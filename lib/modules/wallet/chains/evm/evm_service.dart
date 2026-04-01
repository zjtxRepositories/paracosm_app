import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';

class EvmService {
  /// =========================
  /// 单钱包实例（全局唯一）
  /// =========================
  static Map<String, String>? _wallet;

  /// =========================
  /// BIP44 路径（固定 index = 0）
  /// =========================
  static const String _path = "m/44'/60'/0'/0/0";

  /// =========================
  /// 获取或创建钱包
  /// =========================
  static Map<String, String> getOrCreateWallet(String mnemonic) {
    /// ✅ 已存在 → 直接返回
    if (_wallet != null) {
      return _wallet!;
    }

    /// ❌ 未创建 → 创建
    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception('Invalid mnemonic');
    }

    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);

    final child = root.derivePath(_path);
    if (child.privateKey == null) {
      throw Exception('Failed to derive private key');
    }

    final privateKeyBytes = child.privateKey!;
    final privateKeyHex = bytesToHex(privateKeyBytes, include0x: true);

    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    final address = credentials.address.hexEip55;

    _wallet = {
      'address': address,
      'privateKey': privateKeyHex,
    };

    return _wallet!;
  }
  /// =========================
  /// 派生地址（单钱包模式）
  /// =========================
  static String deriveAddress(String mnemonic) {
    /// ✅ 已存在钱包 → 直接返回地址
    if (_wallet != null) {
      return _wallet!['address']!;
    }

    /// ❌ 未创建 → 创建并返回
    return getOrCreateWallet(mnemonic)['address']!;
  }


  /// =========================
  /// 私钥 → 地址
  /// =========================
  static String privateKeyToAddress(String privateKeyHex) {
    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    return credentials.address.hexEip55;
  }

  /// =========================
  /// 校验私钥
  /// =========================
  static bool isValidPrivateKey(String privateKeyHex) {
    try {
      final bytes = hexToBytes(privateKeyHex.replaceFirst('0x', ''));

      if (bytes.length != 32) return false;

      final keyInt = bytesToInt(bytes);

      final n = BigInt.parse(
        'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
        radix: 16,
      );

      return keyInt > BigInt.zero && keyInt < n;
    } catch (_) {
      return false;
    }
  }

  static BigInt bytesToInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }

  /// =========================
  /// （可选）清空钱包（登出用）
  /// =========================
  static void clearWallet() {
    _wallet = null;
  }
}