import 'package:bdk_flutter/bdk_flutter.dart';

import 'bitcoin_service.dart';

class BitcoinChainService {
  final BitcoinService _btcService = BitcoinService();

  /// 缓存
  BigInt? _cachedBalance;
  DateTime? _lastFetchTime;

  /// 缓存时间（秒）
  static const int _cacheSeconds = 10;

  /// =========================
  /// 获取余额
  /// =========================
  Future<BigInt> getBalance({bool forceRefresh = false}) async {
    final now = DateTime.now();

    /// 缓存命中
    if (!forceRefresh &&
        _cachedBalance != null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!).inSeconds < _cacheSeconds) {
      return _cachedBalance!;
    }

    final wallet = _btcService.wallet;

    /// ⚠️ 必须先同步
    await BitcoinService.sync();

    final balance = wallet.getBalance();
    final total = balance.total;
    final btc = satoshiToBtc(total);
    print('钱包余额: ${balance.total} satoshis---$btc btc');
    _cachedBalance = balance.total;
    _lastFetchTime = now;

    return balance.total;
  }

  /// =========================
  /// 获取交易记录
  /// =========================
  Future<List<TransactionDetails>> getTransactions() async {
    final wallet = _btcService.wallet;

    await BitcoinService.sync();

    return wallet.listTransactions(includeRaw: false);
  }

  // /// =========================
  // /// 创建交易（未广播）
  // /// =========================
  // Future<PartiallySignedTransaction> createTx({
  //   required String toAddress,
  //   required int amount, // satoshi
  //   int feeRate = 2, // sat/vbyte
  // }) async {
  //   final wallet = _btcService.wallet;
  //
  //   final txBuilder = TxBuilder();
  //
  //   txBuilder.addRecipient(
  //     address: Address(address: toAddress),
  //     amount: amount,
  //   );
  //
  //   txBuilder.feeRate(feeRate.toDouble());
  //
  //   final result = await wallet.createTx(txBuilder: txBuilder);
  //
  //   return result.psbt;
  // }
  //
  // /// =========================
  // /// 签名交易
  // /// =========================
  // Future<bool> signTx(PartiallySignedTransaction psbt) async {
  //   final wallet = _btcService.wallet;
  //
  //   final result = await wallet.sign(psbt: psbt);
  //
  //   return result.isFinalized;
  // }
  //
  // /// =========================
  // /// 广播交易
  // /// =========================
  // Future<String> broadcastTx(PartiallySignedTransaction psbt) async {
  //   await _initBlockchain();
  //
  //   final tx = psbt.extractTx();
  //
  //   await _blockchain!.broadcast(tx);
  //
  //   return tx.txid;
  // }


   double satoshiToBtc(BigInt satoshi) {
    return satoshi.toDouble() / 100000000;
  }

  // BTC 转 satoshi
  BigInt btcToSatoshi(double btc) {
    return BigInt.from(btc * 100000000);
  }
}