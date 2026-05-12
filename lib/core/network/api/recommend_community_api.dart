
import 'package:paracosm/core/models/community_model.dart';
import 'package:paracosm/core/network/client/http_client.dart';
import '../../../modules/account/manager/account_manager.dart';
import 'api_paths.dart';

class RecommendCommunityApi {
  static Future<List<CommunityModel>> get() async {
    String? token =
        AccountManager().currentAccount?.token;
    final response = await HttpClient().get(
        ApiPaths.recommendCommunity,
        params:{
          'access_token': token,
        }
    );
    if (response == null) {
      return [];
    }
    /// 如果接口直接返回数组
    if (response is List) {
      return response
          .map((e) => CommunityModel.fromJson(e))
          .toList();
    }
    /// 如果接口格式是 { data: [] }
    if (response['data'] is List) {
      return (response['data'] as List)
          .map((e) => CommunityModel.fromJson(e))
          .toList();
    }

    return [];
  }
}