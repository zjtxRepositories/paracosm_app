import 'package:dio/dio.dart';
import '../config/network_config.dart';
import 'api_paths.dart';

class ConfigApi {
  static Future<Map<String, dynamic>> getAppConfig() async {
    Dio dio = Dio(
      BaseOptions(
        baseUrl: NetworkConfig.defaultApiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ),
    );

    final res = await dio.get(ApiPaths.config);
    final data = res.data["data"];
    return data;
  }
}
