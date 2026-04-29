import 'dart:convert';

enum ScanResultType { webUrl, friend, walletPayment, unknown }

class ScanResult {
  final ScanResultType type;
  final String raw;
  final String? url;
  final String? userId;
  final String? address;
  final String? amount;
  final String? tokenSymbol;
  final String? chain;

  const ScanResult({
    required this.type,
    required this.raw,
    this.url,
    this.userId,
    this.address,
    this.amount,
    this.tokenSymbol,
    this.chain,
  });
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
}
