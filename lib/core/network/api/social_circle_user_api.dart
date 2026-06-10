import '../../../modules/account/manager/account_manager.dart';
import '../../models/social_Invitation_model.dart';
import '../../models/social_wallet_address.dart';
import '../client/friend_circle_base_client.dart';

class SocialCircleUserApi {
  static FriendCircleBaseClient _httpUtil = FriendCircleBaseClient();
  static String? Function() _accountIdProvider = () =>
      AccountManager().currentAccount?.accountId;
  static String? get _userId =>
      SocialWalletAddress.normalize(_accountIdProvider());

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

  static void setClientForTesting(FriendCircleBaseClient client) {
    _httpUtil = client;
  }

  static void resetClientForTesting() {
    _httpUtil = FriendCircleBaseClient();
  }

  static void setAccountIdProviderForTesting(String? Function() provider) {
    _accountIdProvider = provider;
  }

  static void resetAccountIdProviderForTesting() {
    _accountIdProvider = () => AccountManager().currentAccount?.accountId;
  }

  static String? _resolveUserId(String? userId) {
    final value = SocialWalletAddress.normalize(userId);
    if (value.isNotEmpty) return value;
    return _userId;
  }

  /// =========================
  /// GET 列表
  /// =========================
  static Future<List<String>> getSocialCircleUserBlock() async {
    final res = await _httpUtil.get(
      "/app/user/block",
      params: {"user_id": _userId},
    );

    return _parseStringList(res["data"]);
  }

  static Future<List<String>> getSocialCircleUserFollow({
    String? userId,
  }) async {
    final res = await _httpUtil.get(
      "/app/user/follow",
      params: {"user_id": _resolveUserId(userId)},
    );

    return _parseStringList(res["data"]);
  }

  static Future<List<String>> getSocialCircleUserFans({String? userId}) async {
    final res = await _httpUtil.get(
      "/app/user/fans",
      params: {"user_id": _resolveUserId(userId)},
    );

    return _parseStringList(res["data"]);
  }

  static Future<List<SocialInvitationModel>> getSocialCircleUserNote() async {
    final res = await _httpUtil.get(
      "/app/user/note",
      params: {"user_id": _userId},
    );

    return _parseInvitationList(res["data"]);
  }

  /// =========================
  /// follow / unfollow（合并）
  /// =========================
  static Future<bool> socialCircleUserFollowToggle(
    String followWalletAddress,
    bool isFollow,
  ) async {
    final followUserId = SocialWalletAddress.normalize(followWalletAddress);
    if (followUserId.isEmpty) return false;
    final path = isFollow ? "/app/user/follow" : "/app/user/unfollow";

    final res = await _httpUtil.post(
      path: path,
      data: {"user_id": _userId, "follow_user_id": followUserId},
    );
    return _isOk(res);
  }

  /// =========================
  /// block / unblock（合并）
  /// =========================
  static Future<bool> socialCircleUserBlockToggle(
    String blockWalletAddress,
    bool isBlock,
  ) async {
    final blockUserId = SocialWalletAddress.normalize(blockWalletAddress);
    if (blockUserId.isEmpty) return false;
    final path = isBlock ? "/app/user/block" : "/app/user/unblock";

    final res = await _httpUtil.post(
      path: path,
      data: {"user_id": _userId, "block_user_id": blockUserId},
    );

    return _isOk(res);
  }

  /// =========================
  /// report（单一行为）
  /// =========================
  static Future<bool> socialCircleUserReport(
    String walletAddress,
    String reportWalletAddress,
    String content,
  ) async {
    final userId = SocialWalletAddress.normalize(walletAddress);
    final reportUserId = SocialWalletAddress.normalize(reportWalletAddress);
    if (userId.isEmpty || reportUserId.isEmpty) return false;
    final res = await _httpUtil.post(
      path: "/app/user/report",
      data: {
        "user_id": userId,
        "report_user_id": reportUserId,
        "content": content,
      },
    );

    return _isOk(res);
  }
}
