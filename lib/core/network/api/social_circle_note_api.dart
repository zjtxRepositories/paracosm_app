import '../../../modules/account/manager/account_manager.dart';
import '../../models/social_Invitation_model.dart';
import '../../models/social_wallet_address.dart';
import '../client/friend_circle_base_client.dart';
import '../../models/social_note_publish_model.dart';

class SocialCircleNoteApi {
  static FriendCircleBaseClient _client = FriendCircleBaseClient();
  static String? Function() _accountIdProvider = () =>
      AccountManager().currentAccount?.accountId;
  static String? get _userId =>
      SocialWalletAddress.normalize(_accountIdProvider());
  static String get _currentUserId =>
      SocialWalletAddress.normalize(_accountIdProvider());

  /// =========================
  /// 通用解析工具
  /// =========================
  static List<SocialInvitationModel> _parseList(dynamic data) {
    if (data is! List) return [];
    return data.map((e) => SocialInvitationModel.fromJson(e)).toList();
  }

  static SocialInvitationModel? _parseOne(dynamic data) {
    if (data == null) return null;
    return SocialInvitationModel.fromJson(data);
  }

  static void setClientForTesting(FriendCircleBaseClient client) {
    _client = client;
  }

  static void resetClientForTesting() {
    _client = FriendCircleBaseClient();
  }

  static void setAccountIdProviderForTesting(String? Function() provider) {
    _accountIdProvider = provider;
  }

  static void resetAccountIdProviderForTesting() {
    _accountIdProvider = () => AccountManager().currentAccount?.accountId;
  }

  /// =========================
  /// 列表
  /// =========================
  static Future<List<SocialInvitationModel>> getSocialCircleNoteList(
    String page,
    String size,
  ) async {
    final res = await _client.get(
      "/app/note/list",
      params: {"user_id": _userId, "page": page, "size": size},
    );

    return _parseList(res["data"]);
  }

  static Future<List<SocialInvitationModel>> getSocialCircleUserNoteList(
    String walletAddress,
  ) async {
    final userId = SocialWalletAddress.normalize(walletAddress);
    if (userId.isEmpty) return [];
    final currentUserId = _currentUserId;
    final params = <String, dynamic>{"user_id": userId};
    if (currentUserId.isNotEmpty) {
      params["viewer_user_id"] = currentUserId;
    }
    final res = await _client.get("/app/user/note", params: params);

    return _parseList(res["data"]);
  }

  static Future<List<String>> getSocialCircleUserFollowList() async {
    final res = await _client.get(
      "/app/user/follow",
      params: {"user_id": _userId},
    );
    if (res["data"] == null) {
      return [];
    } else {
      return (res["data"] as List<dynamic>).cast<String>();
    }
  }

  static Future<SocialInvitationModel?> getSocialCircleNoteInfo(
    String noteId,
  ) async {
    final res = await _client.get(
      "/app/note/info",
      params: {"note_id": noteId, "user_id": _userId},
    );

    return _parseOne(res["data"]);
  }

  /// =========================
  /// 写操作（统一 bool）
  /// =========================
  static Future<bool> _postOk(String path, Map<String, dynamic> data) async {
    final res = await _client.post(path: path, data: data);
    return res["code"] == 1;
  }

  static Future<bool> socialCircleNoteDel(String noteId) =>
      _postOk("/app/note/delete", {"user_id": _userId, "note_id": noteId});

  static Future<bool> socialCircleNoteLikeToggle(String noteId, bool isLike) {
    return _postOk(isLike ? "/app/note/like" : "/app/note/unlike", {
      "user_id": _userId,
      "note_id": noteId,
    });
  }

  static Future<bool> socialCircleNoteCollectToggle(
    String noteId,
    bool isCollect,
  ) {
    return _postOk(isCollect ? "/app/note/collect" : "/app/note/uncollect", {
      "user_id": _userId,
      "note_id": noteId,
    });
  }

  static Future<bool> socialCircleNoteReview(
    String noteId,
    String toWalletAddress,
    String content,
    String rootId,
  ) {
    final toUserId = SocialWalletAddress.normalize(toWalletAddress);
    if (toUserId.isEmpty) return Future.value(false);
    return _postOk("/app/note/review", {
      "user_id": _userId,
      "note_id": noteId,
      "to_user_id": toUserId,
      "content": content,
      "root_id": rootId,
    });
  }

  static Future<bool> socialCircleNoteDelreview(
    String noteId,
    String reviewId,
  ) => _postOk("/app/note/delreview", {
    "user_id": _userId,
    "note_id": noteId,
    "review_id": reviewId,
  });

  static Future<bool> socialCircleNoteShare(
    String fromWalletAddress,
    String toWalletAddress,
    String noteId,
  ) {
    final fromUserId = SocialWalletAddress.normalize(fromWalletAddress);
    final toUserId = SocialWalletAddress.normalize(toWalletAddress);
    if (fromUserId.isEmpty || toUserId.isEmpty) return Future.value(false);
    return _postOk("/app/note/share", {
      "note_id": noteId,
      "from_user_id": fromUserId,
      "to_user_id": toUserId,
    });
  }

  static Future<bool> socialCircleNoteForward(
    String fromWalletAddress,
    String toWalletAddress,
    String noteId,
  ) {
    final fromUserId = SocialWalletAddress.normalize(fromWalletAddress);
    final toUserId = SocialWalletAddress.normalize(toWalletAddress);
    if (fromUserId.isEmpty || toUserId.isEmpty) return Future.value(false);
    return _postOk("/app/note/forward", {
      "note_id": noteId,
      "from_user_id": fromUserId,
      "to_user_id": toUserId,
    });
  }

  static Future<List<SocialInvitationModel>> getSocialCircleNoteDraft() async {
    final res = await _client.get(
      "/app/user/draft",
      params: {"user_id": _userId},
    );

    return _parseList(res["data"]);
  }

  static Future<bool> socialCircleUpdateNoteDraft(
    SocialNotePublishModel model,
  ) => _postOk("/app/user/draft", model.toJson());

  static Future<bool> socialCircleNotePublish(SocialNotePublishModel model) =>
      _postOk("/app/note/publish", model.toJson());
}
