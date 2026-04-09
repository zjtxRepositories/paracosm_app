
import 'package:dio/dio.dart';
import 'package:paracosm/core/network/models/dApp_hive.dart';
import '../config/network_config.dart';
import 'api_paths.dart';

class DappListApi {

  static Future<List<DAppHive>> get(int isNew) async {
    Dio dio = Dio(
      BaseOptions(
        baseUrl: NetworkConfig.defaultApiBaseUrl,
      ),
    );
    final res = await dio.get(ApiPaths.dappList,
        queryParameters: {
          'isNew': isNew,
          'channelId': 'ParaCosm',
        }
    );
    final data = res.data["data"];
    final list =  (data as List).map((e) {
      final utxo = DAppHive.fromJson(e);
      return utxo;
    }).toList();
    return list;
  }

}