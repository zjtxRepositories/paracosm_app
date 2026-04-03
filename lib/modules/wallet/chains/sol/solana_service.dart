import 'dart:convert';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:solana/solana.dart';

class SolanaService {
  /// =========================
  /// 多钱包存储（key = address）
  /// =========================
  static final Map<String, Ed25519HDKeyPair> _wallets = {};
  static final Map<String, String> _mnemonics = {}; // address -> mnemonic

  /// =========================
  /// BIP44 路径
  /// =========================
  static String _getPath(int account, int index) {
    return "m/44'/501'/$account'/$index'";
  }

  /// =========================
  /// 创建或获取钱包（助记词）
  /// =========================
  static Future<Ed25519HDKeyPair> createWalletFromMnemonic(
      String mnemonic, {
        int account = 0,
        int index = 0,
      }) async {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception("Invalid mnemonic");
    }

    // 已存在相同助记词的钱包 → 返回已有钱包
    for (final entry in _mnemonics.entries) {
      if (entry.value == mnemonic) {
        return _wallets[entry.key]!;
      }
    }

    // 创建新钱包
    final seed = bip39.mnemonicToSeed(mnemonic);
    final path = _getPath(account, index);

    final keyData = await ED25519_HD_KEY.derivePath(path, seed);

    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: keyData.key,
    );

    final address = keyPair.address;
    _wallets[address] = keyPair;
    _mnemonics[address] = mnemonic;

    return keyPair;
  }

  /// =========================
  /// 导入私钥
  /// =========================
  static Future<Ed25519HDKeyPair> importWalletFromPrivateKey(
      String base64PrivateKey) async {
    final privateKeyBytes = base64Decode(base64PrivateKey);
    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: privateKeyBytes,
    );

    final address = keyPair.address;
    _wallets[address] = keyPair;

    return keyPair;
  }

  /// =========================
  /// 获取钱包
  /// =========================
  static Ed25519HDKeyPair? getWallet(String address) {
    return _wallets[address];
  }

  /// =========================
  /// 获取地址（通过助记词）
  /// =========================
  static Future<String> getAddressFromMnemonic(String mnemonic,
      {int account = 0, int index = 0}) async {
    final kp = await createWalletFromMnemonic(
      mnemonic,
      account: account,
      index: index,
    );
    return kp.address;
  }

  /// =========================
  /// 派生地址（统一入口）
  /// =========================
  static Future<String> deriveAddress(
      String mnemonic, {
        int account = 0,
        int index = 0,
      }) async {
    return await getAddressFromMnemonic(
      mnemonic,
      account: account,
      index: index,
    );
  }
  /// =========================
  /// 私钥 → 地址（导入钱包）
  /// =========================
  static Future<String> privateKeyToAddress(String base64PrivateKey) async {
    // 1. 解码
    final privateKeyBytes = base64Decode(base64PrivateKey);

    // 2. 创建 keypair
    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: privateKeyBytes,
    );

    final address = keyPair.address;

    // 3. 已存在直接返回
    if (_wallets.containsKey(address)) {
      return address;
    }

    // 4. 缓存钱包
    _wallets[address] = keyPair;

    return address;
  }
  /// =========================
  /// 地址 → 私钥（base64）
  /// =========================
  static Future<String?> getPrivateKeyByAddress(String address) async {
    final keyPair = _wallets[address];
    if (keyPair == null) return null;

    final keyData = await keyPair.extract();
    return base64Encode(keyData.bytes);
  }

  /// =========================
  /// 导出私钥（base64）
  /// =========================
  static Future<Ed25519HDKeyPair> exportKeyPair(String address) async {
    final keyPair = _wallets[address];
    if (keyPair == null) throw Exception("钱包不存在");
    return keyPair;
  }

  static Future<String> exportPrivateKey(String address) async {
    final keyPair = _wallets[address];
    if (keyPair == null) throw Exception("钱包不存在");

    final keyData = await keyPair.extract();
    return base64Encode(keyData.bytes);
  }

  /// =========================
  /// 获取公钥（Base58）
  /// =========================
  static String getPublicKey(String address) {
    final keyPair = _wallets[address];
    if (keyPair == null) throw Exception("钱包不存在");
    return keyPair.publicKey.toBase58();
  }

  /// =========================
  /// 删除指定钱包
  /// =========================
  static void removeWallet(String address) {
    _wallets.remove(address);
    _mnemonics.remove(address);
  }

  /// =========================
  /// 清空所有钱包
  /// =========================
  static void clearAllWallets() {
    _wallets.clear();
    _mnemonics.clear();
  }

  /// =========================
  /// 获取所有钱包地址
  /// =========================
  static List<String> getAllWalletAddresses() {
    return _wallets.keys.toList();
  }
}