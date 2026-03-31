import 'package:dio/dio.dart';
import 'package:paracosm/modules/wallet/chains/model/coin_market_model.dart';
import '../config/network_config.dart';
import 'api_paths.dart';

class CoinOverviewApi {

  static Future<List<CoinMarketModel>> getCoins() async {
    Dio dio = Dio(
      BaseOptions(
        baseUrl: NetworkConfig.defaultApiBaseUrl,
      ),
    );

    final res = await dio.get(ApiPaths.coinOverview);
    final data = res.data["data"];
    final list =  (data as List).map((e) {
      final utxo = CoinMarketModel.fromJson(e);
      print("GetMarketListApi---${utxo.coinImg}---${utxo.symbol}");
      return utxo;
    }).toList();
    return list;
  }

}