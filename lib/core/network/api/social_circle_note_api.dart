
import 'package:dio/dio.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import '../models/social_Invitation_model.dart';
import 'api_paths.dart';

class SocialCircleNoteApi {
  static Future<List<SocialInvitationModel>> get(String page, String size) async {
    Dio dio = Dio(
      BaseOptions(
        baseUrl: ApiPaths.circleUrl,
      ),
    );
    final userId = AccountManager().currentAccount?.userId;
    final token = AccountManager().currentAccount?.token;
    final res = await dio.get(ApiPaths.noteList,
        queryParameters: {
          "user_id": userId,
          "page": page,
          "size": size
        },
      options: Options(headers: {"token": token}),
    );
    final data = res.data["data"];
    print('res------$data');
    final list =  (data as List).map((e) {
      final item = SocialInvitationModel.fromJson(e);
      return item;
    }).toList();
    return list;
  }

}