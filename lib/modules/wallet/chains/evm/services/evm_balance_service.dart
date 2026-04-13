import 'package:web3dart/contracts.dart';
import 'package:web3dart/credentials.dart';

import '../../../model/chain_account.dart';
import '../client/evm_client_manager.dart';

class EvmBalanceService {

  /// =========================
  /// 余额
  /// =========================
  static Future<BigInt> getBalance(ChainAccount chain,
      String address,
      {String? contractAddress}) {
    if ((contractAddress ?? '').isNotEmpty) {
      return getTokenBalance(chain, contractAddress!, address);
    }
    return getNativeBalance(chain, address);
  }

  static Future<BigInt> getNativeBalance(ChainAccount chain,
      String address) async {
    return EvmClientManager.withFallback(chain.chainId, chain.nodes, (client) async {
      final balance = await client
          .getBalance(EthereumAddress.fromHex(address))
          .timeout(const Duration(seconds: 8));

      return balance.getInWei;
    });
  }

  static Future<BigInt> getTokenBalance(ChainAccount chain,
      String contractAddress,
      String address,) async {
    return EvmClientManager.withFallback(chain.chainId, chain.nodes, (client) async {
      final contract = DeployedContract(
        ContractAbi.fromJson(_erc20Abi, 'ERC20'),
        EthereumAddress.fromHex(contractAddress),
      );

      final result = await client.call(
        contract: contract,
        function: contract.function('balanceOf'),
        params: [EthereumAddress.fromHex(address)],
      );

      return result.first as BigInt;
    });
  }


}
const String _erc20Abi = '''
[
  {"constant":true,"inputs":[{"name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"type":"function"}
]
''';