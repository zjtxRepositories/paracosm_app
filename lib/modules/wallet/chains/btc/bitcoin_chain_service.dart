import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:paracosm/core/network/client/http_client.dart';
import 'package:paracosm/modules/wallet/model/transaction_model.dart';
import '../model/gas_fee.dart';
import 'bitcoin_service.dart';
import 'bitcoin_tx_detail.dart';

class BitcoinChainService {
  /// 缓存
  BigInt? _cachedBalance;
  DateTime? _lastFetchTime;

  /// 缓存时间（秒）
  static const int _cacheSeconds = 10;

  /// ⭐ fee缓存（避免频繁请求）
  static BtcFeeRate? _feeCache;
  static int _feeCacheTime = 0;

  /// ⭐ mempool API（主网）
  static const String _feeUrl =
      "https://mempool.space/api/v1/fees/recommended";


  /// =========================
  /// 获取余额
  /// =========================
  Future<BigInt> getBalance(
      String address, {
        bool forceRefresh = false,
      }) async {
    final now = DateTime.now();

    /// ✅ 缓存命中
    if (!forceRefresh &&
        _cachedBalance != null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!).inSeconds < _cacheSeconds) {
      return _cachedBalance!;
    }

    /// ✅ 通过 address 找钱包
    final wallet = BitcoinService.getWalletByAddress(address);

    if (wallet == null) {
      throw Exception("Wallet not found for address: $address");
    }

    /// ✅ 同步（注意：你需要一个 syncByAddress 或 syncByDescriptor）
    final descriptor = BitcoinService.getDescriptorByAddress(address);
    if (descriptor == null) {
      throw Exception("Descriptor not found for address");
    }

    await BitcoinService.syncByDescriptor(descriptor);

    /// ✅ 获取余额
    final balance = wallet.getBalance();
    final total = balance.total;

    print('钱包余额: $total satoshis');

    _cachedBalance = total;
    _lastFetchTime = now;

    return total;
  }

  /// =========================
  /// 获取交易记录
  /// =========================
  Future<List<TransactionDetails>> getTransactions(String address) async {
    final wallet = BitcoinService.getWalletByAddress(address);

    if (wallet == null) {
      throw Exception("Wallet not found for address: $address");
    }

    final descriptor = BitcoinService.getDescriptorByAddress(address);
    if (descriptor == null) {
      throw Exception("Descriptor not found for address");
    }

    await BitcoinService.syncByDescriptor(descriptor);

    return wallet.listTransactions(includeRaw: false);
  }

  /// =========================
  /// 发送 BTC
  /// =========================
  static Future<String> sendTransaction({
    required String fromAddress,
    required String toAddress,
    required BigInt amount, // satoshis
    double? feePerVbyte, // 可选：自定义 sat/vByte
    bool isSegWit = true,
  }) async {
    final wallet = BitcoinService.getWalletByAddress(fromAddress);
    if (wallet == null) throw Exception("Wallet not found");

    final descriptor = BitcoinService.getDescriptorByAddress(fromAddress);
    if (descriptor == null) throw Exception("Descriptor not found");

    final blockchain = BitcoinService().blockchain;
    if (blockchain == null) throw Exception("blockchain not found");

    // 同步钱包
    await BitcoinService.syncByDescriptor(descriptor);

    // 获取手续费，如果没传 feePerVbyte，就用默认中速费率
    double feeRateUsed = feePerVbyte ?? (await BitcoinChainService.getFeeEstimate(
      inputs: 1,
      outputs: 2,
      isSegWit: isSegWit,
    ))["medium"]!.toDouble();
    final service = BitcoinService();
    // 构建 ScriptBuf
    final addressObj = await Address.fromString(s: toAddress, network: service.network);
    final script = addressObj.scriptPubkey();

    // 构建交易
    final builder = TxBuilder()
      ..addRecipient(script, amount)
      ..feeRate(feeRateUsed)
      ..enableRbf(); // 可选

    // 构建并签名
    final result = await builder.finish(wallet);
    final psbt = result.$1;
    wallet.sign(psbt: psbt);
    final tx = psbt.extractTx();
    final txId = await blockchain.broadcast(transaction: tx);

    return txId;
  }

  /// =========================
  /// 获取交易详情
  /// =========================
  Future<BitcoinTxDetail?> getTransactionDetail(
      String address,
      String txid,
      ) async {
    try {
      final txs = await getTransactions(address);

      final tx = txs.firstWhere(
            (e) => e.txid == txid,
        orElse: () => throw Exception("tx not found"),
      );
      final currentHeight = tx.confirmationTime?.height ?? 0;
      ///  confirmations
      final confirmations = tx.confirmationTime != null
          ? currentHeight - tx.confirmationTime!.height + 1
          : 0;

      /// 时间
      DateTime? time;
      if (tx.confirmationTime != null) {
        final timestamp = tx.confirmationTime!.timestamp;
        time = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
      }

      /// 金额（注意：正负）
      final value = tx.received - tx.sent;

      ///  fee
      final fee = tx.fee ?? BigInt.zero;

      /// 地址（简单取）
      final from = tx.sent > BigInt.zero ? "me" : "external";
      final to = tx.received > BigInt.zero ? "me" : "external";
      return BitcoinTxDetail(
        txid: tx.txid,
        from: from,
        to: to,
        value: value,
        fee: fee,
        confirmations: confirmations,
        time: time,
      );
    } catch (e) {
      print("❌ BTC tx error: $e");
      return null;
    }
  }

  /// =========================
  /// 获取BTC手续费（慢 / 中 / 快）
  /// =========================
  static Future<BtcFeeRate> getFeeRate() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    /// ✅ 10秒缓存
    if (_feeCache != null && now - _feeCacheTime < 10000) {
      return _feeCache!;
    }

    try {
      final response = await HttpClient().get(_feeUrl);
      final data = response.data;
      final result = BtcFeeRate(
        slow: data['hourFee'] ?? 10,
        medium: data['halfHourFee'] ?? 15,
        fast: data['fastestFee'] ?? 25,
      );

      _feeCache = result;
      _feeCacheTime = now;

      return result;
    } catch (e) {
      /// ⭐ fallback（防止接口挂）
      return BtcFeeRate(
        slow: 10,
        medium: 15,
        fast: 25,
      );
    }
  }

  /// =========================
  /// 估算交易大小（bytes）
  /// =========================
  static int estimateTxSize({
    required int inputs,
    required int outputs,
    bool isSegWit = true,
  }) {
    if (isSegWit) {
      /// SegWit更省手续费
      return inputs * 68 + outputs * 31 + 10;
    } else {
      return inputs * 148 + outputs * 34 + 10;
    }
  }

  /// =========================
  /// 计算手续费（satoshi）
  /// =========================
  static int estimateFee({
    required int feeRate, // sat/vByte
    required int txSize,
  }) {
    return feeRate * txSize;
  }

  /// =========================
  /// 🚀 一步获取最终手续费（推荐用这个）
  /// =========================
  static Future<Map<String, int>> getFeeEstimate({
    required int inputs,
    required int outputs,
    bool isSegWit = true,
  }) async {
    final feeRate = await getFeeRate();

    final txSize = estimateTxSize(
      inputs: inputs,
      outputs: outputs,
      isSegWit: isSegWit,
    );

    return {
      "slow": estimateFee(
        feeRate: feeRate.slow,
        txSize: txSize,
      ),
      "medium": estimateFee(
        feeRate: feeRate.medium,
        txSize: txSize,
      ),
      "fast": estimateFee(
        feeRate: feeRate.fast,
        txSize: txSize,
      ),
    };
  }
}