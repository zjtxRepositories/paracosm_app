import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';

class EvmService {
  /// =========================
  /// 多钱包实例（key = address）
  /// =========================
  static final Map<String, Map<String, String>> _wallets = {};

  /// =========================
  /// BIP44 路径（固定 index = 0）
  /// =========================
  static const String _path = "m/44'/60'/0'/0/0";

  /// =========================
  /// 创建或获取钱包（助记词）
  /// =========================
  static Map<String, String> createWalletFromMnemonic(String mnemonic) {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception('Invalid mnemonic');
    }

    // 检查是否已存在相同助记词的钱包
    for (final wallet in _wallets.values) {
      if (wallet['mnemonic'] == mnemonic) {
        return wallet;
      }
    }

    // 创建新钱包
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath(_path);

    if (child.privateKey == null) {
      throw Exception('Failed to derive private key');
    }

    final privateKeyHex = bytesToHex(child.privateKey!, include0x: true);
    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    final address = credentials.address.hexEip55;

    final walletInfo = {
      'address': address,
      'privateKey': privateKeyHex,
      'mnemonic': mnemonic,
    };

    _wallets[address] = walletInfo;

    return walletInfo;
  }

  /// =========================
  /// 派生地址（通过助记词）
  /// =========================
  static String deriveAddress(String mnemonic) {
    // 已存在钱包 → 返回
    for (final wallet in _wallets.values) {
      if (wallet['mnemonic'] == mnemonic) {
        return wallet['address']!;
      }
    }
    // 不存在 → 创建
    return createWalletFromMnemonic(mnemonic)['address']!;
  }

  /// =========================
  /// 私钥 → 地址
  /// =========================
  static String privateKeyToAddress(String privateKeyHex) {
    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    return credentials.address.hexEip55;
  }

  /// =========================
  /// 地址 → 私钥（从缓存获取）
  /// =========================
  static String? getPrivateKeyByAddress(String address) {
    final wallet = _wallets[address];
    return wallet?['privateKey'];
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
  /// 删除指定钱包
  /// =========================
  static void removeWallet(String address) {
    _wallets.remove(address);
  }

  /// =========================
  /// 清空所有钱包
  /// =========================
  static void clearAllWallets() {
    _wallets.clear();
  }

  /// =========================
  /// 获取所有钱包地址
  /// =========================
  static List<String> getAllWalletAddresses() {
    return _wallets.keys.toList();
  }

  /// =========================
  /// 获取钱包信息（通过地址）
  /// =========================
  static Map<String, String>? getWallet(String address) {
    return _wallets[address];
  }
}