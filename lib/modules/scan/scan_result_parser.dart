import 'dart:convert';

enum ScanResultType { webUrl, friend, group, walletPayment, invite, unknown }

class ScanResult {
  final ScanResultType type;
  final String raw;
  final String? url;
  final String? userId;
  final String? groupId;
  final int? expiresAt;
  final List<QrGroupMember> groupMembers;
  final String? address;
  final String? amount;
  final String? tokenSymbol;
  final String? chain;
  final String? inviteCode;

  const ScanResult({
    required this.type,
    required this.raw,
    this.url,
    this.userId,
    this.groupId,
    this.expiresAt,
    this.groupMembers = const [],
    this.address,
    this.amount,
    this.tokenSymbol,
    this.chain,
    this.inviteCode,
  });
}

class QrGroupMember {
  const QrGroupMember({
    required this.userId,
    this.name,
    this.portraitUri,
    this.nickname,
    this.role,
  });

  final String userId;
  final String? name;
  final String? portraitUri;
  final String? nickname;
  final int? role;

  factory QrGroupMember.fromJson(Map<String, dynamic> json) {
    return QrGroupMember(
      userId: '${json['userId'] ?? json['uid'] ?? ''}',
      name: _nullableString(json['name']),
      portraitUri: _nullableString(json['portraitUri'] ?? json['avatar']),
      nickname: _nullableString(json['nickname']),
      role: json['role'] is int
          ? json['role'] as int
          : int.tryParse('${json['role'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'portraitUri': portraitUri,
      'nickname': nickname,
      'role': role,
    };
  }
}

class ScanResultParser {
  ScanResultParser._();

  static final RegExp _domainRegExp = RegExp(
    r'^(localhost|(\d{1,3}\.){3}\d{1,3}|([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})(:\d+)?([/?#].*)?$',
  );

  static ScanResult parse(String value) {
    final raw = value.trim();
    if (raw.isEmpty) {
      return ScanResult(type: ScanResultType.unknown, raw: value);
    }

    final jsonResult = _parseJson(raw);
    if (jsonResult != null) {
      return jsonResult;
    }

    final uriResult = _parseUri(raw);
    if (uriResult != null) {
      return uriResult;
    }

    final normalizedUrl = normalizeUrl(raw);
    if (normalizedUrl != null) {
      final inviteResult = _parseInviteUrl(normalizedUrl, raw);
      if (inviteResult != null) {
        return inviteResult;
      }
      return ScanResult(
        type: ScanResultType.webUrl,
        raw: raw,
        url: normalizedUrl,
      );
    }

    return ScanResult(type: ScanResultType.unknown, raw: raw);
  }

  static String? normalizeUrl(String input) {
    final value = input.trim();
    if (value.isEmpty || value.contains(RegExp(r'\s'))) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      return uri.toString();
    }

    if (_domainRegExp.hasMatch(value)) {
      return 'https://$value';
    }

    return null;
  }

  static ScanResult? _parseJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final type = '${decoded['type'] ?? decoded['action'] ?? ''}'
          .trim()
          .toLowerCase();
      if (type == 'friend' ||
          type == 'add_friend' ||
          type == 'addfriend' ||
          type == 'user') {
        final userId = _firstString(decoded, ['userId', 'uid', 'id']);
        return ScanResult(
          type: ScanResultType.friend,
          raw: raw,
          userId: userId,
        );
      }

      if (type == 'invite' || type == 'invitation' || type == 'referral') {
        return ScanResult(
          type: ScanResultType.invite,
          raw: raw,
          inviteCode: _firstString(decoded, ['inviteCode', 'code']),
        );
      }

      if (type == 'group' ||
          type == 'group_qr' ||
          type == 'join_group' ||
          type == 'group_invite') {
        return ScanResult(
          type: ScanResultType.group,
          raw: raw,
          groupId: _firstString(decoded, ['groupId', 'gid', 'id']),
          expiresAt: _firstInt(decoded, ['expiresAt', 'expireAt', 'expiredAt']),
          groupMembers: _parseGroupMembers(decoded['members']),
        );
      }

      if (type == 'payment' ||
          type == 'pay' ||
          type == 'wallet_payment' ||
          type == 'transfer') {
        return ScanResult(
          type: ScanResultType.walletPayment,
          raw: raw,
          address: _firstString(decoded, ['address', 'to', 'walletAddress']),
          amount: _firstString(decoded, ['amount', 'value']),
          tokenSymbol: _firstString(decoded, [
            'token',
            'tokenSymbol',
            'symbol',
          ]),
          chain: _firstString(decoded, ['chain', 'network', 'chainId']),
        );
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static ScanResult? _parseUri(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme.isEmpty) {
      return null;
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'paracosm') {
      final action = uri.host.toLowerCase();
      if (action == 'invite' ||
          action == 'invitation' ||
          uri.path == '/invite') {
        return ScanResult(
          type: ScanResultType.invite,
          raw: raw,
          inviteCode:
              uri.queryParameters['code'] ?? uri.queryParameters['inviteCode'],
        );
      }
      if (action == 'friend' || action == 'user' || uri.path == '/friend') {
        return ScanResult(
          type: ScanResultType.friend,
          raw: raw,
          userId:
              uri.queryParameters['userId'] ??
              uri.queryParameters['uid'] ??
              uri.queryParameters['id'],
        );
      }
      if (action == 'pay' || action == 'transfer' || uri.path == '/pay') {
        return ScanResult(
          type: ScanResultType.walletPayment,
          raw: raw,
          address: uri.queryParameters['address'] ?? uri.queryParameters['to'],
          amount: uri.queryParameters['amount'],
          tokenSymbol:
              uri.queryParameters['token'] ?? uri.queryParameters['symbol'],
          chain: uri.queryParameters['chain'] ?? uri.queryParameters['network'],
        );
      }
      if (action == 'group' || action == 'join-group' || uri.path == '/group') {
        return ScanResult(
          type: ScanResultType.group,
          raw: raw,
          groupId:
              uri.queryParameters['groupId'] ??
              uri.queryParameters['gid'] ??
              uri.queryParameters['id'],
          expiresAt: int.tryParse(
            uri.queryParameters['expiresAt'] ??
                uri.queryParameters['expireAt'] ??
                '',
          ),
        );
      }
    }

    if (scheme == 'bitcoin' || scheme == 'ethereum' || scheme == 'solana') {
      return ScanResult(
        type: ScanResultType.walletPayment,
        raw: raw,
        address: uri.path.isNotEmpty ? uri.path : uri.host,
        amount: uri.queryParameters['amount'] ?? uri.queryParameters['value'],
        tokenSymbol: scheme.toUpperCase(),
        chain: scheme,
      );
    }

    return null;
  }

  static ScanResult? _parseInviteUrl(String normalizedUrl, String raw) {
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) return null;

    final code =
        uri.queryParameters['code'] ?? uri.queryParameters['inviteCode'];
    if (code == null || code.trim().isEmpty) return null;

    final isInvitePath =
        uri.pathSegments.any((segment) => segment.toLowerCase() == 'invite') ||
        uri.host.toLowerCase() == 'invite.zjtxy.top' ||
        uri.host.toLowerCase() == 'hb.zjtxy.top' ||
        uri.host.toLowerCase().contains('paracosm');
    if (!isInvitePath) return null;

    return ScanResult(
      type: ScanResultType.invite,
      raw: raw,
      url: normalizedUrl,
      inviteCode: code,
    );
  }

  static String? _firstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) {
        continue;
      }
      final text = '$value'.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  static int? _firstInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) {
        continue;
      }
      if (value is int) {
        return value;
      }
      final number = int.tryParse('$value'.trim());
      if (number != null) {
        return number;
      }
    }
    return null;
  }

  static List<QrGroupMember> _parseGroupMembers(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => QrGroupMember.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.userId.isNotEmpty)
        .toList();
  }
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}
