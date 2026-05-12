
import 'package:paracosm/core/models/community_model.dart';
import 'package:paracosm/core/network/client/http_client.dart';
import '../../../modules/account/manager/account_manager.dart';
import 'api_paths.dart';

class CommunityDynamicsApi {
  static Future<CommunityPostPageModel?> get({
    required String roomId,
    int pageIndex = 0,
    int pageSize = 20,
  }) async {
    final token =
        AccountManager().currentAccount?.token;

    final response = await HttpClient().get(
      ApiPaths.communityDynamics,
      params: {
        'access_token': token,
        'pageIndex': pageIndex,
        'pageSize': pageSize,
        'roomId': roomId,
      },
    );

    if (response == null) {
      return null;
    }

    return CommunityPostPageModel.fromJson(response);
  }
}