import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/custom_message_model.dart';
import '../../manager/im_engine_manager.dart';
import '../../store/red_packet_claim_store.dart';

abstract class ImMessage {
  ImMessage({this.destructDuration});

  final int? destructDuration;

  RCIMIWMessageType get type;

  Future<RCIMIWMessage?> toRCMessage();

  void applyMessageOptions(RCIMIWMessage? message) {
    final duration = destructDuration;
    if (message != null && duration != null && duration > 0) {
      message.destructDuration = duration;
    }
  }
}

class CustomMessage extends ImMessage {
  final String targetId;

  final CustomMessageType customMessageType;

  /// 邀请进群时传递的用户 IDs
  final List<String>? userIds;

  RCIMIWConversationType conversationType;

  String? channelId;

  String? content;

  CustomMessage({
    required this.targetId,
    required this.customMessageType,
    this.userIds,
    this.conversationType = RCIMIWConversationType.private,
    this.channelId,
    this.content,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.custom;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final myId = IMEngineManager().currentUserId ?? '';

    final messageID = const Uuid().v4().replaceAll("-", "");

    final model = CustomMessageModel(
      type: customMessageType,
      fromUserId: myId,
      toUserId: targetId,
      content: content,

      /// 新增
      userIds: userIds,
    );

    final msg = await IMEngineManager().engine?.createCustomMessage(
      conversationType,
      targetId,
      channelId,
      model.isNotification
          ? RCIMIWCustomMessagePolicy.storage
          : RCIMIWCustomMessagePolicy.normal,
      messageID,
      model.toJson(),
    );

    msg?.senderUserId = IMEngineManager().currentUserId;

    msg?.sentTime = DateTime.now().millisecondsSinceEpoch;

    return msg;
  }
}

class ForwardCustomMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final RCIMIWCustomMessagePolicy policy;
  final String messageIdentifier;
  final Map fields;

  ForwardCustomMessage({
    required this.conversationType,
    required this.targetId,
    required this.messageIdentifier,
    required this.fields,
    this.channelId,
    this.policy = RCIMIWCustomMessagePolicy.normal,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.custom;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final msg = await IMEngineManager().engine?.createCustomMessage(
      conversationType,
      targetId,
      channelId,
      policy,
      messageIdentifier,
      fields,
    );
    msg?.senderUserId = IMEngineManager().currentUserId;
    msg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    return msg;
  }
}

class TextMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final String content;
  TextMessage({
    required this.conversationType,
    required this.targetId,
    required this.content,
    this.channelId,
    super.destructDuration,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.text;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final textMsg = await IMEngineManager().engine?.createTextMessage(
      conversationType,
      targetId,
      channelId,
      content,
    );
    textMsg?.senderUserId = IMEngineManager().currentUserId;
    textMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    applyMessageOptions(textMsg);
    return textMsg;
  }
}

class ReferenceMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final RCIMIWMessage referenceMessage;
  final String content;

  ReferenceMessage({
    required this.conversationType,
    required this.targetId,
    required this.referenceMessage,
    required this.content,
    this.channelId,
    super.destructDuration,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.reference;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final referenceMsg = await IMEngineManager().engine?.createReferenceMessage(
      conversationType,
      targetId,
      channelId,
      referenceMessage,
      content,
    );
    referenceMsg?.senderUserId = IMEngineManager().currentUserId;
    referenceMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    applyMessageOptions(referenceMsg);
    return referenceMsg;
  }
}

class CombineForwardMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final RCIMIWConversationType originalConversationType;
  final List<String> summaryList;
  final List<String> nameList;
  final List<RCIMIWCombineMsgInfo> msgList;

  CombineForwardMessage({
    required this.conversationType,
    required this.targetId,
    required this.originalConversationType,
    required this.summaryList,
    required this.nameList,
    required this.msgList,
    this.channelId,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.combineV2;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    RCIMIWCombineV2Message? combineMsg;
    try {
      combineMsg = await IMEngineManager().engine?.createCombineV2Message(
        conversationType,
        targetId,
        channelId,
        originalConversationType,
        summaryList,
        nameList,
        msgList,
      );
    } catch (_) {
      return null;
    }
    combineMsg?.senderUserId = IMEngineManager().currentUserId;
    combineMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    return combineMsg;
  }
}

class ImageMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final String path;
  ImageMessage({
    required this.conversationType,
    required this.targetId,
    required this.path,
    this.channelId,
    super.destructDuration,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.image;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final imageMsg = await IMEngineManager().engine?.createImageMessage(
      conversationType,
      targetId,
      channelId,
      path,
    );
    imageMsg?.senderUserId = IMEngineManager().currentUserId;
    imageMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    applyMessageOptions(imageMsg);
    return imageMsg;
  }
}

class VideoMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final String path;
  final int duration;
  final String? remoteUrl;
  final String? coverUrl;
  String thumbnailBase64String;
  VideoMessage({
    required this.conversationType,
    required this.targetId,
    required this.path,
    required this.duration,
    required this.thumbnailBase64String,
    this.remoteUrl,
    this.coverUrl,
    this.channelId,
    super.destructDuration,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.sight;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final videoMsg = await IMEngineManager().engine?.createSightMessage(
      conversationType,
      targetId,
      channelId,
      path,
      duration,
    );
    videoMsg?.thumbnailBase64String = thumbnailBase64String;
    videoMsg?.remote = remoteUrl;
    videoMsg?.senderUserId = IMEngineManager().currentUserId;
    videoMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    applyMessageOptions(videoMsg);
    return videoMsg;
  }
}

class FileMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final String path;
  final int size;
  final String name;
  final String? remoteUrl;
  FileMessage({
    required this.conversationType,
    required this.targetId,
    required this.path,
    required this.size,
    required this.name,
    this.remoteUrl,
    this.channelId,
    super.destructDuration,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.file;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final fileMsg = await IMEngineManager().engine?.createFileMessage(
      conversationType,
      targetId,
      channelId,
      path,
    );
    fileMsg?.remote = remoteUrl;
    fileMsg?.senderUserId = IMEngineManager().currentUserId;
    fileMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    applyMessageOptions(fileMsg);
    return fileMsg;
  }
}

class VoiceMessage extends ImMessage {
  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final String path;
  final String? remoteUrl;
  final int duration;

  VoiceMessage({
    required this.conversationType,
    required this.targetId,
    required this.path,
    required this.duration,
    this.remoteUrl,
    this.channelId,
    super.destructDuration,
  });

  @override
  RCIMIWMessageType get type => RCIMIWMessageType.voice;

  @override
  Future<RCIMIWMessage?> toRCMessage() async {
    final videoMsg = await IMEngineManager().engine?.createVoiceMessage(
      conversationType,
      targetId,
      channelId,
      path,
      duration,
    );
    videoMsg?.remote = remoteUrl;
    videoMsg?.senderUserId = IMEngineManager().currentUserId;
    videoMsg?.sentTime = DateTime.now().millisecondsSinceEpoch;
    applyMessageOptions(videoMsg);
    return videoMsg;
  }
}

class RedPacketMessage extends ImMessage {
  RedPacketMessage({
    required this.conversationType,
    required this.targetId,
    required this.data,
    this.channelId,
    super.destructDuration,
  });

  static const messageIdentifier = 'PARA:RedPacket';
  static const serverMessageIdentifier = 'ZJ:RedPkt';

  final RCIMIWConversationType conversationType;
  final String targetId;
  final String? channelId;
  final RedPacketData data;

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

class RedPacketData {
  const RedPacketData({
    required this.redPacketId,
    this.greeting = '',
    this.amount,
    this.tokenSymbol,
    this.chainId,
    this.packetType,
    this.assetId,
    this.count,
    this.expireTime,
    this.recipientUserId,
    this.isClaimed = false,
  });

  final String redPacketId;
  final String greeting;
  final String? amount;
  final String? tokenSymbol;
  final String? chainId;
  final String? packetType;
  final String? assetId;
  final int? count;
  final int? expireTime;
  final String? recipientUserId;
  final bool isClaimed;

  Map<String, dynamic> toFields({
    required String fromUserId,
    required String toUserId,
  }) {
    return CustomMessageModel(
      type: CustomMessageType.redPacket,
      fromUserId: fromUserId,
      toUserId: toUserId,
      content: greeting,
      redPacketId: redPacketId,
      redPacketAmount: amount,
      redPacketTokenSymbol: tokenSymbol,
      redPacketChainId: chainId,
      redPacketType: packetType,
      redPacketAssetId: assetId,
      redPacketCount: count,
      redPacketExpireTime: expireTime,
      redPacketClaimed: isClaimed,
      userIds: recipientUserId == null || recipientUserId!.isEmpty
          ? null
          : [recipientUserId!],
    ).toJson();
  }

  static RedPacketData? fromFields(Map? fields, {String? claimedUserId}) {
    if (fields == null) return null;

    final normalizedFields = _normalizeFields(fields);
    final model = CustomMessageModel.fromJson(normalizedFields);
    if (model.type != CustomMessageType.redPacket) {
      return null;
    }

    final redPacketId = model.redPacketId?.trim() ?? '';
    final resolvedClaimedUserId = claimedUserId ?? model.toUserId.trim();
    final isClaimed =
        model.redPacketClaimed == true ||
        (redPacketId.isNotEmpty &&
            RedPacketClaimStore.isClaimed(
              redPacketId,
              userId: resolvedClaimedUserId,
            ));

    return RedPacketData(
      redPacketId: redPacketId,
      greeting: model.content?.trim() ?? '',
      amount: model.redPacketAmount?.trim(),
      tokenSymbol: model.redPacketTokenSymbol?.trim(),
      chainId: model.redPacketChainId?.trim(),
      packetType: model.redPacketType?.trim(),
      assetId: model.redPacketAssetId?.trim(),
      count: model.redPacketCount,
      expireTime: model.redPacketExpireTime,
      recipientUserId: model.userIds?.firstOrNull?.trim(),
      isClaimed: isClaimed,
    );
  }

  static RedPacketData? fromMessage(
    RCIMIWMessage message, {
    String? claimedUserId,
  }) {
    if (message is! RCIMIWCustomMessage) return null;
    return fromFields(message.fields, claimedUserId: claimedUserId);
  }

  static Map<String, dynamic> _normalizeFields(Map fields) {
    final source = fields.map((key, value) => MapEntry(key.toString(), value));
    if (source['type'] == 'red_packet') {
      return source;
    }

    final packetNo = source['packetNo'] ?? source['packet_no'];
    if (packetNo == null) {
      return source;
    }

    final sender = source['sender']?.toString() ?? source['fromUserId'] ?? '';
    final recipient = source['to']?.toString() ?? source['toUserId'] ?? '';
    return {
      ...source,
      'type': 'red_packet',
      'fromUserId': sender,
      'toUserId': recipient,
      'content': source['greeting'] ?? source['content'] ?? '',
      'redPacketId': packetNo,
      'redPacketAmount':
          source['display'] ?? source['amount'] ?? source['redPacketAmount'],
      'redPacketTokenSymbol':
          source['symbol'] ??
          source['redPacketTokenSymbol'] ??
          source['tokenSymbol'],
      'redPacketType':
          source['mode'] ?? source['redPacketType'] ?? source['packetType'],
      'redPacketAssetId': source['assetId'] ?? source['asset_id'],
      'redPacketCount': source['count'],
      'redPacketExpireTime': source['expireTime'] ?? source['expire_time'],
      if (source['to'] != null) 'userIds': [source['to'].toString()],
    };
  }
}
