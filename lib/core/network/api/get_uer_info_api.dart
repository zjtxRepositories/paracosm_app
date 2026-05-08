
import 'package:flutter/cupertino.dart';
import 'package:get/get_connect/http/src/multipart/form_data.dart' as dio hide FormData;
import 'package:paracosm/core/network/client/http_client.dart';
import 'package:paracosm/modules/user/model/user_info.dart';
import '../../../modules/account/manager/account_manager.dart';
import 'api_paths.dart';
import 'package:dio/dio.dart' as dio;

class GetUerInfoApi {

  static Future<UserInfo> get(String userId) async {
    String? token = AccountManager().currentAccount?.token;
    final res = await HttpClient().get<UserInfo>(
        ApiPaths.userInfo,
        params: {
          'access_token': token,
          'userId': userId,
        },
        fromJson: (json) =>  UserInfo.fromJson(json)
    );
    print('res----${res.userId}');
    return res;
  }

  static Future<List<UserInfo>> getList(
      List<String> uids,
      ) async {
    String? token =
        AccountManager().currentAccount?.token;
    final response = await HttpClient().post(
      ApiPaths.userInfoList,
        data: dio.FormData.fromMap({
          'access_token': token,
          'userIdList': uids,
        })
    );
    return (response as List)
        .map<UserInfo>(
          (json) => UserInfo.fromJson(json),
    )
        .toList();
  }
}