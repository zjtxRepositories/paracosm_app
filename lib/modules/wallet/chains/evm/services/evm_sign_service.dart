

class EvmSignService {

  /// =========================
  /// signMessage
  /// =========================
  static Future<String> signMessage({
    required String address,
    required String message,
  }) async {
    // final privateKey = EvmService.getPrivateKeyByAddress(address);
    // if (privateKey == null) throw Exception("找不到该钱包");
    // final credentials = EthPrivateKey.fromHex(privateKey);
    //
    // /// 1️⃣ 统一 bytes（⭐关键：全部转 List<int>）
    // final List<int> messageBytes = message.startsWith('0x')
    //     ? hexToBytes(message).toList()
    //     : utf8.encode(message);

    // /// 2️⃣ 转 Uint8List（只做一次）
    // final Uint8List data = Uint8List.fromList(messageBytes);
    //
    // /// 3️⃣ 使用 web3dart 官方方法
    // final signature = credentials.signPersonalMessageToUint8List(fix(data));
    //
    // /// 4️⃣ 转 hex
    // return bytesToHex(signature, include0x: true);
    return '';
  }

}