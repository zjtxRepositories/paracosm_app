import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';

class EvmService {
  static Future<Map> fromMnemonic(
      String mnemonic,
      ) async {

    final seed = bip39.mnemonicToSeed(mnemonic);

    final privateKeyBytes = seed.sublist(0, 32);

    final privateKeyHex =
    bytesToHex(privateKeyBytes, include0x: true);

    final credentials = EthPrivateKey.fromHex(privateKeyHex);

    final address = credentials.address;

    return {
      'address' : address.hex,
      'privateKey' : privateKeyHex
    };
  }

  static String deriveAddress(
      String mnemonic,
      )  {

    final seed = bip39.mnemonicToSeed(mnemonic);

    final privateKeyBytes = seed.sublist(0, 32);

    final privateKeyHex =
    bytesToHex(privateKeyBytes, include0x: true);

    final credentials = EthPrivateKey.fromHex(privateKeyHex);

    final address = credentials.address;

    return address.hex;
  }

  /// =========================
  /// 私钥 → 地址
  /// =========================
  static String privateKeyToAddress(String privateKeyHex) {
    final credentials = EthPrivateKey.fromHex(privateKeyHex);

    final address = credentials.address;

    return address.hexEip55; // EIP55校验地址
  }

  /// =========================
  /// 校验私钥是否有效
  /// =========================
  static bool isValidPrivateKey(String privateKeyHex) {
    try {
      EthPrivateKey.fromHex(privateKeyHex);
      return true;
    } catch (e) {
      return false;
    }
  }
}