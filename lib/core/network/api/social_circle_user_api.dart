
import '../../../modules/account/manager/account_manager.dart';
import '../client/base_client.dart';
import '../models/social_Invitation_model.dart';
import 'api_paths.dart';

class SocialCircleUserApi {
  static final BaseClient _httpUtil =
  BaseClient(ApiPaths.circleUrl);
  static String? get _userId =>
      AccountManager().currentAccount?.userId.toLowerCase();

  /// =========================
  /// 通用解析
  /// =========================
  static List<String> _parseStringList(dynamic data) {
    if (data is! List) return [];
    return data.cast<String>();
  }

  static List<SocialInvitationModel> _parseInvitationList(dynamic data) {
    if (data is! List) return [];
    return data.map((e) => SocialInvitationModel.fromJson(e)).toList();
  }

  static bool _isOk(dynamic res) => res?["code"] == 1;

  /// =========================
  /// GET 列表
  /// =========================
  static Future<List<String>> getSocialCircleUserBlock(String userId) async {
    final res = await _httpUtil.get(
      "/app/user/block",
      params: {"user_id": userId},
    );

    return _parseStringList(res.data["data"]);
  }

  static Future<List<String>> getSocialCircleUserFollow(String userId) async {
    final res = await _httpUtil.get(
      "/app/user/follow",
      params: {"user_id": userId},
    );

    return _parseStringList(res.data["data"]);
  }

  static Future<List<String>> getSocialCircleUserFans(String userId) async {
    final res = await _httpUtil.get(
      "/app/user/fans",
      params: {"user_id": userId},
    );

    return _parseStringList(res.data["data"]);
  }

  static Future<List<SocialInvitationModel>> getSocialCircleUserNote() async {
    final res = await _httpUtil.get(
      "/app/user/note",
      params: {
        "user_id": _userId,
      },
    );

    return _parseInvitationList(res.data["data"]);
  }

  /// =========================
  /// follow / unfollow（合并）
  /// =========================
  static Future<bool> socialCircleUserFollowToggle(
      String followUserId,
      bool isFollow,
      ) async {
    final path = isFollow
        ? "/app/user/follow"
        : "/app/user/unfollow";

    final res = await _httpUtil.post(
      path,
      data: {
        "user_id": _userId,
        "follow_user_id": followUserId,
      },
    );
    return _isOk(res);
  }

  /// =========================
  /// block / unblock（合并）
  /// =========================
  static Future<bool> socialCircleUserBlockToggle(
      String userId,
      String blockUserId,
      bool isBlock,
      ) async {
    final path = isBlock
        ? "/app/user/block"
        : "/app/user/unblock";

    final res = await _httpUtil.post(
      path,
      data: {
        "user_id": userId,
        "block_user_id": blockUserId,
      },
    );

    return _isOk(res.data);
  }

  /// =========================
  /// report（单一行为）
  /// =========================
  static Future<bool> socialCircleUserReport(
      String userId,
      String reportUserId,
      String content,
      ) async {
    final res = await _httpUtil.post(
      "/app/user/report",
      data: {
        "user_id": userId,
        "report_user_id": reportUserId,
        "content": content,
      },
    );

    return _isOk(res.data);
  }
}