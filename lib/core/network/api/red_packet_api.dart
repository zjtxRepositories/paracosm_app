import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:paracosm/core/network/api/api_paths.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/invite/service/invite_access_token_manager.dart';
import 'package:paracosm/modules/wallet/chains/evm/evm_facade.dart';
import 'package:paracosm/util/string_util.dart';

typedef RedPacketSignatureProvider =
    Future<String> Function(String userId, String message);

class RedPacketSignatureRequest {
  const RedPacketSignatureRequest({
    required this.userId,
    required this.message,
    required this.timestamp,
    required this.nonce,
  });

  final String userId;
  final String message;
  final int timestamp;
  final String nonce;
}

class RedPacketApiException implements Exception {
  const RedPacketApiException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'RedPacketApiException($code): $message';
}

class RedPacketAsset {
  const RedPacketAsset({
    required this.assetId,
    required this.symbol,
    required this.decimals,
    this.kind,
    this.contract,
    this.minShare,
    this.maxSend,
  });

  final String assetId;
  final String symbol;
  final int decimals;
  final String? kind;
  final String? contract;
  final String? minShare;
  final String? maxSend;

  factory RedPacketAsset.fromJson(Map json) {
    return RedPacketAsset(
      assetId: _string(json['asset_id'] ?? json['assetId']),
      symbol: _string(json['symbol']),
      kind: _nullableString(json['kind']),
      contract: _nullableString(json['contract']),
      decimals: _int(json['decimals'], fallback: 18),
      minShare: _nullableString(json['min_share'] ?? json['minShare']),
      maxSend: _nullableString(json['max_send'] ?? json['maxSend']),
    );
  }
}

class RedPacketBalance {
  const RedPacketBalance({
    required this.assetId,
    required this.symbol,
    required this.decimals,
    required this.available,
    required this.display,
  });

  final String assetId;
  final String symbol;
  final int decimals;
  final String available;
  final String display;

  factory RedPacketBalance.fromJson(Map json) {
    final decimals = _int(json['decimals'], fallback: 18);
    final available = _string(json['available']);
    return RedPacketBalance(
      assetId: _string(json['asset_id'] ?? json['assetId']),
      symbol: _string(json['symbol']),
      decimals: decimals,
      available: available,
      display: _formatTokenUnitsString(
        available,
        decimals,
        fallback: _string(json['display']),
      ),
    );
  }
}

class RedPacketSendResult {
  const RedPacketSendResult({
    required this.packetNo,
    required this.mode,
    required this.scene,
    required this.assetId,
    required this.count,
    this.expireTime,
  });

  final String packetNo;
  final String mode;
  final String scene;
  final String assetId;
  final int count;
  final int? expireTime;

  factory RedPacketSendResult.fromJson(Map json) {
    return RedPacketSendResult(
      packetNo: _string(json['packet_no'] ?? json['packetNo']),
      mode: _string(json['mode']),
      scene: _string(json['scene']),
      assetId: _string(json['asset_id'] ?? json['assetId']),
      count: _int(json['count']),
      expireTime: _nullableInt(json['expire_time'] ?? json['expireTime']),
    );
  }
}

class RedPacketGrabResult {
  const RedPacketGrabResult({
    required this.packetNo,
    required this.assetId,
    required this.symbol,
    required this.amount,
    required this.display,
    required this.finished,
  });

  final String packetNo;
  final String assetId;
  final String symbol;
  final String amount;
  final String display;
  final bool finished;

  factory RedPacketGrabResult.fromJson(Map json) {
    final amount = _string(json['amount']);
    final display = _string(
      json['display'] ?? json['amount_display'] ?? json['amountDisplay'],
    );
    final decimals = _int(json['decimals'], fallback: 18);
    return RedPacketGrabResult(
      packetNo: _string(json['packet_no'] ?? json['packetNo']),
      assetId: _string(json['asset_id'] ?? json['assetId']),
      symbol: _string(json['symbol']),
      amount: amount,
      display: display.isNotEmpty
          ? _formatDisplayString(display)
          : _formatTokenUnitsString(amount, decimals),
      finished: _bool(json['finished']),
    );
  }
}

class RedPacketReceive {
  const RedPacketReceive({
    required this.receiver,
    required this.amount,
    required this.display,
    this.createTime,
  });

  final String receiver;
  final String amount;
  final String display;
  final int? createTime;

  factory RedPacketReceive.fromJson(Map json, {int decimals = 18}) {
    final amount = _string(
      json['amount'] ?? json['receive_amount'] ?? json['receiveAmount'],
    );
    final display = _string(
      json['display'] ??
          json['amount_display'] ??
          json['amountDisplay'] ??
          json['receive_display'] ??
          json['receiveDisplay'],
    );
    return RedPacketReceive(
      receiver: _string(json['receiver'] ?? json['user_id'] ?? json['userId']),
      amount: amount,
      display: display.isNotEmpty
          ? _formatDisplayString(display)
          : _formatTokenUnitsString(amount, decimals),
      createTime: _nullableInt(json['create_time'] ?? json['createTime']),
    );
  }
}

class RedPacketInfo {
  const RedPacketInfo({
    required this.packetNo,
    required this.sender,
    required this.scene,
    required this.assetId,
    required this.mode,
    required this.status,
    required this.count,
    required this.remainingCount,
    required this.totalAmount,
    required this.remainingAmount,
    required this.totalDisplay,
    required this.greeting,
    required this.receives,
    this.groupId,
    this.symbol,
    this.createTime,
    this.expireTime,
  });

  final String packetNo;
  final String sender;
  final String scene;
  final String? groupId;
  final String assetId;
  final String? symbol;
  final String mode;
  final String status;
  final int count;
  final int remainingCount;
  final String totalAmount;
  final String remainingAmount;
  final String totalDisplay;
  final String greeting;
  final int? createTime;
  final int? expireTime;
  final List<RedPacketReceive> receives;

  int get receivedCount => max(0, count - remainingCount);

  bool get isExpired => status == 'expired' || status == 'void';

  bool get isFinished => status == 'finished' || remainingCount <= 0;

  factory RedPacketInfo.fromJson(Map json) {
    final decimals = _int(json['decimals'], fallback: 18);
    return RedPacketInfo(
      packetNo: _string(json['packet_no'] ?? json['packetNo']),
      sender: _string(json['sender']),
      scene: _string(json['scene']),
      groupId: _nullableString(json['group_id'] ?? json['groupId']),
      assetId: _string(json['asset_id'] ?? json['assetId']),
      symbol: _nullableString(json['symbol']),
      mode: _string(json['mode']),
      status: _string(json['status']),
      count: _int(json['count']),
      remainingCount: _int(json['remaining_count'] ?? json['remainingCount']),
      totalAmount: _string(json['total_amount'] ?? json['totalAmount']),
      remainingAmount: _string(
        json['remaining_amount'] ?? json['remainingAmount'],
      ),
      totalDisplay: _formatDisplayString(
        _string(json['total_display'] ?? json['totalDisplay']),
      ),
      greeting: _string(json['greeting']),
      createTime: _nullableInt(json['create_time'] ?? json['createTime']),
      expireTime: _nullableInt(json['expire_time'] ?? json['expireTime']),
      receives: _list(json['receives'])
          .whereType<Map>()
          .map((item) => RedPacketReceive.fromJson(item, decimals: decimals))
          .toList(growable: false),
    );
  }
}

class RedPacketMineItem {
  const RedPacketMineItem({
    required this.packetNo,
    required this.assetId,
    required this.mode,
    required this.scene,
    required this.status,
    required this.count,
    required this.remainingCount,
    required this.totalAmount,
    this.totalDisplay,
    this.symbol,
    this.createTime,
    this.expireTime,
    this.receiveAmount,
    this.receiveDisplay,
    this.receiveTime,
  });

  final String packetNo;
  final String assetId;
  final String mode;
  final String scene;
  final String status;
  final int count;
  final int remainingCount;
  final String totalAmount;
  final String? totalDisplay;
  final String? symbol;
  final int? createTime;
  final int? expireTime;
  final String? receiveAmount;
  final String? receiveDisplay;
  final int? receiveTime;

  int get receivedCount => max(0, count - remainingCount);

  factory RedPacketMineItem.fromJson(Map json) {
    final decimals = _int(json['decimals'], fallback: 18);
    final totalAmount = _string(json['total_amount'] ?? json['totalAmount']);
    final totalDisplay = _formatNullableDisplayString(
      json['total_display'] ?? json['totalDisplay'],
    );
    final receiveAmount = _nullableString(
      json['receive_amount'] ?? json['receiveAmount'],
    );
    final receiveDisplay = _formatNullableDisplayString(
      json['receive_display'] ?? json['receiveDisplay'],
    );
    return RedPacketMineItem(
      packetNo: _string(json['packet_no'] ?? json['packetNo']),
      assetId: _string(json['asset_id'] ?? json['assetId']),
      symbol: _nullableString(json['symbol']),
      mode: _string(json['mode']),
      scene: _string(json['scene']),
      status: _string(json['status']),
      count: _int(json['count']),
      remainingCount: _int(json['remaining_count'] ?? json['remainingCount']),
      totalAmount: totalAmount,
      totalDisplay:
          totalDisplay ?? _formatTokenUnitsString(totalAmount, decimals),
      createTime: _nullableInt(json['create_time'] ?? json['createTime']),
      expireTime: _nullableInt(json['expire_time'] ?? json['expireTime']),
      receiveAmount: receiveAmount,
      receiveDisplay:
          receiveDisplay ??
          (receiveAmount == null
              ? null
              : _formatTokenUnitsString(receiveAmount, decimals)),
      receiveTime: _nullableInt(json['receive_time'] ?? json['receiveTime']),
    );
  }
}

class RedPacketGroupListResult {
  const RedPacketGroupListResult({
    required this.userId,
    required this.groupId,
    required this.sent,
    required this.received,
    this.type,
    this.items = const [],
  });

  final String userId;
  final String groupId;
  final String? type;
  final List<RedPacketMineItem> sent;
  final List<RedPacketMineItem> received;
  final List<RedPacketMineItem> items;

  factory RedPacketGroupListResult.fromJson(Map json) {
    final type = _nullableString(json['type']);
    final items = _parseMineItems(json['items']);
    return RedPacketGroupListResult(
      userId: _string(json['userId']),
      groupId: _string(json['groupId'] ?? json['group_id']),
      type: type,
      sent: type == 'sent' ? items : _parseMineItems(json['sent']),
      received: type == 'received' ? items : _parseMineItems(json['received']),
      items: items,
    );
  }
}

class RedPacketApi {
  RedPacketApi._();

  static const String baseUrl = ApiPaths.blockUrl;

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.jsonContentType,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  static String Function()? _nonceProviderForTesting;
  static int Function()? _timestampProviderForTesting;
  static String? Function()? _accessTokenProviderForTesting;
  static String? Function()? _userIdProviderForTesting;
  static RedPacketSignatureProvider? _signatureProviderForTesting;

  static Future<List<RedPacketAsset>> assetList() async {
    final data = await _post('/asset/list.json');
    print('assetList--------$data');
    return _list(data['assets'])
        .whereType<Map>()
        .map(RedPacketAsset.fromJson)
        .where((item) => item.assetId.isNotEmpty)
        .toList(growable: false);
  }

  static Future<List<RedPacketBalance>> queryBalances() async {
    final accessToken = await _accessToken();
    final data = await _post(
      '/balance/query.json',
      body: {'accessToken': accessToken},
    );
    debugPrint('queryBalances: $data');
    return _list(data['balances'])
        .whereType<Map>()
        .map(RedPacketBalance.fromJson)
        .where((item) => item.assetId.isNotEmpty)
        .toList(growable: false);
  }

  static Future<RedPacketSendResult> send({
    required String assetId,
    required String amount,
    required int count,
    required String mode,
    String? groupId,
    String? to,
    String? greeting,
    RedPacketSignatureRequest? signatureRequest,
  }) async {
    final request =
        signatureRequest ??
        prepareSendSignature(
          assetId: assetId,
          amount: amount,
          count: count,
          mode: mode,
          groupId: groupId,
        );
    final safeUserId = request.userId;
    final timestamp = request.timestamp;
    final nonce = request.nonce;
    final message = request.message;
    debugPrint('RedPacketApi redSend signatureMessage=$message');
    final signature = await _signature(safeUserId, message);

    final data = await _post(
      '/red/send.json',
      body: {
        'userId': safeUserId,
        'signature': signature,
        'timestamp': timestamp,
        'nonce': nonce,
        'mode': mode,
        'assetId': assetId,
        'amount': amount,
        'count': count,
        if ((groupId ?? '').trim().isNotEmpty) 'groupId': groupId!.trim(),
        if ((to ?? '').trim().isNotEmpty) 'to': to!.trim(),
        if ((greeting ?? '').trim().isNotEmpty) 'greeting': greeting!.trim(),
      },
    );
    return RedPacketSendResult.fromJson(data);
  }

  static RedPacketSignatureRequest prepareSendSignature({
    required String assetId,
    required String amount,
    required int count,
    required String mode,
    String? groupId,
  }) {
    final safeUserId = _currentUserId();
    if (safeUserId.isEmpty) {
      throw const RedPacketApiException('missing_user', '缺少钱包地址');
    }

    final nonce = _nonce();
    final timestamp = _timestamp();
    final extras = <String>[
      if ((groupId ?? '').trim().isNotEmpty) 'groupId: ${groupId!.trim()}',
      'assetId: $assetId',
      'amount: $amount',
      'count: $count',
      'mode: $mode',
    ];
    final message = _signatureMessage(
      title: 'RongCloud redSend',
      userId: safeUserId,
      extras: extras,
      timestamp: timestamp,
      nonce: nonce,
    );
    return RedPacketSignatureRequest(
      userId: safeUserId,
      message: message,
      timestamp: timestamp,
      nonce: nonce,
    );
  }

  static Future<RedPacketGrabResult> grab(String packetNo) async {
    final accessToken = await _accessToken();
    final data = await _post(
      '/red/grab.json',
      body: {'accessToken': accessToken, 'packetNo': packetNo},
    );
    return RedPacketGrabResult.fromJson(data);
  }

  static Future<RedPacketInfo> info(String packetNo) async {
    final safePacketNo = packetNo.trim();
    if (safePacketNo.isEmpty) {
      throw const RedPacketApiException(
        'missing_packet_no',
        'packetNo is required',
      );
    }
    final data = await _post(
      '/red/info.json',
      body: {'packetNo': safePacketNo},
      queryParameters: {'packetNo': safePacketNo},
    );
    return RedPacketInfo.fromJson(data);
  }

  static Future<List<RedPacketMineItem>> mine() async {
    final accessToken = await _accessToken();
    final data = await _post(
      '/red/mine.json',
      body: {'accessToken': accessToken},
    );
    return _parseMineItems(data['packets'] ?? data['items'] ?? data['sent']);
  }

  static Future<List<RedPacketMineItem>> received() async {
    final accessToken = await _accessToken();
    final data = await _post(
      '/red/received.json',
      body: {'accessToken': accessToken},
    );
    return _parseMineItems(
      data['packets'] ?? data['items'] ?? data['received'],
    );
  }

  static Future<RedPacketGroupListResult> groupList({
    required String groupId,
    String? type,
    int limit = 20,
  }) async {
    final safeGroupId = groupId.trim();
    if (safeGroupId.isEmpty) {
      throw const RedPacketApiException('missing_group_id', '未传 groupId');
    }
    final safeType = type?.trim();
    if (safeType != null &&
        safeType.isNotEmpty &&
        safeType != 'sent' &&
        safeType != 'received') {
      throw const RedPacketApiException(
        'invalid_type',
        'type 不是 sent/received',
      );
    }

    final accessToken = await _accessToken();
    final data = await _post(
      '/red/group/list.json',
      body: {
        'accessToken': accessToken,
        'groupId': safeGroupId,
        if (safeType != null && safeType.isNotEmpty) 'type': safeType,
        'limit': limit.clamp(1, 100),
      },
    );
    return RedPacketGroupListResult.fromJson(data);
  }

  static Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        queryParameters: queryParameters,
        data: body ?? const <String, dynamic>{},
        options: Options(contentType: Headers.jsonContentType),
      );
      final data = _normalizeResponseData(response.data);
      if (data is! Map) {
        throw RedPacketApiException(
          response.statusCode?.toString() ?? 'invalid_response',
          '红包接口响应异常',
        );
      }

      final error = data['error'];
      if (error is Map) {
        throw RedPacketApiException(
          _string(error['code'], fallback: 'api_error'),
          _string(error['message'], fallback: '红包接口请求失败'),
        );
      }

      final code = data['code'];
      if (code == 200 || code == '200' || code == null) {
        return data.map((key, value) => MapEntry(key.toString(), value));
      }

      throw RedPacketApiException(
        _string(code, fallback: 'api_error'),
        _string(
          data['message'] ?? data['msg'] ?? data['errorMessage'],
          fallback: '红包接口请求失败',
        ),
      );
    } on DioException catch (e) {
      final data = _normalizeResponseData(e.response?.data);
      if (data is Map && data['error'] is Map) {
        final error = data['error'] as Map;
        throw RedPacketApiException(
          _string(error['code'], fallback: 'network_error'),
          _string(error['message'], fallback: '红包接口请求失败'),
        );
      }
      throw RedPacketApiException(
        e.response?.statusCode?.toString() ?? 'network_error',
        e.message ?? '网络请求失败',
      );
    }
  }

  static String _signatureMessage({
    required String title,
    required String userId,
    required List<String> extras,
    required int timestamp,
    required String nonce,
  }) {
    return [
      title,
      'userId: $userId',
      ...extras,
      'timestamp: $timestamp',
      'nonce: $nonce',
    ].join('\n');
  }

  static Future<String> _signature(String userId, String message) {
    final provider = _signatureProviderForTesting;
    if (provider != null) {
      return provider(userId, message);
    }
    return EvmFacade.signMessage(userId, message, personal: true);
  }

  static Future<String> _accessToken() async {
    final provider = _accessTokenProviderForTesting;
    final provided = provider?.call();
    if (provided != null && provided.isNotEmpty) {
      return provided;
    }

    try {
      final token = await InviteAccessTokenManager.ensureAccessToken();
      if (token.trim().isEmpty) {
        throw const RedPacketApiException('missing_token', '缺少红包访问令牌');
      }
      return token.trim();
    } catch (_) {
      throw const RedPacketApiException('missing_token', '缺少红包访问令牌');
    }
  }

  static String _currentUserId() {
    final provider = _userIdProviderForTesting;
    final provided = provider?.call();
    if (provided != null && provided.trim().isNotEmpty) {
      return provided.trim().toLowerCase();
    }
    return AccountManager().currentAccount?.accountId.trim().toLowerCase() ??
        '';
  }

  static String _nonce() {
    final provider = _nonceProviderForTesting;
    if (provider != null) return provider();
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(99999).toString();
  }

  static int _timestamp() {
    final provider = _timestampProviderForTesting;
    if (provider != null) return provider();
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  static dynamic _normalizeResponseData(dynamic data) {
    if (data is String && data.isNotEmpty) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  static void setHttpClientAdapterForTesting(HttpClientAdapter adapter) {
    _dio.httpClientAdapter = adapter;
  }

  static void setNonceProviderForTesting(String Function()? provider) {
    _nonceProviderForTesting = provider;
  }

  static void setTimestampProviderForTesting(int Function()? provider) {
    _timestampProviderForTesting = provider;
  }

  static void setAccessTokenProviderForTesting(String? Function()? provider) {
    _accessTokenProviderForTesting = provider;
  }

  static void setUserIdProviderForTesting(String? Function()? provider) {
    _userIdProviderForTesting = provider;
  }

  static void setSignatureProviderForTesting(
    RedPacketSignatureProvider? provider,
  ) {
    _signatureProviderForTesting = provider;
  }

  static void resetForTesting() {
    _nonceProviderForTesting = null;
    _timestampProviderForTesting = null;
    _accessTokenProviderForTesting = null;
    _userIdProviderForTesting = null;
    _signatureProviderForTesting = null;
    _dio.httpClientAdapter = IOHttpClientAdapter();
  }
}

String redPacketDecimalToUnits(
  String value,
  int decimals, {
  int multiplier = 1,
}) {
  final text = value.trim();
  if (text.isEmpty || multiplier <= 0 || decimals < 0) {
    throw const FormatException('invalid amount');
  }

  final parts = text.split('.');
  if (parts.length > 2) {
    throw const FormatException('invalid amount');
  }

  final integerPart = parts[0].isEmpty ? '0' : parts[0];
  final fractionPart = parts.length == 2 ? parts[1] : '';
  final digitsOnly = RegExp(r'^\d+$');
  if (!digitsOnly.hasMatch(integerPart) ||
      (fractionPart.isNotEmpty && !digitsOnly.hasMatch(fractionPart)) ||
      fractionPart.length > decimals) {
    throw const FormatException('invalid amount');
  }

  final unit = BigInt.from(10).pow(decimals);
  final integer = BigInt.parse(integerPart) * unit;
  final fraction = fractionPart.isEmpty
      ? BigInt.zero
      : BigInt.parse(fractionPart.padRight(decimals, '0'));
  final amount = (integer + fraction) * BigInt.from(multiplier);
  if (amount <= BigInt.zero) {
    throw const FormatException('invalid amount');
  }
  return amount.toString();
}

String _string(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

int _int(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    return value == '1' || value.toLowerCase() == 'true';
  }
  return false;
}

List _list(dynamic value) {
  if (value is List) return value;
  return const [];
}

List<RedPacketMineItem> _parseMineItems(dynamic value) {
  return _list(value)
      .whereType<Map>()
      .map(RedPacketMineItem.fromJson)
      .where((item) => item.packetNo.isNotEmpty)
      .toList(growable: false);
}

String _formatTokenUnitsString(
  String value,
  int decimals, {
  String fallback = '',
}) {
  try {
    final text = value.trim();
    if (text.isEmpty) return _formatDisplayString(fallback);
    return formatTokenUnits(BigInt.parse(text), decimals);
  } catch (_) {
    return _formatDisplayString(fallback.isNotEmpty ? fallback : value);
  }
}

String? _formatNullableDisplayString(dynamic value) {
  final text = _nullableString(value);
  if (text == null) return null;
  return _formatDisplayString(text);
}

String _formatDisplayString(String value) {
  try {
    return formatTokenDecimalString(value);
  } catch (_) {
    return value.trim();
  }
}
