import 'package:paracosm/modules/wallet/chains/btc/bitcoin_chain_service.dart';
import 'package:paracosm/modules/wallet/chains/evm/evm_chain_service.dart';
import 'package:paracosm/modules/wallet/chains/sol/solana_chain_service.dart';

import '../../model/chain_account.dart';
import '../../model/token_model.dart';


class BalanceService {
  static final BalanceService _instance = BalanceService._internal();
  factory BalanceService() => _instance;
  BalanceService._internal();

  /// =========================
  /// 获取单个 token 的余额
  /// =========================
  Future<TokenModel> getTokenBalance(TokenModel token) async {
    final chain = token.getChain();
    if (chain == null) return token;

    switch (chain.chainType) {
      case ChainType.evm:
        if (token.address.isNotEmpty) {
          final balance = await EvmChainService.getTokenBalance(
            chain,
            token.address,
            chain.address,
          );
          token.balance = balance;
          break;
        }
        final balance = await EvmChainService.getNativeBalance(
          chain,
          chain.address,
        );
        token.balance = balance;
        break;

      case ChainType.solana:
        token.balance = await SolanaChainService().getBalance();
        break;

      case ChainType.bitcoin:
        token.balance = await BitcoinChainService().getBalance();
        break;
    }

    return token;
  }

  /// =========================
  /// 获取多个 token 的余额（并发）
  /// =========================
  Future<List<TokenModel>> getTokenBalances(List<TokenModel> tokens) async {
    final futures = tokens.map((t) => getTokenBalance(t));
    final results = await Future.wait(futures);
    return results;
  }

}