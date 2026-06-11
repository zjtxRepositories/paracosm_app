import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/wallet/chains/model/coin_market_model.dart';
import 'package:paracosm/modules/wallet/manager/wallet_manager.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';

void main() {
  group('WalletManager token market preservation', () {
    test('preserves price and market when incoming token has no market', () {
      final existing = _token(
        symbol: 'USDT',
        address: '0x55d398326f99059ff775485246999027b3197955',
        price: 1,
        market: _market(price: 1, change: 0.1),
        isAdded: true,
      );
      final incoming = _token(
        symbol: 'USDT',
        address: '0x55d398326f99059ff775485246999027b3197955',
        price: 0,
        isAdded: false,
      );

      final merged = WalletManager.mergeTokenPreservingMarket(
        existing,
        incoming,
      );

      expect(merged.isAdded, isFalse);
      expect(merged.price, 1);
      expect(merged.market?.close, 1);
      expect(merged.market?.chg, 0.1);
    });

    test('updates contract token market by chain and address only', () {
      final wallet = _wallet([
        _chain(
          chainId: 56,
          tokens: [
            _token(
              symbol: 'USDT',
              address: '0x55d398326f99059fF775485246999027B3197955',
              balance: BigInt.from(100),
              isAdded: true,
              logo: 'old-logo',
            ),
          ],
        ),
      ]);
      final updatedToken = _token(
        symbol: 'USDT',
        address: '0x55d398326f99059ff775485246999027b3197955',
        price: 1,
        market: _market(price: 1, change: -0.01),
        balance: BigInt.zero,
        isAdded: false,
        logo: 'new-logo',
      );

      final changed = WalletManager.applyTokenMarketUpdates(wallet, [
        updatedToken,
      ]);

      final token = wallet.chains.first.tokens.first;
      expect(changed, isTrue);
      expect(token.price, 1);
      expect(token.market?.close, 1);
      expect(token.market?.chg, -0.01);
      expect(token.balance, BigInt.from(100));
      expect(token.isAdded, isTrue);
      expect(token.logo, 'old-logo');
    });

    test('updates native token market by chain and symbol', () {
      final wallet = _wallet([
        _chain(
          chainId: 56,
          tokens: [_token(symbol: 'BNB', balance: BigInt.from(10))],
        ),
      ]);
      final updatedToken = _token(
        symbol: 'BNB',
        price: 592.5,
        market: _market(price: 592.5, change: 0.85),
      );

      final changed = WalletManager.applyTokenMarketUpdates(wallet, [
        updatedToken,
      ]);

      final token = wallet.chains.first.tokens.first;
      expect(changed, isTrue);
      expect(token.price, 592.5);
      expect(token.market?.close, 592.5);
      expect(token.market?.chg, 0.85);
      expect(token.balance, BigInt.from(10));
    });

    test('does not add or update unmatched tokens', () {
      final wallet = _wallet([
        _chain(chainId: 56, tokens: [_token(symbol: 'BNB')]),
      ]);
      final updatedToken = _token(
        symbol: 'USDT',
        address: '0x55d398326f99059ff775485246999027b3197955',
        price: 1,
        market: _market(price: 1, change: 0),
      );

      final changed = WalletManager.applyTokenMarketUpdates(wallet, [
        updatedToken,
      ]);

      expect(changed, isFalse);
      expect(wallet.chains.first.tokens, hasLength(1));
      expect(wallet.chains.first.tokens.first.symbol, 'BNB');
      expect(wallet.chains.first.tokens.first.price, 0);
    });
  });
}

WalletModel _wallet(List<ChainAccount> chains) {
  return WalletModel(
    id: 'wallet-1',
    aIndex: 0,
    chains: chains,
    type: WalletType.mnemonic,
    currentChainId: chains.first.chainId,
  );
}

ChainAccount _chain({required int chainId, required List<TokenModel> tokens}) {
  return ChainAccount(
    name: 'Chain $chainId',
    address: '0xabc',
    chainId: chainId,
    logo: '',
    symbol: 'BNB',
    tokens: tokens,
    chainType: ChainType.evm,
    nodes: const [],
  );
}

TokenModel _token({
  required String symbol,
  String address = '',
  double price = 0,
  CoinMarketModel? market,
  BigInt? balance,
  bool? isAdded,
  bool? isNative,
  String logo = '',
}) {
  return TokenModel(
    symbol: symbol,
    name: symbol,
    address: address,
    balance: balance ?? BigInt.zero,
    decimals: 18,
    logo: logo,
    coinId: '',
    chainId: 56,
    isAdded: isAdded,
    isNative: isNative ?? address.isEmpty,
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
