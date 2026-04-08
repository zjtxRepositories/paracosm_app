import 'dart:async';
import 'package:paracosm/modules/wallet/chains/evm/evm_service.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import '../model/gas_fee.dart';

class EvmChainService {
  static final Map<String, Web3Client> _clients = {};

  static final Map<int, String> _bestRpcCache = {};

  static final Map<int, GasLevel> _gasCache = {};
  static final Map<int, int> _gasCacheTime = {};

  /// =========================
  /// client
  /// =========================
  static Web3Client _getClient(String rpc) {
    return _clients.putIfAbsent(
      rpc,
          () => Web3Client(rpc, Client()),
    );
  }

  static Future<void> dispose() async {
    for (final client in _clients.values) {
      client.dispose();
    }
    _clients.clear();
  }

  /// =========================
  /// RPC容灾
  /// =========================
  static Future<T> _withFallback<T>(
      int chainId,
      List<String> rpcs,
      Future<T> Function(Web3Client client) action,
      ) async {
    final sortedRpcs = {
      if (_bestRpcCache.containsKey(chainId))
        _bestRpcCache[chainId]!,
      ...rpcs,
    }.toList();

    Exception? lastError;

    for (final rpc in sortedRpcs) {
      try {
        final client = _getClient(rpc);
        final result = await action(client);
        _bestRpcCache[chainId] = rpc;
        return result;
      } catch (e) {
        lastError = Exception("RPC失败: $rpc -> $e");
      }
    }

    throw lastError ?? Exception("所有RPC失败");
  }

  /// =========================
  /// 余额
  /// =========================
  static Future<BigInt> getNativeBalance(
      ChainAccount chain,
      String address,
      ) async {
    return _withFallback(
      chain.chainId,
      chain.nodes,
          (client) async {
            final balance = await client
            .getBalance(EthereumAddress.fromHex(address))
            .timeout(const Duration(seconds: 8));

        return balance.getInWei;
      },
    );
  }

  static Future<BigInt> getTokenBalance(
      ChainAccount chain,
      String contractAddress,
      String address,
      ) async {
    return _withFallback(
      chain.chainId,
      chain.nodes,
          (client) async {
        final contract = DeployedContract(
          ContractAbi.fromJson(_erc20Abi, 'ERC20'),
          EthereumAddress.fromHex(contractAddress),
        );

        final function = contract.function('balanceOf');

        final result = await client.call(
          contract: contract,
          function: function,
          params: [EthereumAddress.fromHex(address)],
        );

        return result.first as BigInt;
      },
    );
  }

  static Future<BigInt> getBalance(
      ChainAccount chain,
      String contractAddress,
      String address,
      ) async {
    if (contractAddress.isNotEmpty) {
      return getTokenBalance(chain, contractAddress, address);
    }
    return getNativeBalance(chain, address);
  }

  /// =========================
  /// Gas
  /// =========================
  static Future<GasLevel> getGasLevels(ChainAccount chain) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_gasCache.containsKey(chain.chainId) &&
        now - _gasCacheTime[chain.chainId]! < 10000) {
      return _gasCache[chain.chainId]!;
    }

    try {
      final result = await _withFallback(
        chain.chainId,
        chain.nodes,
            (client) async {
          final block = await client.getBlockInformation();
          final baseFee = block.baseFeePerGas;

          /// 老链
          if (baseFee == null) {
            final gasPrice = await client.getGasPrice();

            return GasLevel(
              slow: GasFee(
                maxFeePerGas: gasPrice.getInWei,
                maxPriorityFeePerGas: BigInt.zero,
                gasPrice: gasPrice.getInWei,
              ),
              medium: GasFee(
                maxFeePerGas:
                gasPrice.getInWei * BigInt.from(12) ~/ BigInt.from(10),
                maxPriorityFeePerGas: BigInt.zero,
                gasPrice:
                gasPrice.getInWei * BigInt.from(12) ~/ BigInt.from(10),
              ),
              fast: GasFee(
                maxFeePerGas:
                gasPrice.getInWei * BigInt.from(15) ~/ BigInt.from(10),
                maxPriorityFeePerGas: BigInt.zero,
                gasPrice:
                gasPrice.getInWei * BigInt.from(15) ~/ BigInt.from(10),
              ),
            );
          }

          /// EIP-1559
          final base = baseFee.getInWei;

          GasFee build(double m, int tipGwei) {
            final priority = BigInt.from(tipGwei) * BigInt.from(1e9.toInt());
            final maxFee =
                (base * BigInt.from((m * 10).toInt()) ~/ BigInt.from(10)) +
                    priority;

            return GasFee(
              maxFeePerGas: maxFee,
              maxPriorityFeePerGas: priority,
            );
          }

          return GasLevel(
            slow: build(1.2, 1),
            medium: build(1.5, 2),
            fast: build(2, 3),
          );
        },
      );

      _gasCache[chain.chainId] = result;
      _gasCacheTime[chain.chainId] = now;

      return result;
    } catch (_) {
      return GasLevel(
        slow: GasFee(
          maxFeePerGas: BigInt.from(20 * 1e9),
          maxPriorityFeePerGas: BigInt.from(1 * 1e9),
        ),
        medium: GasFee(
          maxFeePerGas: BigInt.from(30 * 1e9),
          maxPriorityFeePerGas: BigInt.from(2 * 1e9),
        ),
        fast: GasFee(
          maxFeePerGas: BigInt.from(40 * 1e9),
          maxPriorityFeePerGas: BigInt.from(3 * 1e9),
        ),
      );
    }
  }

  /// =========================
  /// nonce
  /// =========================
  static Future<int> _getNonce(
      Web3Client client,
      String address,
      ) async {
    return client.getTransactionCount(
      EthereumAddress.fromHex(address),
    );
  }

  /// =========================
  /// gas limit
  /// =========================
  static Future<BigInt> _estimateGas(
      Web3Client client, {
        required String from,
        required String to,
        required BigInt value,
        String? data,
      }) async {
    final estimate = await client.estimateGas(
      sender: EthereumAddress.fromHex(from),
      to: EthereumAddress.fromHex(to),
      value: EtherAmount.inWei(value),
      data: data != null ? hexToBytes(data) : null,
    );

    return estimate + BigInt.from(10000);
  }

  /// =========================
  /// 🚀 转账
  /// =========================
  static Future<String> sendTransaction({
    required ChainAccount chain,
    required String contractAddress,
    required String to,
    required BigInt amountWei,
    GasFee? gasFee,
    String? customData,
  })async {
    if (!EvmService.isValidAddress(to)) throw '地址不合法';
    final privateKey = EvmService.getPrivateKeyByAddress(chain.address);
    if (privateKey == null) throw '没有找到该钱包！';

    if (contractAddress.isEmpty){
      return sendNativeTransaction(chain: chain, privateKey: privateKey, to: to, amountWei: amountWei, gasFee: gasFee);
    }
    return sendErc20Transaction(chain: chain, privateKey: privateKey,
        contractAddress: contractAddress, to: to, amount: amountWei, gasFee: gasFee);
  }
  /// =========================
  /// 🚀 原生转账
  /// =========================
  static Future<String> sendNativeTransaction({
    required ChainAccount chain,
    required String privateKey,
    required String to,
    required BigInt amountWei,
    GasFee? gasFee,
  }) async {
    return _withFallback(
      chain.chainId,
      chain.nodes,
          (client) async {
        final credentials = EthPrivateKey.fromHex(privateKey);
        final from = credentials.address;

        final nonce = await _getNonce(client, from.hex);
        final gas = gasFee ?? (await getGasLevels(chain)).medium;

        final gasLimit = await _estimateGas(
          client,
          from: from.hex,
          to: to,
          value: amountWei,
        );

        /// 自动判断 EIP-1559 或 Legacy
        final bool useEip1559 = gas.maxFeePerGas > BigInt.zero &&
            gas.maxPriorityFeePerGas > BigInt.zero;

        /// 如果 priorityFee 为 0，强制设置为 1 Gwei 避免编码失败
        final maxPriorityFee = useEip1559
            ? (gas.maxPriorityFeePerGas > BigInt.zero
            ? gas.maxPriorityFeePerGas
            : BigInt.from(1e9))
            : null;
        //
        // print('--- Transaction Debug ---');
        // print('from: ${from.hex}');
        // print('to: $to');
        // print('value (wei): $amountWei');
        // print('nonce: $nonce');
        // print('gasLimit: $gasLimit');
        // print('useEip1559: $useEip1559');
        // print('gasPrice: ${gas.gasPrice}');
        // print('maxFeePerGas: ${gas.maxFeePerGas}');
        // print('maxPriorityFeePerGas: $maxPriorityFee');
        // print('--------------------------');

        final tx = Transaction(
          from: from,
          to: EthereumAddress.fromHex(to),
          value: EtherAmount.inWei(amountWei),
          nonce: nonce,
          maxGas: gasLimit.toInt(),

          /// 根据判断选择填充字段
          gasPrice: useEip1559 ? null : EtherAmount.inWei(gas.gasPrice!),
          maxFeePerGas:
          useEip1559 ? EtherAmount.inWei(gas.maxFeePerGas) : null,
          maxPriorityFeePerGas:
          useEip1559 ? EtherAmount.inWei(maxPriorityFee!) : null,
        );

        final signed = await client.signTransaction(
          credentials,
          tx,
          chainId: chain.chainId,
        );

        final rawTx = bytesToHex(signed, include0x: true);
        print('sendNativeTransaction：$rawTx');
        return client.sendRawTransaction(signed);
      },
    );
  }

  /// =========================
  /// 🚀 ERC20转账
  /// =========================
  static Future<String> sendErc20Transaction({
    required ChainAccount chain,
    required String privateKey,
    required String contractAddress,
    required String to,
    required BigInt amount,
    GasFee? gasFee,
  }) async {
    return _withFallback(
      chain.chainId,
      chain.nodes,
          (client) async {
        final credentials = EthPrivateKey.fromHex(privateKey);
        final from = credentials.address;

        // ERC20 合约
        final contract = DeployedContract(
          ContractAbi.fromJson(_erc20TransferAbi, 'ERC20'),
          EthereumAddress.fromHex(contractAddress),
        );

        final function = contract.function('transfer');

        final data = Transaction.callContract(
          contract: contract,
          function: function,
          parameters: [
            EthereumAddress.fromHex(to),
            amount,
          ],
        ).data;

        final nonce = await _getNonce(client, from.hex);
        final gas = gasFee ?? (await getGasLevels(chain)).medium;

        final gasLimit = await _estimateGas(
          client,
          from: from.hex,
          to: contractAddress,
          value: BigInt.zero,
          data: bytesToHex(data!, include0x: true),
        );

        /// 自动判断 EIP-1559 或 LegacyTx
        final bool useEip1559 = gas.maxFeePerGas > BigInt.zero &&
            gas.maxPriorityFeePerGas > BigInt.zero;

        final maxPriorityFee = useEip1559
            ? (gas.maxPriorityFeePerGas > BigInt.zero
            ? gas.maxPriorityFeePerGas
            : BigInt.from(1e9)) // 保证 >0
            : null;

        print('--- ERC20 Transaction Debug ---');
        print('from: ${from.hex}');
        print('to: $to');
        print('contract: $contractAddress');
        print('amount: $amount');
        print('nonce: $nonce');
        print('gasLimit: $gasLimit');
        print('useEip1559: $useEip1559');
        print('gasPrice: ${gas.gasPrice}');
        print('maxFeePerGas: ${gas.maxFeePerGas}');
        print('maxPriorityFeePerGas: $maxPriorityFee');
        print('-------------------------------');

        final tx = Transaction(
          from: from,
          to: EthereumAddress.fromHex(contractAddress),
          data: data,
          nonce: nonce,
          maxGas: gasLimit.toInt(),

          /// 根据判断选择填充字段
          gasPrice: useEip1559 ? null : EtherAmount.inWei(gas.gasPrice!),
          maxFeePerGas:
          useEip1559 ? EtherAmount.inWei(gas.maxFeePerGas) : null,
          maxPriorityFeePerGas:
          useEip1559 ? EtherAmount.inWei(maxPriorityFee!) : null,
        );

        final signed = await client.signTransaction(
          credentials,
          tx,
          chainId: chain.chainId,
        );

        final rawTx = bytesToHex(signed, include0x: true);
        print('from-tx--1-=$rawTx');

        try {
          return await client.sendRawTransaction(signed);
        } catch (e) {
          print('❌ ERC20 广播失败: $e');
          rethrow;
        }
      },
    );
  }

  static Future<TransactionInformation?> getTransactionDetail(ChainAccount chain,String txHash) async {
    return _withFallback(
        chain.chainId,
        chain.nodes,
            (client) async {
              final txInfo = await client.getTransactionByHash(txHash);
              print('getTransactionDetail:-----$txHash---${txInfo.toString()}');
              return txInfo;
            }
    );

  }
  static Future<TransactionReceipt?> waitForTransaction(
      {required ChainAccount chain,
        required String txHash,
        int confirmations = 1,
        Duration pollInterval = const Duration(seconds: 5),
      }) async {
    return _withFallback(
        chain.chainId,
        chain.nodes,
            (client) async {
              TransactionReceipt? receipt;
              while (true) {
                receipt = await client.getTransactionReceipt(txHash);
                if (receipt != null) {
                  final latestBlock = await client.getBlockNumber();
                  final txConfirmations = latestBlock - receipt.blockNumber.blockNum + 1;
                  if (txConfirmations >= confirmations) break;
                }
                await Future.delayed(pollInterval);
              }
              return receipt;
        }
    );

  }
  /// =========================
  /// 获取区块信息
  /// =========================
  static Future<BlockInformation?> getBlock(
      ChainAccount chain,
      ) async {
    return _withFallback(
        chain.chainId,
        chain.nodes,
            (client) async {
              try {
                final block = await client.getBlockInformation();
                return block;
              } catch (e) {
                print('getBlock error: $e');
                return null;
              }
        }
    );
  }
}

/// ERC20 ABI
const String _erc20Abi = '''
[
  {"constant":true,"inputs":[{"name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"type":"function"}
]
''';

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
