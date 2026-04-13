import 'package:paracosm/modules/wallet/chains/btc/bitcoin_chain_service.dart';
import 'package:paracosm/modules/wallet/chains/evm/evm_facade.dart';
import 'package:paracosm/modules/wallet/chains/evm/services/evm_transaction_service.dart';
import 'package:paracosm/modules/wallet/chains/sol/solana_chain_service.dart';
import 'package:solana/dto.dart';
import '../chains/evm/evm_chain_service.dart';
import '../model/chain_account.dart';
import '../model/token_model.dart';
import '../model/transaction_model.dart';

/// 转账状态
enum TransferStatus {
  waiting,
  success,
  fail,
}

/// 统一返回
class TransactionResult {
  final TransactionModel model;
  final TransferStatus status;

  TransactionResult({
    required this.model,
    required this.status,
  });
}

class TransactionService {
  /// =========================
  /// 统一入口
  /// =========================
  static Future<TransactionResult?> fetchTransaction({
    required ChainAccount chain,
    required TokenModel token,
    required String txHash,
    required void Function(TransactionModel model)? onPending,
  }) async {
    switch (chain.chainType) {
      case ChainType.evm:
        return _fetchEvm(
          chain: chain,
          token: token,
          txHash: txHash,
          onPending: onPending,
        );

      case ChainType.solana:
        return _fetchSol(
          chain: chain,
          token: token,
          txHash: txHash,
          onPending: onPending,
        );

      case ChainType.bitcoin:
        return _fetchBitcoin(
          chain: chain,
          token: token,
          txHash: txHash,
          onPending: onPending,
        );
    }
  }

  /// =========================
  /// ✅ 统一状态映射（核心）
  /// =========================
  static TransferStatus _mapStatus({
    bool? evmStatus,
    int? btcConfirmations,
    dynamic solErr,
    ConfirmationStatus? solConfirmation,
  }) {
    /// EVM
    if (evmStatus != null) {
      return evmStatus ? TransferStatus.success : TransferStatus.fail;
    }

    /// BTC
    if (btcConfirmations != null) {
      return btcConfirmations > 0
          ? TransferStatus.success
          : TransferStatus.waiting;
    }

    /// SOL
    if (solErr != null) return TransferStatus.fail;

    if (solConfirmation == ConfirmationStatus.finalized) {
      return TransferStatus.success;
    }

    return TransferStatus.waiting;
  }

  /// =========================
  /// EVM
  /// =========================
  static Future<TransactionResult?> _fetchEvm({
    required ChainAccount chain,
    required TokenModel token,
    required String txHash,
    void Function(TransactionModel model)? onPending,
  }) async {
    final tx =
    await EvmTransactionService.getTransactionDetail(chain, txHash);

    if (tx == null) return null;

    /// pending 先返回
    final pendingModel = TransactionModel(
      hash: tx.hash,
      from: tx.from.hex,
      to: tx.to?.hex ?? '',
      value: tx.value.getInWei,
      fee: null,
      logo: token.logo,
      time: null,
      decimals: token.decimals,
      symbol: token.symbol,
    );

    onPending?.call(pendingModel);

    final receipt = await EvmTransactionService.waitForTransaction(
      chain: chain,
      txHash: txHash,
    );

    if (receipt == null) {
      return TransactionResult(
        model: pendingModel,
        status: TransferStatus.waiting,
      );
    }

    /// gas fee
    BigInt? fee;
    if (receipt.gasUsed != null) {
      fee = receipt.gasUsed! * tx.gasPrice.getInWei;
    }

    /// ✅ 获取真实时间（区块时间）
    DateTime? time;
    final block = await EvmFacade.getBlock(chain);
    if (block != null) {
      time = block.timestamp;
    }

    final finalModel = TransactionModel(
      hash: tx.hash,
      from: tx.from.hex,
      to: tx.to?.hex ?? '',
      value: tx.value.getInWei,
      fee: fee,
      logo: token.logo,
      time: time,
      decimals: token.decimals,
      symbol: token.symbol,
    );

    return TransactionResult(
      model: finalModel,
      status: _mapStatus(
        evmStatus: receipt.status,
      ),
    );
  }

  /// =========================
  /// BTC
  /// =========================
  static Future<TransactionResult?> _fetchBitcoin({
    required ChainAccount chain,
    required TokenModel token,
    required String txHash,
    void Function(TransactionModel model)? onPending,
  }) async {
    final tx = await BitcoinChainService()
        .getTransactionDetail(chain.address, txHash);

    if (tx == null) return null;

    final pendingModel = TransactionModel(
      hash: tx.txid,
      from: tx.from,
      to: tx.to,
      value: tx.value,
      fee: tx.fee,
      logo: token.logo,
      time: tx.time,
      decimals: token.decimals,
      symbol: token.symbol,
    );

    onPending?.call(pendingModel);

    return TransactionResult(
      model: pendingModel,
      status: _mapStatus(
        btcConfirmations: tx.confirmations,
      ),
    );
  }

  /// =========================
  /// SOL
  /// =========================
  static Future<TransactionResult?> _fetchSol({
    required ChainAccount chain,
    required TokenModel token,
    required String txHash,
    void Function(TransactionModel model)? onPending,
  }) async {
    final tx = await SolanaChainService()
        .getTransactionDetail(chain.address, txHash);

    if (tx == null) return null;

    final pendingModel = TransactionModel(
      hash: tx.hash,
      from: tx.from,
      to: tx.to,
      value: tx.value,
      fee: tx.fee,
      logo: token.logo,
      time: tx.time,
      decimals: token.decimals,
      symbol: token.symbol,
    );

    onPending?.call(pendingModel);

    /// ✅ 获取确认状态
    final confirmation =
    await SolanaChainService().getConfirmationStatus(txHash);

    final finalModel = TransactionModel(
      hash: tx.hash,
      from: tx.from,
      to: tx.to,
      value: tx.value,
      fee: tx.fee,
      logo: token.logo,
      time: tx.time,
      decimals: token.decimals,
      symbol: token.symbol,
    );

    return TransactionResult(
      model: finalModel,
      status: _mapStatus(
        solErr: tx.err,
        solConfirmation: confirmation,
      ),
    );
  }
}