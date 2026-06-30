import 'package:flutter/foundation.dart';
import 'package:paracosm/modules/wallet/chains/btc/bitcoin_chain_service.dart';
import 'package:paracosm/modules/wallet/chains/sol/solana_chain_service.dart';
import 'package:paracosm/modules/wallet/chains/tron/tron_chain_service.dart';

import '../../model/chain_account.dart';
import '../../model/token_model.dart';
import '../evm/evm_facade.dart';

class BalanceService {
  static final BalanceService _instance = BalanceService._internal();
  factory BalanceService() => _instance;
  BalanceService._internal();

  static const String _debugUsdtContract =
      '0x3f4b84b037eadb4d3d3d7f44f4bfccea53cf1dd1';

  /// =========================
  /// 获取单个 token 的余额
  /// =========================
  Future<TokenModel> getTokenBalance(TokenModel token) async {
    final chain = token.getChain();
    if (chain == null) return token;

    switch (chain.chainType) {
      case ChainType.evm:
        if (!EvmFacade.isValidAddress(chain.address)) {
          token.balance = BigInt.zero;
          break;
        }
        final balance = await EvmFacade.getBalance(
          chain,
          chain.address,
          contractAddress: token.address,
        );
        token.balance = balance;
        _debugPrintTargetTokenBalance(token, chain);
        break;
      case ChainType.solana:
        if (chain.address.isEmpty) {
          token.balance = BigInt.zero;
          break;
        }
        token.balance = await SolanaChainService().getBalance(chain.address);
        break;

      case ChainType.bitcoin:
        if (chain.address.isEmpty) {
          token.balance = BigInt.zero;
          break;
        }
        token.balance = await BitcoinChainService().getBalance(chain.address);
        break;
      case ChainType.tron:
        if (chain.address.isEmpty) {
          token.balance = BigInt.zero;
          break;
        }
        token.balance = await TronChainService().getBalance(
          chain.address,
          contractAddress: token.address,
          node: chain.nodes.isNotEmpty
              ? chain.nodes.first
              : 'https://api.trongrid.io',
        );
        break;
    }

    return token;
  }

  void _debugPrintTargetTokenBalance(TokenModel token, ChainAccount chain) {
    if (token.address.trim().toLowerCase() != _debugUsdtContract) return;
    debugPrint(
      'USDT balance debug: '
      'chainId=${chain.chainId}, '
      'wallet=${chain.address}, '
      'contract=${token.address}, '
      'raw=${token.balance}, '
      'display=${token.displayBalance} ${token.symbol}',
    );
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
