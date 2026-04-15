import 'dart:convert';
import 'dart:typed_data';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/util/utils.dart';
import '../evm_service.dart';

class EvmSignService {

  static Future<String> signMessage({
    required String address,
    required String message,
    required bool personal,
  }) async {
    final privateKey = EvmService.getPrivateKeyByAddress(address);
    if (privateKey == null) {
      throw Exception("找不到该钱包");
    }

    final keyBytes = _normalizePrivateKey(privateKey);

    final Uint8List messageBytes = _normalizeMessage(message);

    if (personal) {
      return EthSigUtil.signPersonalMessage(
        message: messageBytes,
        privateKeyInBytes: keyBytes,
      );
    }

    return EthSigUtil.signMessage(
      message: messageBytes,
      privateKeyInBytes: keyBytes,
    );
  }

  /// =========================
  /// message 统一解析（关键）
  /// =========================
  static Uint8List _normalizeMessage(String message) {
    final trimmed = message.trim();

    // hex message
    if (trimmed.startsWith('0x')) {
      try {
        return hexToBytes(trimmed);
      } catch (_) {
        // fallback：当作普通字符串
        return Uint8List.fromList(utf8.encode(trimmed));
      }
    }

    // 默认 utf8
    return Uint8List.fromList(utf8.encode(trimmed));
  }

  /// =========================
  /// privateKey 统一格式化
  /// =========================
  static Uint8List _normalizePrivateKey(dynamic key) {
    if (key is Uint8List) return key;

    if (key is String) {
      final clean = key.startsWith('0x') ? key.substring(2) : key;
      return Uint8List.fromList(List<int>.generate(
        clean.length ~/ 2,
            (i) => int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16),
      ));
    }

    throw Exception("Unsupported privateKey format");
  }
}