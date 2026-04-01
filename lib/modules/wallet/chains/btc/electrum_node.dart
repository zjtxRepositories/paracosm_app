
import 'electrum_node_manager.dart';

Future<String> selectElectrumNode(Map<String, dynamic> params) async {
  final network = params['network'];

  final manager = ElectrumNodeManager();

  return await manager.getNode(
    testnet: network == 'testnet',
  );
}