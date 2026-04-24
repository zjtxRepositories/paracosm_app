
import 'package:paracosm/core/network/client/http_client.dart';
import 'package:paracosm/modules/user/model/user_info.dart';
import 'api_paths.dart';

class GetUerInfoApi {

  static Future<UserInfo> get(String userId) async {
    final res = await HttpClient().get<UserInfo>(
        ApiPaths.userInfo,
        params: {
          'access_token': 'd26b93bda491423b81cdb9463bff5342',
          'userId': userId,
        },
        fromJson: (json) =>  UserInfo.fromJson(json)
    );
    print('res----${res.userId}');
    return res;
  }

}