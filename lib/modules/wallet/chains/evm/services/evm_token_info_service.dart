import 'package:paracosm/modules/wallet/model/token_model.dart';
import 'package:web3dart/web3dart.dart';

class EvmTokenInfoService {

  static Future<TokenModel?> getTokenInfo({
    required Web3Client client,
    required String contractAddress,
    required int chainId
  }) async {
    try {
      final address = EthereumAddress.fromHex(contractAddress);

      final contract = DeployedContract(
        ContractAbi.fromJson(erc20Abi, 'ERC20'),
        address,
      );

      final nameFn = contract.function('name');
      final symbolFn = contract.function('symbol');
      final decimalsFn = contract.function('decimals');

      final results = await Future.wait([
        client.call(contract: contract, function: nameFn, params: []),
        client.call(contract: contract, function: symbolFn, params: []),
        client.call(contract: contract, function: decimalsFn, params: []),
      ]);

      return TokenModel(
          name: results[0][0] as String,
          symbol: results[1][0] as String,
          decimals: (results[2][0] as BigInt).toInt(),
          address: contractAddress,
          balance: BigInt.zero,
          logo: '',
          coinId: '',
          chainId: chainId,
          isAdded: true
      );
    } catch (e) {
      return null;
    }
  }

  static const String erc20Abi = '''
[
  {"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"type":"function"},
  {"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"type":"function"},
  {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"},
  {"constant":true,"inputs":[{"name":"account","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"type":"function"}
]
''';

}
