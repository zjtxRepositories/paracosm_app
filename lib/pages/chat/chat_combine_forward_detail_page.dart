import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/call/rong_call_summary_parser.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:paracosm/pages/chat/chat_detail_message_mapper.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/chat_message_contents.dart';
import 'package:paracosm/widgets/chat/chat_message_item.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class ChatCombineForwardDetailPage extends StatefulWidget {
  const ChatCombineForwardDetailPage({super.key, required this.message});

  final RCIMIWCombineV2Message? message;

  @override
  State<ChatCombineForwardDetailPage> createState() =>
      _ChatCombineForwardDetailPageState();
}

class _ChatCombineForwardDetailPageState
    extends State<ChatCombineForwardDetailPage> {
  late Future<List<ChatDetailMessage>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _loadMessages(widget.message);
  }

  @override
  void didUpdateWidget(covariant ChatCombineForwardDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _messagesFuture = _loadMessages(widget.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '聊天记录',
      isAddBottomMargin: false,
      backgroundColor: AppColors.grey100,
      child: FutureBuilder<List<ChatDetailMessage>>(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data ?? const <ChatDetailMessage>[];
          if (messages.isEmpty) {
            return const AppEmptyView(text: '暂无聊天记录');
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return KeyedSubtree(
                key: ValueKey('${index}_${message.messageId}'),
                child: _buildMessageNode(message),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<ChatDetailMessage>> _loadMessages(
    RCIMIWCombineV2Message? combineMessage,
  ) async {
    final msgList = combineMessage?.msgList;
    if (msgList == null || msgList.isEmpty) {
      return const <ChatDetailMessage>[];
    }

    final rawMessages = <RCIMIWMessage>[];
    for (var i = 0; i < msgList.length; i++) {
      rawMessages.add(_messageFromCombineInfo(msgList[i], i));
    }

    return ChatDetailMessageMapper.mapMessages(rawMessages);
  }

  RCIMIWMessage _messageFromCombineInfo(RCIMIWCombineMsgInfo info, int index) {
    final content = _contentMap(info.content);
    if (content == null) {
      return _unknownMessage(info, index, null);
    }

    final json = Map<String, dynamic>.from(content);
    _fillMissingMessageFields(json, info, index);

    try {
      return _messageFromJson(json) ?? _unknownMessage(info, index, json);
    } catch (_) {
      return _unknownMessage(info, index, json);
    }
  }

  Map<String, dynamic>? _contentMap(Map? content) {
    if (content == null) {
      return null;
    }

    try {
      return content.map((key, value) => MapEntry(key.toString(), value));
    } catch (_) {
      return null;
    }
  }

  void _fillMissingMessageFields(
    Map<String, dynamic> json,
    RCIMIWCombineMsgInfo info,
    int index,
  ) {
    json['senderUserId'] ??= info.fromUserId;
    json['targetId'] ??= info.targetId;
    json['sentTime'] ??= info.timestamp;
    json['receivedTime'] ??= info.timestamp;
    json['messageUId'] ??= 'combine:$index:${info.timestamp ?? ''}';

    final objectName = info.objectName ?? json['objectName']?.toString();
    json['objectName'] ??= objectName;

    var messageType =
        _readMessageType(json['messageType']) ??
        _messageTypeForObjectName(objectName);
    messageType ??= _messageTypeForReadableContent(json);
    if (messageType != null) {
      json['messageType'] = messageType.index;
    }

    _normalizePayloadFields(
      json,
      objectName: objectName,
      messageType: messageType,
    );

    if (objectName == RongCallSummaryParser.objectName) {
      json['messageType'] ??= RCIMIWMessageType.unknown.index;
      json['rawData'] ??= _safeJsonEncode(
        json['fields'] ?? json['content'] ?? Map<String, dynamic>.from(json),
      );
    }
  }

  void _normalizePayloadFields(
    Map<String, dynamic> json, {
    required String? objectName,
    required RCIMIWMessageType? messageType,
  }) {
    switch (messageType) {
      case RCIMIWMessageType.text:
        _normalizeTextPayload(json);
      case RCIMIWMessageType.reference:
        _normalizeReferencePayload(json);
      case RCIMIWMessageType.image:
        _normalizeImagePayload(json);
      case RCIMIWMessageType.voice:
        _normalizeVoicePayload(json);
      case RCIMIWMessageType.sight:
        _normalizeSightPayload(json);
      case RCIMIWMessageType.file:
        _normalizeFilePayload(json);
      case RCIMIWMessageType.custom:
        _normalizeCustomPayload(json, objectName: objectName);
      case RCIMIWMessageType.nativeCustom:
      case RCIMIWMessageType.unknown:
      case RCIMIWMessageType.userCustom:
        _normalizeNativeCustomPayload(json, objectName: objectName);
      default:
        break;
    }
  }

  void _normalizeTextPayload(Map<String, dynamic> json) {
    _assignIfEmpty(json, 'text', _stringValue(json['content']));
  }

  void _normalizeReferencePayload(Map<String, dynamic> json) {
    _assignIfEmpty(json, 'text', _stringValue(json['content']));

    final referenceMessage = _normalizeReferenceMessageJson(
      json['referenceMessage'],
    );
    if (referenceMessage != null) {
      json['referenceMessage'] = referenceMessage;
      return;
    }

    final referMsg = _mapValue(json['referMsg']);
    if (referMsg == null) {
      return;
    }

    final referenced = _normalizeReferenceMessageJson(
      referMsg['content'],
      objectName: referMsg['objectName']?.toString(),
      senderUserId: referMsg['senderId']?.toString(),
      messageUId: referMsg['messageUId']?.toString(),
    );

    if (referenced != null) {
      json['referenceMessage'] = referenced;
    }
  }

  Map<String, dynamic>? _normalizeReferenceMessageJson(
    Object? value, {
    String? objectName,
    String? senderUserId,
    String? messageUId,
  }) {
    final messageJson = _messageContentMap(value);
    if (messageJson == null) {
      return null;
    }

    final refObjectName = objectName ?? messageJson['objectName']?.toString();
    messageJson['objectName'] ??= refObjectName;
    messageJson['senderUserId'] ??= senderUserId;
    messageJson['messageUId'] ??= messageUId;

    var messageType =
        _readMessageType(messageJson['messageType']) ??
        _messageTypeForObjectName(refObjectName);
    messageType ??= _messageTypeForReadableContent(messageJson);
    messageType ??= RCIMIWMessageType.unknown;
    messageJson['messageType'] = messageType.index;

    _normalizePayloadFields(
      messageJson,
      objectName: refObjectName,
      messageType: messageType,
    );

    return messageJson;
  }

  void _normalizeImagePayload(Map<String, dynamic> json) {
    _assignIfEmpty(
      json,
      'thumbnailBase64String',
      _stringValue(json['content']),
    );
    _assignIfEmpty(
      json,
      'remote',
      _firstString(json, const ['imageUri', 'remoteUrl', 'url', 'mediaUrl']),
    );
    _assignIfEmpty(
      json,
      'local',
      _firstString(json, const ['localPath', 'path', 'filePath']),
    );
  }

  void _normalizeVoicePayload(Map<String, dynamic> json) {
    _assignIfEmpty(
      json,
      'remote',
      _firstString(json, const ['remoteUrl', 'uri', 'url', 'voiceUrl']),
    );
    _assignIfEmpty(
      json,
      'local',
      _firstString(json, const ['localPath', 'path', 'filePath']),
    );
    final duration = _readInt(json['duration']);
    if (duration != null) {
      json['duration'] = duration;
    }
  }

  void _normalizeSightPayload(Map<String, dynamic> json) {
    _assignIfEmpty(
      json,
      'thumbnailBase64String',
      _stringValue(json['content']),
    );
    _assignIfEmpty(
      json,
      'remote',
      _firstString(json, const ['sightUrl', 'remoteUrl', 'url', 'mediaUrl']),
    );
    _assignIfEmpty(
      json,
      'local',
      _firstString(json, const ['localPath', 'path', 'filePath']),
    );
    final duration = _readInt(json['duration']);
    if (duration != null) {
      json['duration'] = duration;
    }
  }

  void _normalizeFilePayload(Map<String, dynamic> json) {
    _assignIfEmpty(json, 'name', _firstString(json, const ['fileName']));
    _assignIfEmpty(
      json,
      'remote',
      _firstString(json, const ['fileUrl', 'remoteUrl', 'url']),
    );
    _assignIfEmpty(
      json,
      'local',
      _firstString(json, const ['localPath', 'path', 'filePath']),
    );
    final size = _readInt(json['size']);
    if (size != null) {
      json['size'] = size;
    }
  }

  void _normalizeCustomPayload(
    Map<String, dynamic> json, {
    required String? objectName,
  }) {
    _assignIfEmpty(json, 'identifier', objectName);
    json['fields'] ??= _customFields(json['content']);
  }

  void _normalizeNativeCustomPayload(
    Map<String, dynamic> json, {
    required String? objectName,
  }) {
    _assignIfEmpty(json, 'messageIdentifier', objectName);
    _assignIfEmpty(json, 'objectName', objectName);
    json['fields'] ??= _customFields(json['content']);
    json['rawData'] ??= _safeJsonEncode(
      json['fields'] ?? json['content'] ?? Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic>? _customFields(Object? value) {
    final map = _mapValue(value);
    if (map != null) {
      return map;
    }

    final text = _stringValue(value);
    if (text == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}

    return null;
  }

  RCIMIWMessage? _messageFromJson(Map<String, dynamic> json) {
    final messageType = _readMessageType(json['messageType']);
    if (messageType == null) {
      return null;
    }

    switch (messageType) {
      case RCIMIWMessageType.custom:
        return RCIMIWCustomMessage.fromJson(json);
      case RCIMIWMessageType.text:
        return RCIMIWTextMessage.fromJson(json);
      case RCIMIWMessageType.voice:
        _normalizeDuration(json);
        return RCIMIWVoiceMessage.fromJson(json);
      case RCIMIWMessageType.image:
        return RCIMIWImageMessage.fromJson(json);
      case RCIMIWMessageType.file:
        return RCIMIWFileMessage.fromJson(json);
      case RCIMIWMessageType.sight:
        _normalizeDuration(json);
        return RCIMIWSightMessage.fromJson(json);
      case RCIMIWMessageType.gif:
        return RCIMIWGIFMessage.fromJson(json);
      case RCIMIWMessageType.recall:
        return RCIMIWRecallNotificationMessage.fromJson(json);
      case RCIMIWMessageType.reference:
        return RCIMIWReferenceMessage.fromJson(json);
      case RCIMIWMessageType.command:
        return RCIMIWCommandMessage.fromJson(json);
      case RCIMIWMessageType.commandNotification:
        return RCIMIWCommandNotificationMessage.fromJson(json);
      case RCIMIWMessageType.location:
        return RCIMIWLocationMessage.fromJson(json);
      case RCIMIWMessageType.nativeCustom:
        return RCIMIWNativeCustomMessage.fromJson(json);
      case RCIMIWMessageType.stream:
        return RCIMIWStreamMessage.fromJson(json);
      case RCIMIWMessageType.nativeCustomMedia:
        return RCIMIWNativeCustomMediaMessage.fromJson(json);
      case RCIMIWMessageType.groupNotification:
        return RCIMIWGroupNotificationMessage.fromJson(json);
      case RCIMIWMessageType.combineV2:
        return RCIMIWCombineV2Message.fromJson(json);
      case RCIMIWMessageType.unknown:
      case RCIMIWMessageType.userCustom:
        return RCIMIWUnknownMessage.fromJson(json);
    }
  }

  RCIMIWMessage _unknownMessage(
    RCIMIWCombineMsgInfo info,
    int index,
    Map<String, dynamic>? content,
  ) {
    final json = <String, dynamic>{
      'messageType': RCIMIWMessageType.unknown.index,
      'senderUserId': info.fromUserId,
      'targetId': info.targetId,
      'sentTime': info.timestamp,
      'receivedTime': info.timestamp,
      'messageUId': 'combine:unsupported:$index:${info.timestamp ?? ''}',
      'objectName': info.objectName,
      'rawData': _safeJsonEncode(content),
    };

    return RCIMIWUnknownMessage.fromJson(json);
  }

  RCIMIWMessageType? _readMessageType(dynamic value) {
    int? index;
    if (value is int) {
      index = value;
    } else if (value is num) {
      index = value.toInt();
    } else if (value is String) {
      index = int.tryParse(value);
    }

    if (index == null ||
        index < 0 ||
        index >= RCIMIWMessageType.values.length) {
      return null;
    }

    return RCIMIWMessageType.values[index];
  }

  RCIMIWMessageType? _messageTypeForReadableContent(Map<String, dynamic> json) {
    final content = _stringValue(json['content']);
    if (content == null || content.isEmpty) {
      return null;
    }

    return RCIMIWMessageType.text;
  }

  RCIMIWMessageType? _messageTypeForObjectName(String? objectName) {
    switch (objectName) {
      case 'RC:TxtMsg':
        return RCIMIWMessageType.text;
      case 'RC:ImgMsg':
        return RCIMIWMessageType.image;
      case 'RC:VcMsg':
        return RCIMIWMessageType.voice;
      case 'RC:FileMsg':
        return RCIMIWMessageType.file;
      case 'RC:SightMsg':
        return RCIMIWMessageType.sight;
      case 'RC:GIFMsg':
        return RCIMIWMessageType.gif;
      case 'RC:ReferenceMsg':
        return RCIMIWMessageType.reference;
      case 'RC:CombineV2Msg':
        return RCIMIWMessageType.combineV2;
      case RongCallSummaryParser.objectName:
        return RCIMIWMessageType.unknown;
      default:
        return null;
    }
  }

  Map<String, dynamic>? _messageContentMap(Object? value) {
    final map = _mapValue(value);
    if (map != null) {
      return map;
    }

    final text = _stringValue(value);
    if (text == null) {
      return null;
    }

    return <String, dynamic>{'content': text};
  }

  Map<String, dynamic>? _mapValue(Object? value) {
    if (value is! Map) {
      return null;
    }

    try {
      return value.map((key, value) => MapEntry(key.toString(), value));
    } catch (_) {
      return null;
    }
  }

  String? _stringValue(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final text = value.trim();
      return text.isEmpty ? null : value;
    }

    if (value is num || value is bool) {
      return value.toString();
    }

    return null;
  }

  String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _stringValue(json[key]);
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  void _assignIfEmpty(Map<String, dynamic> json, String key, Object? value) {
    if (value == null) {
      return;
    }

    final current = json[key];
    if (current == null || (current is String && current.trim().isEmpty)) {
      json[key] = value;
    }
  }

  void _normalizeDuration(Map<String, dynamic> json) {
    final duration = json['duration'];
    if (duration is double) {
      json['duration'] = duration.ceil();
    }
  }

  String? _safeJsonEncode(Object? value) {
    if (value == null) {
      return null;
    }

    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }

  Widget _buildMessageNode(ChatDetailMessage message) {
    switch (message.kind) {
      case ChatDetailMessageKind.timestamp:
        return _buildCenterTextMessage(message.text ?? '');
      case ChatDetailMessageKind.withdrawnNotice:
        return _buildCenterTextMessage(
          AppLocalizations.of(context)!.chatDetailWithdrewMessage,
        );
      case ChatDetailMessageKind.fm:
        return _buildCenterTextMessage(message.text ?? '');
      default:
        return ChatMessageItem(
          isMe: message.isMe,
          isUnread: false,
          showBubble: message.showBubble,
          onLongPressStart: (_) {},
          child: _buildMessageContent(message),
        );
    }
  }

  Widget _buildCenterTextMessage(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.grey400,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(ChatDetailMessage message) {
    switch (message.kind) {
      case ChatDetailMessageKind.text:
      case ChatDetailMessageKind.fm:
        return ChatTextMessageContent(
          message: message.text ?? '',
          quoteText: message.quoteText,
        );
      case ChatDetailMessageKind.voice:
        return ChatVoiceMessageContent(duration: message.duration ?? '');
      case ChatDetailMessageKind.image:
        return ChatImageMessageContent(imagePath: message.imagePath ?? '');
      case ChatDetailMessageKind.video:
        return ChatVideoMessageContent(
          thumbnailBase64String: message.thumbnailBase64String ?? '',
          duration: message.duration,
        );
      case ChatDetailMessageKind.file:
        return ChatFileMessageContent(
          fileName: message.fileName ?? '',
          fileSize: message.fileSize ?? '',
        );
      case ChatDetailMessageKind.combineForward:
        final raw = message.extra;
        return ChatCombineMessageContent(
          title: message.text ?? '聊天记录',
          summaries: message.combineSummaries ?? const <String>[],
          onTap: raw is RCIMIWCombineV2Message
              ? () => _openNestedCombine(raw)
              : null,
        );
      case ChatDetailMessageKind.call:
        return ChatCallMessageContent(
          text: message.text ?? '',
          isVideo: message.isVideo,
          isMe: message.isMe,
        );
      default:
        return const SizedBox();
    }
  }

  void _openNestedCombine(RCIMIWCombineV2Message message) {
    context.push('/chat-combine-forward-detail', extra: message);
  }
}
