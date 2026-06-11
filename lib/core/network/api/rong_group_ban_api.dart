import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../modules/account/manager/account_manager.dart';
import '../../../modules/wallet/chains/evm/evm_service.dart';
import '../../../modules/im/service/im_service.dart';
import '../../../modules/wallet/chains/evm/evm_facade.dart';

class RongGroupBanApi {
  static const String _baseUrl = 'http://192.168.0.111:8080';
  static const String _addPath = '/group/ban/add.json';
  static const String _rollbackPath = '/group/ban/rollback.json';
  static const String _queryPath = '/group/ban/query.json';
  static const String _appKey = ImConfig.appKey;
  static const String _appSecret = 'zmetBLCbins';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  static Future<bool> add({required String groupId}) async {
    return _post(_addPath, groupId: groupId, isAdd: true);
  }

  static Future<bool> rollback({required String groupId}) {
    return _post(_rollbackPath, groupId: groupId, isAdd: false);
  }

  static Future<List<RongGroupBanStatus>?> query({
    String? groupId,
    List<String>? groupIds,
    int? page,
    int? size,
  }) async {
    final ids = _normalizeGroupIds(groupId: groupId, groupIds: groupIds);
    if (ids.length > 20) {
      debugPrint('RongGroupBanApi query failed: groupIds exceeds 20');
      return null;
    }

    final userId = _currentSignerAddress();
    if (userId.isEmpty) {
      return null;
    }

    final nonce = _nonce();
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timestampText = timestamp.toString();
    final headerSignature = _headerSignature(nonce, timestampText);
    final body = await _queryRequestBody(
      userId: userId,
      groupIds: ids,
      page: page,
      size: size,
      timestamp: timestamp,
      nonce: nonce,
    );

    try {
      final response = await _dio.post(
        _queryPath,
        data: body,
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            'App-Key': _appKey,
            'Nonce': nonce,
            'Timestamp': timestampText,
            'Signature': headerSignature,
          },
        ),
      );

      final data = _normalizeResponseData(response.data);
      if (data is! Map) {
        debugPrint(
          'RongGroupBanApi query failed: http=${response.statusCode}, data=$data',
        );
        return null;
      }

      final code = data['code'];
      final success =
          response.statusCode == 200 &&
          (code == null ||
              code == 0 ||
              code == 200 ||
              code == '0' ||
              code == '200');
      if (!success) {
        debugPrint(
          'RongGroupBanApi query failed: http=${response.statusCode}, '
          'code=$code, data=$data',
        );
        return null;
      }

      return RongGroupBanStatus.fromList(data['groupinfo']);
    } on DioException catch (e) {
      debugPrint(
        'RongGroupBanApi query error: '
        'status=${e.response?.statusCode}, data=${e.response?.data}, error=$e',
      );
      return null;
    } catch (e) {
      debugPrint('RongGroupBanApi query error: $e');
      return null;
    }
  }

  static Future<bool?> isBanned(String groupId) async {
    final result = await query(groupId: groupId);
    if (result == null) {
      return null;
    }
    final id = groupId.trim();
    return result
        .where((item) => item.groupId == id)
        .map((item) => item.isBanned)
        .firstOrNull;
  }

  static String _nonce() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(99999).toString();
  }

  static String _headerSignature(String nonce, String timestamp) {
    final content = _appSecret + nonce + timestamp;
    return sha1.convert(utf8.encode(content)).toString();
  }

  static String _signatureMessage({
    required bool isAdd,
    required String userId,
    required List<String> groupIds,
    required String timestamp,
    required String nonce,
  }) {
    final title = isAdd
        ? 'RongCloud groupBanAdd'
        : 'RongCloud groupBanRollback';
    final lines = <String>[
      title,
      'userId: $userId',
      ...groupIds.map((id) => 'groupId: $id'),
      'timestamp: $timestamp',
      'nonce: $nonce',
    ];
    return lines.join('\n');
  }

  static String _querySignatureMessage({
    required String userId,
    required List<String> groupIds,
    required String timestamp,
    required String nonce,
  }) {
    final lines = <String>[
      'RongCloud groupBanQuery',
      'userId: $userId',
      ...groupIds.map((id) => 'groupId: $id'),
      'timestamp: $timestamp',
      'nonce: $nonce',
    ];
    return lines.join('\n');
  }

  static Future<String> _bodySignature({
    required bool isAdd,
    required String userId,
    required List<String> groupIds,
    required String timestamp,
    required String nonce,
  }) {
    final content = _signatureMessage(
      isAdd: isAdd,
      userId: userId,
      groupIds: groupIds,
      timestamp: timestamp,
      nonce: nonce,
    );
    debugPrint('RongGroupBanApi signatureMessage=$content');
    return EvmFacade.signMessage(userId, content, personal: true);
  }

  static Future<Map<String, dynamic>> _requestBody({
    required bool isAdd,
    required String userId,
    required List<String> groupIds,
    required int timestamp,
    required String nonce,
  }) async {
    final timestampText = timestamp.toString();
    return {
      'userId': userId,
      'groupIds': groupIds,
      'timestamp': timestamp,
      'nonce': nonce,
      'signature': await _bodySignature(
        isAdd: isAdd,
        userId: userId,
        groupIds: groupIds,
        timestamp: timestampText,
        nonce: nonce,
      ),
    };
  }

  static Future<Map<String, dynamic>> _queryRequestBody({
    required String userId,
    required List<String> groupIds,
    required int timestamp,
    required String nonce,
    int? page,
    int? size,
  }) async {
    final timestampText = timestamp.toString();
    final content = _querySignatureMessage(
      userId: userId,
      groupIds: groupIds,
      timestamp: timestampText,
      nonce: nonce,
    );
    debugPrint('RongGroupBanApi querySignatureMessage=$content');
    final body = <String, dynamic>{
      'userId': userId,
      if (groupIds.isNotEmpty) 'groupIds': groupIds,
      if (groupIds.isEmpty && page != null) 'page': page,
      if (groupIds.isEmpty && size != null) 'size': size,
      'timestamp': timestamp,
      'nonce': nonce,
      'signature': await EvmFacade.signMessage(userId, content, personal: true),
    };
    return body;
  }

  static List<String> _normalizeGroupIds({
    String? groupId,
    List<String>? groupIds,
  }) {
    final result = <String>[];
    final seen = <String>{};
    void add(String? value) {
      final id = value?.trim() ?? '';
      if (id.isEmpty || !seen.add(id)) {
        return;
      }
      result.add(id);
    }

    add(groupId);
    for (final id in groupIds ?? const <String>[]) {
      add(id);
    }
    return result;
  }

  static String _currentSignerAddress() {
    final configuredAddress =
        AccountManager().currentWallet?.evmChain?.address.trim() ?? '';
    final wallet = configuredAddress.isEmpty
        ? null
        : EvmService.getWallet(configuredAddress);
    final privateKey = wallet?['privateKey']?.trim() ?? '';
    if (privateKey.isNotEmpty) {
      final signerAddress = EvmService.privateKeyToAddress(privateKey);
      if (configuredAddress.isNotEmpty &&
          signerAddress.toLowerCase() != configuredAddress.toLowerCase()) {
        debugPrint(
          'RongGroupBanApi signer mismatch: '
          'configured=$configuredAddress, signer=$signerAddress',
        );
      }
      return signerAddress;
    }

    return AccountManager().currentAccount?.accountId ?? '';
  }

  static Future<bool> _post(
    String path, {
    required String groupId,
    required bool isAdd,
  }) async {
    final id = groupId.trim();
    if (id.isEmpty) {
      return false;
    }

    final userId = _currentSignerAddress();
    if (userId.isEmpty) {
      return false;
    }

    final groupIds = [id];
    final nonce = _nonce();
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timestampText = timestamp.toString();
    final headerSignature = _headerSignature(nonce, timestampText);
    debugPrint(
      'RongGroupBanApi userId=$userId, headerSignature=$headerSignature',
    );
    try {
      final response = await _dio.post(
        path,
        data: await _requestBody(
          isAdd: isAdd,
          userId: userId,
          groupIds: groupIds,
          timestamp: timestamp,
          nonce: nonce,
        ),
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            'App-Key': _appKey,
            'Nonce': nonce,
            'Timestamp': timestampText,
            'Signature': headerSignature,
          },
        ),
      );

      final data = _normalizeResponseData(response.data);

      if (data is Map) {
        final code = data['code'];
        final success =
            response.statusCode == 200 &&
            (code == null ||
                code == 0 ||
                code == 200 ||
                code == '0' ||
                code == '200');
        if (!success) {
          debugPrint(
            'RongGroupBanApi failed: path=$path, '
            'http=${response.statusCode}, code=$code, data=$data',
          );
        }
        return success;
      }

      final success = response.statusCode == 200;
      if (!success) {
        debugPrint(
          'RongGroupBanApi failed: path=$path, '
          'http=${response.statusCode}, data=$data',
        );
      }
      return success;
    } on DioException catch (e) {
      debugPrint(
        'RongGroupBanApi error: path=$path, '
        'status=${e.response?.statusCode}, data=${e.response?.data}, error=$e',
      );
      return false;
    } catch (e) {
      debugPrint('RongGroupBanApi error: path=$path, error=$e');
      return false;
    }
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
}

class RongGroupBanStatus {
  final String groupId;
  final int stat;

  const RongGroupBanStatus({required this.groupId, required this.stat});

  bool get isBanned => stat == 1;

  factory RongGroupBanStatus.fromJson(Map data) {
    return RongGroupBanStatus(
      groupId: data['groupId']?.toString() ?? '',
      stat: int.tryParse(data['stat']?.toString() ?? '') ?? 0,
    );
  }

  static List<RongGroupBanStatus> fromList(dynamic value) {
    final list = value is List ? value : const [];
    return list
        .whereType<Map>()
        .map(RongGroupBanStatus.fromJson)
        .where((item) => item.groupId.isNotEmpty)
        .toList();
  }
}
