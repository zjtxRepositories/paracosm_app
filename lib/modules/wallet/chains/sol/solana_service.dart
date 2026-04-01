import 'dart:convert';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:solana/solana.dart';

class SolanaService {
  /// =========================
  /// 单例 keyPair（全局唯一）
  /// =========================
  static Ed25519HDKeyPair? _keyPair;

  /// 当前 mnemonic（用于校验）
  static String? _currentMnemonic;

  /// =========================
  /// 获取 keyPair（安全）
  /// =========================
   Ed25519HDKeyPair get keyPair {
    if (_keyPair == null) {
      throw Exception("Solana wallet 未初始化");
    }
    return _keyPair!;
  }

  /// =========================
  /// 地址（同步获取）
  /// =========================
   String get address {
    return keyPair.address;
  }

  /// =========================
  /// 路径
  /// =========================
  static String _getPath(int account, int index) {
    return "m/44'/501'/$account'/$index'";
  }

  /// =========================
  /// 获取或创建钱包（助记词）
  /// =========================
  static Future<Ed25519HDKeyPair> getOrCreateFromMnemonic(
      String mnemonic, {
        int account = 0,
        int index = 0,
      }) async {
    /// ✅ 已存在
    if (_keyPair != null) {
      if (_currentMnemonic == mnemonic) {
        return _keyPair!;
      }
    }

    /// ❌ 未初始化 → 创建
    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception("Invalid mnemonic");
    }

    final seed = bip39.mnemonicToSeed(mnemonic);
    final path = _getPath(account, index);

    final keyData = await ED25519_HD_KEY.derivePath(
      path,
      seed,
    );

    _keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: keyData.key,
    );

    _currentMnemonic = mnemonic;

    return _keyPair!;
  }

  /// =========================
  /// 私钥恢复（只允许一次）
  /// =========================
  static Future<Ed25519HDKeyPair> initFromPrivateKey(
      String base64PrivateKey,
      ) async {
    if (_keyPair != null) {
      return _keyPair!;
    }

    final privateKeyBytes = base64Decode(base64PrivateKey);

    _keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: privateKeyBytes,
    );

    return _keyPair!;
  }

  /// =========================
  /// 获取地址
  /// =========================
  static Future<String> getAddress(String mnemonic) async {
    final kp = await getOrCreateFromMnemonic(mnemonic);
    return kp.address;
  }

  /// =========================
  /// deriveAddress（统一入口）
  /// =========================
  static Future<String> deriveAddress(
      String mnemonic, {
        int account = 0,
        int index = 0,
      }) async {
    /// ✅ 已存在 → 直接用
    if (_keyPair != null) {
      if (_currentMnemonic == mnemonic) {
        throw Exception("钱包已用其他助记词初始化");
        return _keyPair!.address;
      }
    }

    /// ❌ 未创建 → 创建
    final kp = await getOrCreateFromMnemonic(
      mnemonic,
      account: account,
      index: index,
    );

    return kp.address;
  }

  /// =========================
  /// 导出私钥
  /// =========================
  static Future<String> exportPrivateKey() async {
    if (_keyPair == null) {
      throw Exception("钱包未初始化");
    }

    final keyData = await _keyPair!.extract();
    return base64Encode(keyData.bytes);
  }

  /// =========================
  /// 公钥
  /// =========================
  static String get publicKey {
    if (_keyPair == null) {
      throw Exception("钱包未初始化");
    }
    return _keyPair!.publicKey.toBase58();
  }

  /// =========================
  /// 清空（登出）
  /// =========================
  static void clear() {
    _keyPair = null;
    _currentMnemonic = null;
  }
}