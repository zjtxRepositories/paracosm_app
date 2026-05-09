
import 'package:paracosm/core/network/client/http_client.dart';
import '../../../modules/account/manager/account_manager.dart';
import 'api_paths.dart';
import 'package:dio/dio.dart' as dio;

class CreateCommunityApi {
  static Future<bool> create(
      String jid,
      String name,
      String desc,
      String avatarUrl,
      int roomType,//群组类型 1DAO 2Club
      int communityType,//社区类型 1token 2nft
      String communityParam,
      ) async {
    String? token =
        AccountManager().currentAccount?.token;
    final response = await HttpClient().post(
        ApiPaths.createCommunity,
        data: dio.FormData.fromMap({
          'access_token': token,
          'jid': jid,
          'name': name,
          'desc': desc,
          'avatarUrl': avatarUrl,
          'roomType': roomType,
          'communityType': communityType,
          'communityParam': communityParam,
        })
    );
    return response != null &&
        response['jid'] != null;
  }
}