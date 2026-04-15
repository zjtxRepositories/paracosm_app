import 'dart:convert';
import 'dart:typed_data';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:web3dart/crypto.dart';

import '../evm_service.dart';

class EvmTypedDataSigner {
  static Future<String> signTypedData({
    required String address,
    required String jsonData,
    required TypedDataVersion version,
  }) async {
    final privateKey = EvmService.getPrivateKeyByAddress(address);

    if (privateKey == null) {
      throw Exception("找不到该钱包");
    }

    final keyBytes = _normalizePrivateKey(privateKey);

    return EthSigUtil.signTypedData(
      jsonData: jsonData,
      version: version,
      privateKeyInBytes: keyBytes,
    );
  }

  static Uint8List _normalizePrivateKey(dynamic key) {
    if (key is Uint8List) {
      if (key.length != 32) {
        throw Exception("Invalid private key length");
      }
      return key;
    }

    if (key is String) {
      final clean = key.startsWith('0x') ? key.substring(2) : key;

      if (clean.length != 64) {
        throw Exception("Invalid private key format");
      }

      return hexToBytes(clean);
    }

    throw Exception("Unsupported privateKey format");
  }
}