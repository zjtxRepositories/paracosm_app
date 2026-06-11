import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/wallet/chains/model/coin_market_model.dart';
import 'package:paracosm/modules/wallet/chains/service/portfolio_service.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';

void main() {
  group('PortfolioService Ave price refresh', () {
    test('builds Ave token ids for native and contract tokens', () async {
      final requestedIds = <String>[];
      final service = PortfolioService.forTesting(
        ownerIdProvider: () => 'wallet-1',
        balanceFetcher: (token) async => token,
        marketSyncer: (_, _) async {},
        avePriceFetcher: (tokenIds) async {
          requestedIds.addAll(tokenIds);
          return {};
        },
      );

      service.start(
        [
          _token(symbol: 'BNB', chainId: 56, isNative: true),
          _token(symbol: 'ETH', chainId: 1, isNative: true),
          _token(symbol: 'SOL', chainId: 101, isNative: true),
          _token(symbol: 'TRX', chainId: 728126428, isNative: true),
          _token(symbol: 'BTC', chainId: 0, isNative: true),
          _token(
            symbol: 'USDT',
            chainId: 56,
            address: '0x55d398326f99059fF775485246999027B3197955',
          ),
          _token(
            symbol: 'USDT',
            chainId: 728126428,
            address: 'TXLAQ63Xg1NAzckPwKHvzw7CSEmLMEqcdj',
          ),
          _token(
            symbol: 'USDC',
            chainId: 101,
            address: 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
          ),
        ],
        ownerId: 'wallet-1',
        interval: 3600,
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        requestedIds,
        containsAll([
          '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-bsc',
          '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-eth',
          '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-solana',
          '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-tron',
          '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-btc',
          '0x55d398326f99059ff775485246999027b3197955-bsc',
          'TXLAQ63Xg1NAzckPwKHvzw7CSEmLMEqcdj-tron',
          'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v-solana',
        ]),
      );

      service.dispose();
    });

    test('writes Ave price and change to token market and total USD', () async {
      final token = _token(
        symbol: 'BNB',
        chainId: 56,
        isNative: true,
        balance: BigInt.from(2) * BigInt.from(10).pow(18),
      );
      final service = PortfolioService.forTesting(
        ownerIdProvider: () => 'wallet-1',
        balanceFetcher: (token) async => token,
        marketSyncer: (_, _) async {},
        avePriceFetcher: (_) async {
          return {
            '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-bsc': {
              'current_price_usd': '592.5',
              'price_change_24h': '0.85',
            },
          };
        },
      );

      final tokensFuture = service.stream.firstWhere(
        (tokens) => tokens.isNotEmpty && tokens.first.price == 592.5,
      );
      final totalFuture = service.totalUsdStream.firstWhere(
        (total) => total > 0,
      );

      service.start([token], ownerId: 'wallet-1', interval: 3600);

      final emittedTokens = await tokensFuture;
      final total = await totalFuture;

      expect(emittedTokens.first.price, 592.5);
      expect(emittedTokens.first.market?.close, 592.5);
      expect(emittedTokens.first.market?.chg, 0.85);
      expect(emittedTokens.first.market?.change, 0.85);
      expect(total, 1185);

      service.dispose();
    });

    test('syncs updated Ave markets back to wallet storage', () async {
      final token = _token(
        symbol: 'BNB',
        chainId: 56,
        isNative: true,
        balance: BigInt.from(2) * BigInt.from(10).pow(18),
      );
      final syncCompleter = Completer<List<TokenModel>>();
      final service = PortfolioService.forTesting(
        ownerIdProvider: () => 'wallet-1',
        balanceFetcher: (token) async => token,
        marketSyncer: (walletId, tokens) async {
          expect(walletId, 'wallet-1');
          if (!syncCompleter.isCompleted) {
            syncCompleter.complete(List<TokenModel>.from(tokens));
          }
        },
        avePriceFetcher: (_) async {
          return {
            '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-bsc': {
              'current_price_usd': '592.5',
              'price_change_24h': '0.85',
            },
          };
        },
      );

      service.start([token], ownerId: 'wallet-1', interval: 3600);

      final syncedTokens = await syncCompleter.future;

      expect(syncedTokens, hasLength(1));
      expect(syncedTokens.first.price, 592.5);
      expect(syncedTokens.first.market?.close, 592.5);
      expect(syncedTokens.first.market?.chg, 0.85);

      service.dispose();
    });

    test('still emits priced tokens when wallet market sync fails', () async {
      final token = _token(symbol: 'BNB', chainId: 56, isNative: true);
      final service = PortfolioService.forTesting(
        ownerIdProvider: () => 'wallet-1',
        balanceFetcher: (token) async => token,
        marketSyncer: (_, _) async => throw StateError('db failed'),
        avePriceFetcher: (_) async {
          return {
            '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-bsc': {
              'current_price_usd': '600',
              'price_change_24h': '1.5',
            },
          };
        },
      );

      final tokensFuture = service.stream.firstWhere(
        (tokens) => tokens.isNotEmpty && tokens.first.price == 600,
      );

      service.start([token], ownerId: 'wallet-1', interval: 3600);

      final emittedTokens = await tokensFuture;

      expect(emittedTokens.first.price, 600);
      expect(emittedTokens.first.market?.close, 600);
      expect(emittedTokens.first.market?.chg, 1.5);

      service.dispose();
    });

    test('uses zero change when Ave omits price_change_24h', () async {
      final token = _token(symbol: 'BNB', chainId: 56, isNative: true);
      final service = PortfolioService.forTesting(
        ownerIdProvider: () => 'wallet-1',
        balanceFetcher: (token) async => token,
        marketSyncer: (_, _) async {},
        avePriceFetcher: (_) async {
          return {
            '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-bsc': {
              'current_price_usd': '592.5',
            },
          };
        },
      );

      final tokensFuture = service.stream.firstWhere(
        (tokens) => tokens.isNotEmpty && tokens.first.price == 592.5,
      );

      service.start([token], ownerId: 'wallet-1', interval: 3600);

      final emittedTokens = await tokensFuture;
      expect(emittedTokens.first.market?.chg, 0);
      expect(emittedTokens.first.market?.change, 0);

      service.dispose();
    });

    test('keeps existing price and market when Ave omits token', () async {
      final token = _token(
        symbol: 'UNKNOWN',
        chainId: 56,
        isNative: true,
        price: 12,
        market: _market(price: 12, change: 3),
        balance: BigInt.from(3) * BigInt.from(10).pow(18),
      );
      final service = PortfolioService.forTesting(
        ownerIdProvider: () => 'wallet-1',
        balanceFetcher: (token) async => token,
        marketSyncer: (_, _) async {},
        avePriceFetcher: (_) async => {},
      );

      final tokensFuture = service.stream.firstWhere(
        (tokens) => tokens.isNotEmpty && tokens.first.price == 12,
      );
      final totalFuture = service.totalUsdStream.firstWhere(
        (total) => total > 0,
      );

      service.start([token], ownerId: 'wallet-1', interval: 3600);

      final emittedTokens = await tokensFuture;
      final total = await totalFuture;

      expect(emittedTokens.first.price, 12);
      expect(emittedTokens.first.market?.close, 12);
      expect(emittedTokens.first.market?.chg, 3);
      expect(total, 36);

      service.dispose();
    });

    test('skips unknown chains instead of guessing Ave chain name', () async {
      final requestedIds = <String>[];
      final token = _token(
        symbol: 'TEST',
        chainId: 999999,
        isNative: true,
        price: 10,
        balance: BigInt.from(2) * BigInt.from(10).pow(18),
      );
      final service = PortfolioService.forTesting(
        ownerIdProvider: () => 'wallet-1',
        balanceFetcher: (token) async => token,
        marketSyncer: (_, _) async {},
        avePriceFetcher: (tokenIds) async {
          requestedIds.addAll(tokenIds);
          return {};
        },
      );
      final totalFuture = service.totalUsdStream.firstWhere(
        (total) => total > 0,
      );

      service.start([token], ownerId: 'wallet-1', interval: 3600);
      final total = await totalFuture;

      expect(requestedIds, isEmpty);
      expect(total, 20);

      service.dispose();
    });
  });
}

TokenModel _token({
  required String symbol,
  required int chainId,
  String address = '',
  bool isNative = false,
  double price = 0,
  CoinMarketModel? market,
  BigInt? balance,
}) {
  return TokenModel(
    symbol: symbol,
    name: symbol,
    address: address,
    balance: balance ?? BigInt.zero,
    decimals: 18,
    logo: '',
    coinId: '',
    chainId: chainId,
    isNative: isNative || address.isEmpty,
    price: price,
    market: market,
  );
}

CoinMarketModel _market({required double price, required double change}) {
  return CoinMarketModel(
    symbol: 'TOKEN/USDT',
    high: price,
    low: price,
    close: price,
    chg: change,
    change: change,
    volume: 0,
    turnover: 0,
    coinImg: '',
  );
}
