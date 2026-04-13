// import 'dart:async';
// import 'dart:convert';
// import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
// import 'package:paracosm/modules/wallet/chains/evm/evm_service.dart';
// import 'package:paracosm/modules/wallet/model/chain_account.dart';
// import 'package:web3dart/crypto.dart';
// import 'package:web3dart/web3dart.dart';
// import 'package:http/http.dart';
// import '../../../../core/util/double_util.dart';
// import '../model/gas_fee.dart';
// import 'dart:typed_data' hide Uint8List;
//
// class EvmChainService {
//   static final Map<String, Web3Client> _clients = {};
//   static final Map<int, String> _bestRpcCache = {};
//   static final Map<int, GasLevel> _gasCache = {};
//   static final Map<int, int> _gasCacheTime = {};
//
//   /// =========================
//   /// client
//   /// =========================
//   static Web3Client getClient(String rpc) {
//     return _clients.putIfAbsent(rpc, () => Web3Client(rpc, Client()));
//   }
//
//   static Future<void> dispose() async {
//     for (final client in _clients.values) {
//       client.dispose();
//     }
//     _clients.clear();
//   }
//
//   /// =========================
//   /// RPC容灾（优化）
//   /// =========================
//   static Future<T> _withFallback<T>(int chainId,
//       List<String> rpcs,
//       Future<T> Function(Web3Client client) action,) async {
//     final sortedRpcs = [
//       if (_bestRpcCache.containsKey(chainId))
//         _bestRpcCache[chainId]!,
//       ...rpcs.where((e) => e != _bestRpcCache[chainId]),
//     ];
//
//     Exception? lastError;
//
//     for (final rpc in sortedRpcs) {
//       try {
//         final client = getClient(rpc);
//         final result = await action(client);
//         _bestRpcCache[chainId] = rpc;
//         return result;
//       } catch (e) {
//         lastError = Exception("RPC失败: $rpc -> $e");
//       }
//     }
//
//     throw lastError ?? Exception("所有RPC失败");
//   }
//
//   static Future<T> withFallback<T>(int chainId,
//       List<String> rpcs,
//       Future<T> Function(Web3Client client) action,) {
//     return _withFallback(chainId, rpcs, action);
//   }
//
//   /// =========================
//   /// 余额
//   /// =========================
//   static Future<BigInt> getNativeBalance(ChainAccount chain,
//       String address) async {
//     return _withFallback(chain.chainId, chain.nodes, (client) async {
//       final balance = await client
//           .getBalance(EthereumAddress.fromHex(address))
//           .timeout(const Duration(seconds: 8));
//
//       return balance.getInWei;
//     });
//   }
//
//   static Future<BigInt> getTokenBalance(ChainAccount chain,
//       String contractAddress,
//       String address,) async {
//     return _withFallback(chain.chainId, chain.nodes, (client) async {
//       final contract = DeployedContract(
//         ContractAbi.fromJson(_erc20Abi, 'ERC20'),
//         EthereumAddress.fromHex(contractAddress),
//       );
//
//       final result = await client.call(
//         contract: contract,
//         function: contract.function('balanceOf'),
//         params: [EthereumAddress.fromHex(address)],
//       );
//
//       return result.first as BigInt;
//     });
//   }
//
//   static Future<BigInt> getBalance(ChainAccount chain,
//       String contractAddress,
//       String address,) {
//     if (contractAddress.isNotEmpty) {
//       return getTokenBalance(chain, contractAddress, address);
//     }
//     return getNativeBalance(chain, address);
//   }
//
//   /// =========================
//   /// Gas
//   /// =========================
//   static Future<GasLevel> getGasLevels(ChainAccount chain) async {
//     final now = DateTime
//         .now()
//         .millisecondsSinceEpoch;
//
//     if (_gasCache.containsKey(chain.chainId) &&
//         now - _gasCacheTime[chain.chainId]! < 10000) {
//       return _gasCache[chain.chainId]!;
//     }
//
//     try {
//       final result =
//       await _withFallback(chain.chainId, chain.nodes, (client) async {
//         final block = await client.getBlockInformation();
//
//         /// legacy链
//         if (block.baseFeePerGas == null) {
//           final gasPrice = await client.getGasPrice();
//
//           final base = gasPrice.getInWei;
//
//           return GasLevel(
//             slow: GasFee(
//               gasPrice: base,
//               maxFeePerGas: base,
//               maxPriorityFeePerGas: BigInt.zero,
//             ),
//             medium: GasFee(
//               gasPrice: base * BigInt.from(12) ~/ BigInt.from(10),
//               maxFeePerGas: base * BigInt.from(12) ~/ BigInt.from(10),
//               maxPriorityFeePerGas: BigInt.zero,
//             ),
//             fast: GasFee(
//               gasPrice: base * BigInt.from(15) ~/ BigInt.from(10),
//               maxFeePerGas: base * BigInt.from(15) ~/ BigInt.from(10),
//               maxPriorityFeePerGas: BigInt.zero,
//             ),
//           );
//         }
//
//         /// EIP-1559
//         final base = block.baseFeePerGas!.getInWei;
//
//         GasFee build(int multiplier, int tipGwei) {
//           final priority =
//               BigInt.from(tipGwei) * BigInt.from(1000000000);
//           final maxFee =
//               (base * BigInt.from(multiplier) ~/ BigInt.from(1)) + priority;
//
//           return GasFee(
//             maxFeePerGas: maxFee,
//             maxPriorityFeePerGas: priority,
//           );
//         }
//
//         return GasLevel(
//           slow: build(12, 1),
//           medium: build(15, 2),
//           fast: build(20, 3),
//         );
//       });
//
//       _gasCache[chain.chainId] = result;
//       _gasCacheTime[chain.chainId] = now;
//
//       return result;
//     } catch (_) {
//       return GasLevel(
//         slow: GasFee(
//           maxFeePerGas: BigInt.from(20000000000),
//           maxPriorityFeePerGas: BigInt.from(1000000000),
//         ),
//         medium: GasFee(
//           maxFeePerGas: BigInt.from(30000000000),
//           maxPriorityFeePerGas: BigInt.from(2000000000),
//         ),
//         fast: GasFee(
//           maxFeePerGas: BigInt.from(40000000000),
//           maxPriorityFeePerGas: BigInt.from(3000000000),
//         ),
//       );
//     }
//   }
//
//   /// =========================
//   /// nonce（修复）
//   /// =========================
//   static Future<int> _getSafeNonce(Web3Client client, String address) async {
//     return await client.getTransactionCount(
//       EthereumAddress.fromHex(address),
//       atBlock: const BlockNum.pending(),
//     );
//   }
//
//   /// =========================
//   /// gas limit
//   /// =========================
//   static Future<BigInt> estimateGas(Web3Client client, {
//     required String from,
//     required String to,
//     required BigInt value,
//     String? data,
//   }) async {
//     try {
//       final estimate = await client.estimateGas(
//         sender: EthereumAddress.fromHex(from),
//         to: EthereumAddress.fromHex(to),
//         value: EtherAmount.inWei(value),
//         data: data != null ? hexToBytes(data) : null,
//       );
//
//       return estimate + BigInt.from(10000);
//     } catch (_) {
//       if (data != null) return BigInt.from(100000);
//       return BigInt.from(21000);
//     }
//   }
//
//   /// =========================
//   /// 🚀 转账入口
//   /// =========================
//   static Future<String> sendTransaction({
//     required ChainAccount chain,
//     required String contractAddress,
//     required String to,
//     required BigInt amountWei,
//     GasFee? gasFee,
//     String? customData,
//   }) async {
//     if (!EvmService.isValidAddress(to)) throw '地址不合法';
//
//     final privateKey =
//     EvmService.getPrivateKeyByAddress(chain.address);
//     if (privateKey == null) throw '没有找到该钱包！';
//
//     if (contractAddress.isEmpty) {
//       return sendNativeTransaction(
//         chain: chain,
//         privateKey: privateKey,
//         to: to,
//         amountWei: amountWei,
//         gasFee: gasFee,
//       );
//     }
//
//     return sendErc20Transaction(
//       chain: chain,
//       privateKey: privateKey,
//       contractAddress: contractAddress,
//       to: to,
//       amount: amountWei,
//       gasFee: gasFee,
//     );
//   }
//
//   /// =========================
//   /// 原生转账
//   /// =========================
//   static Future<String> sendNativeTransaction({
//     required ChainAccount chain,
//     required String privateKey,
//     required String to,
//     required BigInt amountWei,
//     GasFee? gasFee,
//   }) async {
//     return _withFallback(chain.chainId, chain.nodes, (client) async {
//       final credentials = EthPrivateKey.fromHex(privateKey);
//       final from = credentials.address;
//
//       final nonce = await _getSafeNonce(client, from.hex);
//       final gas = gasFee ?? (await getGasLevels(chain)).medium;
//
//       final gasLimit = await estimateGas(
//         client,
//         from: from.hex,
//         to: to,
//         value: amountWei,
//       );
//
//       final latestBlock = await client.getBlockInformation();
//       final supports1559 = latestBlock.baseFeePerGas != null;
//
//       final maxPriorityFee = supports1559
//           ? (gas.maxPriorityFeePerGas > BigInt.zero
//           ? gas.maxPriorityFeePerGas
//           : BigInt.from(1000000000))
//           : null;
//
//       final tx = Transaction(
//         from: from,
//         to: EthereumAddress.fromHex(to),
//         value: EtherAmount.inWei(amountWei),
//         nonce: nonce,
//         maxGas: gasLimit.toInt(),
//         gasPrice:
//         supports1559 ? null : EtherAmount.inWei(gas.gasPrice!),
//         maxFeePerGas: supports1559
//             ? EtherAmount.inWei(gas.maxFeePerGas)
//             : null,
//         maxPriorityFeePerGas: supports1559
//             ? EtherAmount.inWei(maxPriorityFee!)
//             : null,
//       );
//
//       final signed = await client.signTransaction(
//         credentials,
//         tx,
//         chainId: chain.chainId,
//       );
//
//       return client.sendRawTransaction(signed);
//     });
//   }
//
//   /// =========================
//   /// ERC20转账
//   /// =========================
//   static Future<String> sendErc20Transaction({
//     required ChainAccount chain,
//     required String privateKey,
//     required String contractAddress,
//     required String to,
//     required BigInt amount,
//     GasFee? gasFee,
//   }) async {
//     return _withFallback(chain.chainId, chain.nodes, (client) async {
//       final credentials = EthPrivateKey.fromHex(privateKey);
//       final from = credentials.address;
//
//       final contract = DeployedContract(
//         ContractAbi.fromJson(_erc20TransferAbi, 'ERC20'),
//         EthereumAddress.fromHex(contractAddress),
//       );
//
//       final data = Transaction
//           .callContract(
//         contract: contract,
//         function: contract.function('transfer'),
//         parameters: [EthereumAddress.fromHex(to), amount],
//       )
//           .data!;
//
//       final nonce = await _getSafeNonce(client, from.hex);
//       final gas = gasFee ?? (await getGasLevels(chain)).medium;
//
//       final gasLimit = await estimateGas(
//         client,
//         from: from.hex,
//         to: contractAddress,
//         value: BigInt.zero,
//         data: bytesToHex(data, include0x: true),
//       );
//
//       final latestBlock = await client.getBlockInformation();
//       final supports1559 = latestBlock.baseFeePerGas != null;
//
//       final maxPriorityFee = supports1559
//           ? (gas.maxPriorityFeePerGas > BigInt.zero
//           ? gas.maxPriorityFeePerGas
//           : BigInt.from(1000000000))
//           : null;
//
//       final tx = Transaction(
//         from: from,
//         to: EthereumAddress.fromHex(contractAddress),
//         data: data,
//         nonce: nonce,
//         maxGas: gasLimit.toInt(),
//         gasPrice:
//         supports1559 ? null : EtherAmount.inWei(gas.gasPrice!),
//         maxFeePerGas: supports1559
//             ? EtherAmount.inWei(gas.maxFeePerGas)
//             : null,
//         maxPriorityFeePerGas: supports1559
//             ? EtherAmount.inWei(maxPriorityFee!)
//             : null,
//       );
//
//       final signed = await client.signTransaction(
//         credentials,
//         tx,
//         chainId: chain.chainId,
//       );
//
//       return client.sendRawTransaction(signed);
//     });
//   }
//
//   static Future<TransactionInformation?> getTransactionDetail(
//       ChainAccount chain,
//       String txHash,) async {
//     return _withFallback(
//       chain.chainId,
//       chain.nodes,
//           (client) async {
//         try {
//           final tx = await client.getTransactionByHash(txHash);
//           return tx;
//         } catch (e) {
//           print('getTransactionDetail error: $e');
//           return null;
//         }
//       },
//     );
//   }
//
//   static Future<TransactionReceipt?> waitForTransaction({
//     required ChainAccount chain,
//     required String txHash,
//     int confirmations = 1,
//     Duration pollInterval = const Duration(seconds: 5),
//   }) async {
//     return _withFallback(
//       chain.chainId,
//       chain.nodes,
//           (client) async {
//         TransactionReceipt? receipt;
//
//         while (true) {
//           try {
//             receipt = await client.getTransactionReceipt(txHash);
//
//             if (receipt != null) {
//               final latestBlock = await client.getBlockNumber();
//
//               final txConfirmations =
//                   latestBlock - receipt.blockNumber.blockNum + 1;
//
//               if (txConfirmations >= confirmations) {
//                 return receipt;
//               }
//             }
//           } catch (e) {
//             print('waitForTransaction error: $e');
//           }
//
//           await Future.delayed(pollInterval);
//         }
//       },
//     );
//   }
//
//   static Future<BlockInformation?> getBlock(ChainAccount chain,) async {
//     return _withFallback(
//       chain.chainId,
//       chain.nodes,
//           (client) async {
//         try {
//           final block = await client.getBlockInformation();
//           return block;
//         } catch (e) {
//           print('getBlock error: $e');
//           return null;
//         }
//       },
//     );
//   }
//
//   /// =========================
//   /// RPC
//   /// =========================
//   static Future<dynamic> rpc({
//     required ChainAccount chain,
//     required String method,
//     List? params,
//   }) async {
//     return _withFallback(
//       chain.chainId,
//       chain.nodes,
//           (client) => client.makeRPCCall(method, params ?? []),
//     );
//   }
//
//   /// =========================
//   /// signMessage
//   /// =========================
//   static Future<String> signMessage({
//     required String address,
//     required String message,
//   }) async {
//     final privateKey = EvmService.getPrivateKeyByAddress(address);
//     if (privateKey == null) throw Exception("找不到该钱包");
//     final credentials = EthPrivateKey.fromHex(privateKey);
//
//     /// 1️⃣ 统一 bytes（⭐关键：全部转 List<int>）
//     final List<int> messageBytes = message.startsWith('0x')
//         ? hexToBytes(message).toList()
//         : utf8.encode(message);
//
//     /// 2️⃣ 转 Uint8List（只做一次）
//     final Uint8List data = Uint8List.fromList(messageBytes);
//
//     /// 3️⃣ 使用 web3dart 官方方法
//     final signature = credentials.signPersonalMessageToUint8List(fix(data));
//
//     /// 4️⃣ 转 hex
//     return bytesToHex(signature, include0x: true);
//   }
//
//   /// =========================
//   /// EIP-712 签名（eth_signTypedData_v4）
//   /// =========================
//   static Future<String> signTypedData({
//     required String address,
//     required Map<String, dynamic> typedData,
//   }) async {
//     final privateKey = EvmService.getPrivateKeyByAddress(address);
//     if (privateKey == null) throw Exception("找不到该钱包");
//     final pk = hexToBytes(privateKey);
//
//     /// 1️⃣ 解析 typedData
//     final domain = typedData['domain'];
//     final types = Map<String, dynamic>.from(typedData['types']);
//     final primaryType = typedData['primaryType'];
//     final message = typedData['message'];
//
//     /// 2️⃣ 移除 EIP712Domain（标准要求）
//     types.remove('EIP712Domain');
//
//     /// 3️⃣ domain separator
//     final domainSeparator = _hashStruct(
//       'EIP712Domain',
//       domain,
//       typedData['types'],
//     );
//
//     /// 4️⃣ message hash
//     final messageHash = _hashStruct(
//       primaryType,
//       message,
//       types,
//     );
//
//     /// 5️⃣ EIP-712 最终 hash
//     final data = [
//       0x19,
//       0x01,
//       ...domainSeparator,
//       ...messageHash,
//     ];
//     final hash = keccak256(fix(data));
//
//     /// 6️⃣ 签名
//     final sig = sign(hash, pk);
//
//     final bytes = [
//       ..._bigIntToBytes(sig.r).padLeft(32, 0),
//       ..._bigIntToBytes(sig.s).padLeft(32, 0),
//       sig.v,
//     ];
//
//     return bytesToHex(bytes, include0x: true);
//   }
//
//   static List<int> _hashStruct(
//       String primaryType,
//       Map<String, dynamic> data,
//       Map<String, dynamic> types,
//       ) {
//     final encoded = _encodeData(primaryType, data, types);
//     return keccak256(encoded);
//   }
//
//   static List<int> _encodeData(
//       String primaryType,
//       Map<String, dynamic> data,
//       Map<String, dynamic> types,
//       ) {
//     final fields = types[primaryType] as List;
//
//     List<int> enc = [];
//
//     /// typeHash
//     enc.addAll(keccak256(utf8.encode(_encodeType(primaryType, types))));
//
//     for (final field in fields) {
//       final name = field['name'];
//       final type = field['type'];
//       final value = data[name];
//
//       enc.addAll(_encodeValue(type, value, types));
//     }
//
//     return enc;
//   }
//
//   static String _encodeType(
//       String primaryType,
//       Map<String, dynamic> types,
//       ) {
//     final deps = _findDependencies(primaryType, types);
//     deps.remove(primaryType);
//     deps.sort();
//
//     final result = StringBuffer();
//
//     result.write(_typeToString(primaryType, types));
//
//     for (final dep in deps) {
//       result.write(_typeToString(dep, types));
//     }
//
//     return result.toString();
//   }
//
//   static String _typeToString(
//       String type,
//       Map<String, dynamic> types,
//       ) {
//     final fields = types[type] as List;
//
//     return '$type(${fields.map((f) => '${f['type']} ${f['name']}').join(',')})';
//   }
//
//   static List<int> _encodeValue(
//       String type,
//       dynamic value,
//       Map<String, dynamic> types,
//       ) {
//     if (types.containsKey(type)) {
//       return _hashStruct(type, value, types);
//     }
//
//     if (type == 'string') {
//       return keccak256(utf8.encode(value));
//     }
//
//     if (type == 'bytes') {
//       return keccak256(hexToBytes(value));
//     }
//
//     if (type == 'address') {
//       return _padLeft(hexToBytes(value), 32);
//     }
//
//     if (type.startsWith('uint') || type.startsWith('int')) {
//       final v = BigInt.parse(value.toString());
//       return _padLeft(_bigIntToBytes(v), 32);
//     }
//
//     if (type == 'bool') {
//       return _padLeft([value ? 1 : 0], 32);
//     }
//
//     throw Exception('Unsupported type: $type');
//   }
//   static List<int> _padLeft(List<int> data, int length) {
//     return List<int>.filled(length - data.length, 0) + data;
//   }
//
//   static List<int> _bigIntToBytes(BigInt number) {
//     final bytes = <int>[];
//     var temp = number;
//
//     while (temp > BigInt.zero) {
//       bytes.insert(0, (temp & BigInt.from(0xff)).toInt());
//       temp = temp >> 8;
//     }
//
//     return bytes.isEmpty ? [0] : bytes;
//   }
//
//   static Set<String> _findDependencies(
//       String primaryType,
//       Map<String, dynamic> types,
//       Set<String>? results,
//       ) {
//     results ??= {};
//
//     if (results.contains(primaryType)) return results;
//
//     results.add(primaryType);
//
//     if (!types.containsKey(primaryType)) return results;
//
//     for (final field in types[primaryType]) {
//       final type = field['type'];
//
//       if (types.containsKey(type)) {
//         _findDependencies(type, types, results);
//       }
//     }
//
//     return results;
//   }
// }
//
// const String _erc20Abi = '''
// [
//   {"constant":true,"inputs":[{"name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"type":"function"}
// ]
// ''';
//
// const String _erc20TransferAbi = '''
// [
//   {
//     "constant": false,
//     "inputs": [
//       {"name": "_to", "type": "address"},
//       {"name": "_value", "type": "uint256"}
//     ],
//     "name": "transfer",
//     "outputs": [{"name": "", "type": "bool"}],
//     "type": "function"
//   }
// ]
// ''';