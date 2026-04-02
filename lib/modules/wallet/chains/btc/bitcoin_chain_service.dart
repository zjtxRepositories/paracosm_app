import 'package:bdk_flutter/bdk_flutter.dart';

import 'bitcoin_service.dart';

class BitcoinChainService {
  /// 缓存
  BigInt? _cachedBalance;
  DateTime? _lastFetchTime;

  /// 缓存时间（秒）
  static const int _cacheSeconds = 10;

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
}