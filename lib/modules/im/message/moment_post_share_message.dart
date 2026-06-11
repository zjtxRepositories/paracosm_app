import 'package:paracosm/core/models/custom_message_model.dart';
import 'package:paracosm/core/models/social_Invitation_model.dart';
import 'package:paracosm/core/models/social_media_model.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/modules/im/message/base/im_message.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class MomentPostShareData {
  const MomentPostShareData({
    required this.noteId,
    required this.postContent,
    required this.postCover,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    this.mediaType,
  });

  final String noteId;
  final String postContent;
  final String postCover;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final int? mediaType;

  bool get isValid => noteId.trim().isNotEmpty;

  Map<String, dynamic> toFields({
    required String fromUserId,
    required String toUserId,
  }) {
    return CustomMessageModel(
      type: CustomMessageType.momentPost,
      fromUserId: fromUserId,
      toUserId: toUserId,
      content: postContent,
      noteId: noteId,
      postContent: postContent,
      postCover: postCover,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      mediaType: mediaType,
    ).toJson();
  }

  static MomentPostShareData fromPost(SocialInvitationModel post) {
    final firstMedia = post.media.firstOrNull;
    return MomentPostShareData(
      noteId: post.noteId,
      postContent: summaryFromContent(post.content),
      postCover: firstMedia?.previewUrl ?? '',
      authorId: post.userId,
      authorName: post.userInfoModel?.nickname ?? '',
      authorAvatar: post.userInfoModel?.avatar ?? '',
      mediaType: firstMedia?.type,
    );
  }

  static MomentPostShareData? fromFields(Map? fields) {
    if (fields == null) return null;
    final model = CustomMessageModel.fromJson(
      fields.map((key, value) => MapEntry(key.toString(), value)),
    );
    if (model.type != CustomMessageType.momentPost) return null;
    final noteId = model.noteId?.trim() ?? '';
    if (noteId.isEmpty) return null;
    return MomentPostShareData(
      noteId: noteId,
      postContent: model.postContent?.trim().isNotEmpty == true
          ? model.postContent!.trim()
          : (model.content ?? '').trim(),
      postCover: model.postCover?.trim() ?? '',
      authorId: model.authorId?.trim() ?? model.fromUserId,
      authorName: model.authorName?.trim() ?? '',
      authorAvatar: model.authorAvatar?.trim() ?? '',
      mediaType: model.mediaType,
    );
  }

  static MomentPostShareData? fromMessage(RCIMIWMessage message) {
    if (message is! RCIMIWCustomMessage) return null;
    return fromFields(message.fields);
  }

  static String summaryFromContent(String content) {
    final compact = content.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (compact.length <= 80) return compact;
    return '${compact.substring(0, 80)}...';
  }
}

class MomentPostShareMessage extends ImMessage {
  MomentPostShareMessage({
    required this.conversationType,
    required this.targetId,
    required this.data,
    this.channelId,
    super.destructDuration,
  });

  static const messageIdentifier = 'PARA:MomentPost';

  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final MomentPostShareData data;

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.custom;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final currentUserId = IMEngineManager().currentUserId ?? '';
    final msg = await IMEngineManager().engine?.createCustomMessage(
      conversationType,
      targetId,
      channelId,
      RCIMIWCustomMessagePolicy.normal,
      messageIdentifier,
      data.toFields(fromUserId: currentUserId, toUserId: targetId),
    );

    msg?.senderUserId = currentUserId;
    msg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    applyMessageOptions(msg);
    return msg;
  }
}
