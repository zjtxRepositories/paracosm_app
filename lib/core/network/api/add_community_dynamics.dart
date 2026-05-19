
import 'package:paracosm/core/network/client/http_client.dart';
import '../../../modules/account/manager/account_manager.dart';
import 'api_paths.dart';

class AddCommunityDynamics {
  static Future<bool> add(
      String roomId,
      String content,
      ) async {
    String? token =
        AccountManager().currentAccount?.token;

    final response = await HttpClient().post(
        ApiPaths.addCommunityDynamics,
        params: {
          'access_token': token,
          'roomId': roomId,
          'text':content,
        }
    );
    final data = response["resultCode"];
    if (data != 1){
      return false;
    }
    return true;
  }
}