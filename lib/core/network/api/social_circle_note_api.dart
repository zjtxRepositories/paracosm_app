

import '../../../modules/account/manager/account_manager.dart';
import '../client/base_client.dart';
import '../models/social_Invitation_model.dart';
import '../models/social_note_publish_model.dart';
import 'api_paths.dart';

class SocialCircleNoteApi {
  static final BaseClient _client =
  BaseClient(ApiPaths.circleUrl);
  static String? get _userId =>
      AccountManager().currentAccount?.userId.toLowerCase();
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

  /// =========================
  /// 列表
  /// =========================
  static Future<List<SocialInvitationModel>> getSocialCircleNoteList(
      String page,
      String size,
      ) async {
    final res = await _client.get("/app/note/list", params: {
      "user_id": _userId,
      "page": page,
      "size": size,
    });

    return _parseList(res["data"]);
  }

  static Future<List<SocialInvitationModel>> getSocialCircleUserNoteList(
      String userId,
      ) async {
    final res = await _client.get("/app/user/note", params: {
      "user_id": userId.toLowerCase(),
    });

    return _parseList(res["data"]);
  }


  static Future<List<String>> getSocialCircleUserFollowList() async {
    final res = await _client.get("/app/user/follow", params: {
      "user_id": _userId,
    });
    if (res["data"] == null) {
      return [];
    } else {
      return (res["data"] as List<dynamic>).cast<String>();
    }
  }

  static Future<SocialInvitationModel?> getSocialCircleNoteInfo(
      String noteId,
      ) async {
    final res = await _client.get("/app/note/info", params: {
      "note_id": noteId,
      "user_id": _userId,
    });

    return _parseOne(res["data"]);
  }

  /// =========================
  /// 写操作（统一 bool）
  /// =========================
  static Future<bool> _postOk(
      String path,
      Map<String, dynamic> data,
      ) async {
    final res = await _client.post(path, data: data);
    return res["code"] == 1;
  }


  static Future<bool> socialCircleNoteDel(String noteId) =>
      _postOk("/app/note/delete", {
        "user_id": _userId,
        "note_id": noteId,
      });

  static Future<bool> socialCircleNoteLikeToggle(
      String noteId,
      bool isLike,
      ) {
    return _postOk(
      isLike ? "/app/note/like" : "/app/note/unlike",
      {
        "user_id": _userId,
        "note_id": noteId,
      },
    );
  }

  static Future<bool> socialCircleNoteCollectToggle(
      String noteId,
      bool isCollect,
      ) {
    return _postOk(
      isCollect ? "/app/note/collect" : "/app/note/uncollect",
      {
        "user_id": _userId,
        "note_id": noteId,
      },
    );
  }

  static Future<bool> socialCircleNoteReview(
      String noteId,
      String toUserId,
      String content,
      String rootId,
      ) =>
      _postOk("/app/note/review", {
        "user_id": _userId,
        "note_id": noteId,
        "to_user_id": toUserId,
        "content": content,
        "root_id": rootId,
      });

  static Future<bool> socialCircleNoteDelreview(
      String noteId,
      String reviewId,
      ) =>
      _postOk("/app/note/delreview", {
        "user_id": _userId,
        "note_id": noteId,
        "review_id": reviewId,
      });

  static Future<bool> socialCircleNoteShare(
      String fromUserId,
      String toUserId,
      String noteId,
      ) =>
      _postOk("/app/note/share", {
        "note_id": noteId,
        "from_user_id": fromUserId,
        "to_user_id": toUserId,
      });

  static Future<bool> socialCircleNoteForward(
      String fromUserId,
      String toUserId,
      String noteId,
      ) =>
      _postOk("/app/note/forward", {
        "note_id": noteId,
        "from_user_id": fromUserId,
        "to_user_id": toUserId,
      });

  static Future<List<SocialInvitationModel>> getSocialCircleNoteDraft() async {
    final res = await _client.get("/app/user/draft", params: {
      "user_id": _userId,
    });

    return _parseList(res["data"]);
  }

  static Future<bool> socialCircleUpdateNoteDraft(SocialNotePublishModel model
     )  =>
      _postOk("/app/user/draft", model.toJson());

  static Future<bool> socialCircleNotePublish(SocialNotePublishModel model
      )  =>
      _postOk("/app/note/publish", model.toJson());

}