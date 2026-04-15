import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:paracosm/modules/wallet/chains/evm/client/evm_client_manager.dart';
import 'package:paracosm/modules/wallet/chains/evm/services/evm_balance_service.dart';
import 'package:paracosm/modules/wallet/chains/evm/services/evm_gas_service.dart';
import 'package:paracosm/modules/wallet/chains/evm/services/evm_sign_service.dart';
import 'package:paracosm/modules/wallet/chains/evm/services/evm_transaction_service.dart';
import 'package:paracosm/modules/wallet/chains/evm/services/evm_typed_data_signer.dart';
import 'package:web3dart/web3dart.dart';

import '../../model/chain_account.dart';
import '../model/gas_fee.dart';

class EvmFacade {
  /// 余额
  static Future<BigInt> getBalance(ChainAccount chain, String address,{String? contractAddress}) {
    return EvmBalanceService.getBalance(chain, address, contractAddress: contractAddress);
  }

  /// 发送交易
  static Future<String> send({
    required ChainAccount chain,
    required String to,
    required BigInt amountWei,
    String? contractAddress,
    GasFee? gasFee,
    String? customData,
  }) {
    return EvmTransactionService.sendTransaction(chain: chain,
        contractAddress: contractAddress, to: to, amountWei: amountWei,
    gasFee: gasFee,customData: customData);
  }

  /// Gas
  static Future<GasLevel> gas(ChainAccount chain) {
    return EvmGasService.getGasLevels(chain);
  }

  /// 签名
  static Future<String> signMessage(String address, String message,{required bool personal}) {
    return EvmSignService.signMessage(address: address, message: message,personal: personal);
  }

  static Future<String> signTypedDataRaw(String address, String jsonData, TypedDataVersion version,{bool personal = false}) {
    return EvmTypedDataSigner.signTypedData(address: address, jsonData: jsonData, version: version);
  }

  /// RPC
  static Future rpc({
    required ChainAccount chain,
    required String method,
    List? params
  }) {
  return EvmClientManager.rpc(chain: chain, method: method,params: params);
  }

  /// block
  static Future<BlockInformation> getBlock(ChainAccount chain,) {
    return EvmClientManager.withFallback(
      chain.chainId,
      chain.nodes,
          (client) => client.getBlockInformation(),
    );
  }
}