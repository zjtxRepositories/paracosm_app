import 'package:paracosm/modules/wallet/chains/evm/services/evm_gas_service.dart';
import 'package:web3dart/contracts.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import '../../../model/chain_account.dart';
import '../../model/gas_fee.dart';
import '../client/evm_client_manager.dart';
import '../evm_service.dart';

class EvmTransactionService {

  /// =========================
  /// 🚀 转账入口
  /// =========================
  static Future<String> sendTransaction({
    required ChainAccount chain,
    required String contractAddress,
    required String to,
    required BigInt amountWei,
    GasFee? gasFee,
    String? customData,
  }) async {
    if (!EvmService.isValidAddress(to)) throw '地址不合法';

    final privateKey =
    EvmService.getPrivateKeyByAddress(chain.address);
    if (privateKey == null) throw '没有找到该钱包！';

    if (contractAddress.isEmpty) {
      return sendNativeTransaction(
        chain: chain,
        privateKey: privateKey,
        to: to,
        amountWei: amountWei,
        gasFee: gasFee,
      );
    }

    return sendErc20Transaction(
      chain: chain,
      privateKey: privateKey,
      contractAddress: contractAddress,
      to: to,
      amount: amountWei,
      gasFee: gasFee,
    );
  }

  /// =========================
  /// 原生转账
  /// =========================
  static Future<String> sendNativeTransaction({
    required ChainAccount chain,
    required String privateKey,
    required String to,
    required BigInt amountWei,
    GasFee? gasFee,
  }) async {
    return EvmClientManager.withFallback(chain.chainId, chain.nodes, (client) async {
      final credentials = EthPrivateKey.fromHex(privateKey);
      final from = credentials.address;

      final nonce = await _getSafeNonce(client, from.hex);
      final gas = gasFee ?? (await EvmGasService.getGasLevels(chain)).medium;

      final gasLimit = await estimateGas(
        client,
        from: from.hex,
        to: to,
        value: amountWei,
      );

      final latestBlock = await client.getBlockInformation();
      final supports1559 = latestBlock.baseFeePerGas != null;

      final maxPriorityFee = supports1559
          ? (gas.maxPriorityFeePerGas > BigInt.zero
          ? gas.maxPriorityFeePerGas
          : BigInt.from(1000000000))
          : null;

      final tx = Transaction(
        from: from,
        to: EthereumAddress.fromHex(to),
        value: EtherAmount.inWei(amountWei),
        nonce: nonce,
        maxGas: gasLimit.toInt(),
        gasPrice:
        supports1559 ? null : EtherAmount.inWei(gas.gasPrice!),
        maxFeePerGas: supports1559
            ? EtherAmount.inWei(gas.maxFeePerGas)
            : null,
        maxPriorityFeePerGas: supports1559
            ? EtherAmount.inWei(maxPriorityFee!)
            : null,
      );

      final signed = await client.signTransaction(
        credentials,
        tx,
        chainId: chain.chainId,
      );

      return client.sendRawTransaction(signed);
    });
  }

  /// =========================
  /// ERC20转账
  /// =========================
  static Future<String> sendErc20Transaction({
    required ChainAccount chain,
    required String privateKey,
    required String contractAddress,
    required String to,
    required BigInt amount,
    GasFee? gasFee,
  }) async {
    return EvmClientManager.withFallback(chain.chainId, chain.nodes, (client) async {
      final credentials = EthPrivateKey.fromHex(privateKey);
      final from = credentials.address;

      final contract = DeployedContract(
        ContractAbi.fromJson(_erc20TransferAbi, 'ERC20'),
        EthereumAddress.fromHex(contractAddress),
      );

      final data = Transaction
          .callContract(
        contract: contract,
        function: contract.function('transfer'),
        parameters: [EthereumAddress.fromHex(to), amount],
      )
          .data!;

      final nonce = await _getSafeNonce(client, from.hex);
      final gas = gasFee ?? (await EvmGasService.getGasLevels(chain)).medium;

      final gasLimit = await estimateGas(
        client,
        from: from.hex,
        to: contractAddress,
        value: BigInt.zero,
        data: bytesToHex(data, include0x: true),
      );

      final latestBlock = await client.getBlockInformation();
      final supports1559 = latestBlock.baseFeePerGas != null;

      final maxPriorityFee = supports1559
          ? (gas.maxPriorityFeePerGas > BigInt.zero
          ? gas.maxPriorityFeePerGas
          : BigInt.from(1000000000))
          : null;

      final tx = Transaction(
        from: from,
        to: EthereumAddress.fromHex(contractAddress),
        data: data,
        nonce: nonce,
        maxGas: gasLimit.toInt(),
        gasPrice:
        supports1559 ? null : EtherAmount.inWei(gas.gasPrice!),
        maxFeePerGas: supports1559
            ? EtherAmount.inWei(gas.maxFeePerGas)
            : null,
        maxPriorityFeePerGas: supports1559
            ? EtherAmount.inWei(maxPriorityFee!)
            : null,
      );

      final signed = await client.signTransaction(
        credentials,
        tx,
        chainId: chain.chainId,
      );

      return client.sendRawTransaction(signed);
    });
  }



  /// =========================
  /// nonce（修复）
  /// =========================
  static Future<int> _getSafeNonce(Web3Client client, String address) async {
    return await client.getTransactionCount(
      EthereumAddress.fromHex(address),
      atBlock: const BlockNum.pending(),
    );
  }

  /// =========================
  /// gas limit
  /// =========================
  static Future<BigInt> estimateGas(Web3Client client, {
    required String from,
    required String to,
    required BigInt value,
    String? data,
  }) async {
    try {
      final estimate = await client.estimateGas(
        sender: EthereumAddress.fromHex(from),
        to: EthereumAddress.fromHex(to),
        value: EtherAmount.inWei(value),
        data: data != null ? hexToBytes(data) : null,
      );

      return estimate + BigInt.from(10000);
    } catch (_) {
      if (data != null) return BigInt.from(100000);
      return BigInt.from(21000);
    }
  }

  /// =========================
  /// 交易状态
  /// =========================
  static Future<TransactionReceipt?> waitForTransaction({
    required ChainAccount chain,
    required String txHash,
    int confirmations = 1,
    Duration pollInterval = const Duration(seconds: 5),
  }) async {
    return EvmClientManager.withFallback(
      chain.chainId,
      chain.nodes,
          (client) async {
        TransactionReceipt? receipt;

        while (true) {
          try {
            receipt = await client.getTransactionReceipt(txHash);

            if (receipt != null) {
              final latestBlock = await client.getBlockNumber();

              final txConfirmations =
                  latestBlock - receipt.blockNumber.blockNum + 1;

              if (txConfirmations >= confirmations) {
                return receipt;
              }
            }
          } catch (e) {
            print('waitForTransaction error: $e');
          }

          await Future.delayed(pollInterval);
        }
      },
    );
  }

  /// =========================
  /// 交易详情
  /// =========================
  static Future<TransactionInformation?> getTransactionDetail(
      ChainAccount chain,
      String txHash,) async {
    return EvmClientManager.withFallback(
      chain.chainId,
      chain.nodes,
          (client) async {
        try {
          final tx = await client.getTransactionByHash(txHash);
          return tx;
        } catch (e) {
          print('getTransactionDetail error: $e');
          return null;
        }
      },
    );
  }
}

const String _erc20TransferAbi = '''
[
  {
    "constant": false,
    "inputs": [
      {"name": "_to", "type": "address"},
      {"name": "_value", "type": "uint256"}
    ],
    "name": "transfer",
    "outputs": [{"name": "", "type": "bool"}],
    "type": "function"
  }
]
''';