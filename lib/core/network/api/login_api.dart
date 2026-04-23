
import 'package:paracosm/core/crypto/crypto_util.dart';
import 'package:paracosm/core/network/client/http_client.dart';
import 'package:paracosm/modules/user/model/user_info.dart';
import 'api_paths.dart';

class LoginApi {
  static String key = "%In9AXC0#Z88kd&U";

  static Future<UserInfo> login(String id) async {
    final res = await HttpClient().post<UserInfo>(
      ApiPaths.login,
      params: {
        'telephone': CryptoUtil.aesEncryption(id, key),
        'password': '',
        'appBrand': 'ParaCosm'
      },
      fromJson: (json) => UserInfo.fromJson(json),
    );
    // print('login-------${res.token}--${res.userId}');
    return res;
  }

}