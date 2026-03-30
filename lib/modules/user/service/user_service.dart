import '../../../core/network/api/login_api.dart';
import '../model/user_info.dart';

class UserService {

  static Future<UserInfo> login(
      String id) async {
    final loginResp = await LoginApi.login(id);

    return loginResp;
  }
}