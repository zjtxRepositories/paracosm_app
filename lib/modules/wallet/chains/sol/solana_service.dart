import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:solana/solana.dart';

class SolanaService {

  /// 标准路径：m/44'/501'/0'/0'
  static const String _path = "m/44'/501'/0'/0'";

  /// ✅ 助记词生成地址
  static Future<String> deriveAddress(
      String mnemonic,
      ) async {

    /// 1️⃣ mnemonic → seed
    final seed = bip39.mnemonicToSeed(mnemonic);

    /// 2️⃣ 派生 key（ed25519）
    final keyData = await ED25519_HD_KEY.derivePath(
      _path,
      seed,
    );

    final privateKey = keyData.key;

    /// 3️⃣ 创建 keypair
    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: privateKey,
    );

    /// 4️⃣ 地址（公钥）
    final address = keyPair.address;

    // print('sol------$address');
    return address;
  }

  /// ✅ 获取指定 index（多地址）
  static Future<String> getAddressByIndex(
      String mnemonic, {
        int account = 0,
        int index = 0,
      }) async {

    /// Solana 推荐路径：
    /// m/44'/501'/{account}'/0'
    final path = "m/44'/501'/$account'/$index'";

    final seed = bip39.mnemonicToSeed(mnemonic);

    final keyData = await ED25519_HD_KEY.derivePath(
      path,
      seed,
    );

    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: keyData.key,
    );

    return keyPair.address;
  }

  /// 私钥 hex（仅运行时用）
  static String _bytesToHex(Uint8List bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}