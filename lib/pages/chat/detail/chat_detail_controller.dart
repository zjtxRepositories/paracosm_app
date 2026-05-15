import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/modules/im/listener/im_data_center.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/manager/im_conversation_manager.dart';
import 'package:paracosm/modules/im/manager/im_message_manager.dart';
import 'package:paracosm/modules/im/manager/im_subscribe_event_manager.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:paracosm/pages/chat/chat_detail_message_mapper.dart';
import 'package:paracosm/pages/chat/chat_session_args.dart';
import 'package:paracosm/pages/chat/detail/scroll_engine.dart';
import 'package:rongcloud_call_wrapper_plugin/wrapper/rongcloud_call_constants.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:video_compress/video_compress.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

import '../../../core/models/media_item.dart';
import '../../../modules/call/rong_call_manager.dart';
import '../../../modules/call/rong_call_summary_parser.dart';
import '../../../modules/im/message/base/im_message.dart';
import '../../../modules/im/message/send/im_sender.dart';
import '../../../modules/manager/voice_player_manager.dart';
import '../../../modules/manager/voice_record_manager.dart';
import '../../../util/media_handle_util.dart';
import '../../../widgets/chat/chat_forward_target_modal.dart';
import '../../../widgets/chat/voice_record_overlay.dart';
import '../../../widgets/common/app_media_gallery.dart';
import '../../../widgets/common/app_toast.dart';

class ChatDetailController extends ChangeNotifier {
  ChatDetailController(this.args);

   ChatSessionArgs? args;

  BuildContext? context;

  final ImMessageManager _messageManager = ImMessageManager();

  final ImConversationManager _conversationManager = ImConversationManager();

  final ImSubscribeEventManager _subscribeEventManager =
      ImSubscribeEventManager();

  final inputController = TextEditingController();

  /// =========================
  /// Scroll Engine（唯一数据源）
  /// =========================
  late final ScrollEngine engine = ScrollEngine(
    getId: (msg) => msg.messageId,
    onUpdate: () => notifyListeners(),
  );

  /// =========================
  /// 状态
  /// =========================
  bool isInputEmpty = true;

  bool isMenuExpanded = false;

  bool isVoiceMode = false;

  bool isOnline = false;

  bool isRecording = false;

  bool isCancelling = false;

  bool isLoading = false;

  bool isLoadingMore = false;

  bool hasMore = true;

  RCIMIWMessage? quotedMessage;

  String? quotedText;

  int? _oldestTime;

  final voiceManager = VoiceRecordManager();

  final voicePlayerManager = VoicePlayerManager();

  /// =========================
  /// Stream
  /// =========================
  StreamSubscription<MessageEvent>? _messageSub;

  StreamSubscription<Map<String, PresenceState>>? _eventSub;

  StreamSubscription? _conversationChangeSub;

  StreamSubscription? _groupChangeSub;

  StreamSubscription? _profileChangeSub;

  /// =========================
  /// init
  /// =========================
  void init() {
    engine.init();

    _initInputListener();

    _loadInitialMessages().then((list) {
      engine.merge(list);

      _markConversationRead();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasAnchor) {
          return;
        }

        engine.onFirstLoaded();
      });
    });

    _subscribeMessages();

    _subscribeVoice();

    _listenConversation();

    _listenConversation();

    _listenProfile();

    _listenGroup();

  }

  @override
  void dispose() {
    super.dispose();
    _subscribeEventManager.unsubscribe([args!.targetId]);

    inputController.dispose();

    engine.dispose();

    _messageSub?.cancel();

    _eventSub?.cancel();

    _conversationChangeSub?.cancel();

    _groupChangeSub?.cancel();

    _profileChangeSub?.cancel();

  }

  /// =========================
  /// input
  /// =========================
  void _initInputListener() {
    inputController.addListener(() {
      final empty = inputController.text.trim().isEmpty;

      if (empty != isInputEmpty) {
        isInputEmpty = empty;

        notifyListeners();
      }
    });
  }

  /// =========================
  /// UI 直接用 engine 数据
  /// =========================
  List<ChatDetailMessage> get messages => engine.list.cast<ChatDetailMessage>();

  bool get hasAnchor => args?.anchorSentTime != null;

  String? get anchorMessageId => args?.anchorMessageId;

  /// =========================
  /// 初始加载
  /// =========================
  Future<List<ChatDetailMessage>> _loadInitialMessages() {
    if (hasAnchor) {
      return _loadMessagesAroundAnchor();
    }

    return _loadMessages();
  }

  Future<List<ChatDetailMessage>> _loadMessages() async {
    if (args == null) {
      return [];
    }

    isLoading = true;

    notifyListeners();

    try {
      final result = await _messageManager.getMessages(
        type: args!.conversationType,
        targetId: args!.targetId,
        sentTime: DateTime.now().millisecondsSinceEpoch,
        order: RCIMIWTimeOrder.before,
        policy: RCIMIWMessageOperationPolicy.localRemote,
      );

      final list = await ChatDetailMessageMapper.mapMessages(
        result.reversed.toList(),
      );

      if (list.isNotEmpty) {
        _oldestTime = list.first.sentTime;
      }

      return list;
    } catch (e) {
      debugPrint('load error: $e');

      return [];
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  Future<List<ChatDetailMessage>> _loadMessagesAroundAnchor() async {
    if (args == null || args!.anchorSentTime == null) {
      return [];
    }

    isLoading = true;

    notifyListeners();

    try {
      final result = await _messageManager.getMessagesAroundTime(
        type: args!.conversationType,
        targetId: args!.targetId,
        channelId: args!.channelId,
        sentTime: args!.anchorSentTime!,
        beforeCount: 10,
        afterCount: 10,
      );

      if (!result.success) {
        return _loadMessages();
      }

      final rawMessages = result.data ?? [];

      final list = await ChatDetailMessageMapper.mapMessages(
        rawMessages.reversed.toList(),
      );

      if (list.isNotEmpty) {
        _oldestTime = list.first.sentTime;
      }

      return list;
    } catch (e) {
      debugPrint('load anchor error: $e');

      return _loadMessages();
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  /// =========================
  /// 加载更多
  /// =========================
  Future<void> loadMoreMessages() async {
    if (args == null) {
      return;
    }

    if (isLoadingMore || !hasMore || _oldestTime == null) {
      return;
    }

    isLoadingMore = true;

    notifyListeners();

    try {
      final result = await _messageManager.getMessages(
        type: args!.conversationType,
        targetId: args!.targetId,
        sentTime: _oldestTime!,
        order: RCIMIWTimeOrder.before,
        policy: RCIMIWMessageOperationPolicy.localRemote,
      );

      final list = await ChatDetailMessageMapper.mapMessages(
        result.reversed.toList(),
      );

      if (list.isEmpty) {
        hasMore = false;
      } else {
        _oldestTime = list.first.sentTime;

        /// ⭐ 核心：只交给 engine
        engine.prepend(list);
      }
    } catch (e) {
      debugPrint('load more error: $e');
    }

    isLoadingMore = false;

    notifyListeners();
  }

  Future<bool> loadMessagesAroundTime(int sentTime) async {
    if (args == null || isLoadingMore) {
      return false;
    }

    isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _messageManager.getMessagesAroundTime(
        type: args!.conversationType,
        targetId: args!.targetId,
        channelId: args!.channelId,
        sentTime: sentTime,
        beforeCount: 10,
        afterCount: 10,
      );

      if (!result.success) {
        return false;
      }

      final rawMessages = result.data ?? [];
      if (rawMessages.isEmpty) {
        return false;
      }

      final list = await ChatDetailMessageMapper.mapMessages(
        rawMessages.reversed.toList(),
      );
      if (list.isEmpty) {
        return false;
      }

      final firstSentTime = list.first.sentTime;
      if (firstSentTime != null &&
          (_oldestTime == null || firstSentTime < _oldestTime!)) {
        _oldestTime = firstSentTime;
      }

      engine.merge(list);
      return true;
    } catch (e) {
      debugPrint('load around time error: $e');
      return false;
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> deleteMessage(ChatDetailMessage message) async {
    await deleteMessages([message]);
  }

  Future<bool> deleteMessages(List<ChatDetailMessage> messages) async {
    final rawMessages = messages
        .map((message) => message.extra)
        .whereType<RCIMIWMessage>()
        .toList();

    if (rawMessages.isEmpty) {
      AppToast.show('删除失败');
      return false;
    }

    final success = await _messageManager.deleteLocalMessages(
      messages: rawMessages,
    );

    if (!success) {
      AppToast.show('删除失败');
    }

    return success;
  }

  Future<bool> forwardMessages({
    required List<ChatDetailMessage> messages,
    required List<ChatForwardTarget> targets,
  }) async {
    if (args == null || targets.isEmpty) {
      return false;
    }

    final selectedIds = messages.map((message) => message.messageId).toSet();
    final rawMessages = this.messages
        .where((message) => selectedIds.contains(message.messageId))
        .map((message) => message.extra)
        .whereType<RCIMIWMessage>()
        .where((message) => !_isRecallMessage(message))
        .toList();

    final msgList = <RCIMIWCombineMsgInfo>[];
    final summaryList = <String>[];
    final nameList = <String>[];
    final nameSet = <String>{};

    for (final raw in rawMessages) {
      final objectName = _messageObjectName(raw);
      if (objectName == null || objectName.isEmpty) {
        continue;
      }

      final senderName = await _senderName(raw.senderUserId);
      if (nameSet.add(senderName)) {
        nameList.add(senderName);
      }

      final summary = await ChatDetailMessageMapper.quoteSummaryForMessage(raw);
      summaryList.add('$senderName: $summary');
      msgList.add(
        RCIMIWCombineMsgInfo.create(
          fromUserId: raw.senderUserId,
          targetId: raw.targetId,
          timestamp: raw.sentTime ?? raw.receivedTime,
          objectName: objectName,
          content: raw.toJson(),
        ),
      );
    }

    if (msgList.isEmpty) {
      AppToast.show('暂无可转发消息');
      return false;
    }

    var allSuccess = true;

    for (final target in targets) {
      final sent = await ImSender.instance.send(
        message: CombineForwardMessage(
          conversationType: target.conversationType,
          targetId: target.targetId,
          channelId: target.channelId,
          originalConversationType: args!.conversationType,
          summaryList: summaryList.take(4).toList(),
          nameList: nameList.isEmpty ? [''] : nameList,
          msgList: msgList,
        ),
      );

      if (!sent) {
        allSuccess = false;
      }
    }

    AppToast.show(allSuccess ? '转发成功' : '转发失败');
    return allSuccess;
  }

  Future<bool> forwardMessage({
    required ChatDetailMessage message,
    required List<ChatForwardTarget> targets,
  }) async {
    if (targets.isEmpty) {
      return false;
    }

    final raw = message.extra;
    if (raw is! RCIMIWMessage || _isRecallMessage(raw)) {
      AppToast.show('暂无可转发消息');
      return false;
    }

    var hasForwardableMessage = false;
    var allSuccess = true;

    for (final target in targets) {
      final forwardMessage = _singleForwardMessageForTarget(raw, target);
      if (forwardMessage == null) {
        allSuccess = false;
        continue;
      }

      hasForwardableMessage = true;
      final sent = await ImSender.instance.send(message: forwardMessage);
      if (!sent) {
        allSuccess = false;
      }
    }

    if (!hasForwardableMessage) {
      AppToast.show('暂无可转发消息');
      return false;
    }

    AppToast.show(allSuccess ? '转发成功' : '转发失败');
    return allSuccess;
  }

  ImMessage? _singleForwardMessageForTarget(
    RCIMIWMessage raw,
    ChatForwardTarget target,
  ) {
    if (raw is RCIMIWTextMessage) {
      final text = raw.text?.trim();
      if (text == null || text.isEmpty) {
        return null;
      }

      return TextMessage(
        conversationType: target.conversationType,
        targetId: target.targetId,
        channelId: target.channelId,
        content: raw.text ?? '',
      );
    }

    if (raw is RCIMIWImageMessage) {
      final path = _forwardLocalPath(raw);
      if (path == null) {
        return null;
      }

      return ImageMessage(
        conversationType: target.conversationType,
        targetId: target.targetId,
        channelId: target.channelId,
        path: path,
      );
    }

    if (raw is RCIMIWVoiceMessage) {
      final path = _forwardLocalPath(raw);
      if (path == null) {
        return null;
      }

      return VoiceMessage(
        conversationType: target.conversationType,
        targetId: target.targetId,
        channelId: target.channelId,
        path: path,
        duration: raw.duration ?? 0,
      );
    }

    if (raw is RCIMIWSightMessage) {
      final path = _forwardLocalPath(raw);
      if (path == null) {
        return null;
      }

      return VideoMessage(
        conversationType: target.conversationType,
        targetId: target.targetId,
        channelId: target.channelId,
        path: path,
        duration: raw.duration ?? 0,
        thumbnailBase64String: raw.thumbnailBase64String ?? '',
      );
    }

    if (raw is RCIMIWFileMessage) {
      final path = _forwardLocalPath(raw);
      if (path == null) {
        return null;
      }

      return FileMessage(
        conversationType: target.conversationType,
        targetId: target.targetId,
        channelId: target.channelId,
        path: path,
        size: raw.size ?? 0,
        name: raw.name ?? _fileNameFromPath(path),
      );
    }

    if (raw is RCIMIWReferenceMessage) {
      final referenceMessage = raw.referenceMessage;
      if (referenceMessage == null) {
        return null;
      }

      return ReferenceMessage(
        conversationType: target.conversationType,
        targetId: target.targetId,
        channelId: target.channelId,
        referenceMessage: referenceMessage,
        content: raw.text ?? '',
      );
    }

    if (raw is RCIMIWCombineV2Message) {
      final msgList = raw.msgList;
      if (msgList == null || msgList.isEmpty) {
        return null;
      }

      return CombineForwardMessage(
        conversationType: target.conversationType,
        targetId: target.targetId,
        channelId: target.channelId,
        originalConversationType: _combineConversationType(raw, target),
        summaryList: raw.summaryList ?? const <String>[],
        nameList: raw.nameList ?? const <String>[''],
        msgList: msgList,
      );
    }

    if (raw is RCIMIWCustomMessage) {
      final identifier = raw.identifier;
      final fields = raw.fields;
      if (identifier == null || identifier.isEmpty || fields == null) {
        return null;
      }

      return ForwardCustomMessage(
        conversationType: target.conversationType,
        targetId: target.targetId,
        channelId: target.channelId,
        messageIdentifier: identifier,
        policy: raw.policy ?? RCIMIWCustomMessagePolicy.normal,
        fields: fields,
      );
    }

    return null;
  }

  String? _forwardLocalPath(RCIMIWMediaMessage message) {
    final path = message.local?.trim();
    if (path == null || path.isEmpty) {
      return null;
    }

    if (!File(path).existsSync()) {
      return null;
    }

    return path;
  }

  String _fileNameFromPath(String path) {
    final parts = path.split(RegExp(r'[\\/]'));
    return parts.isEmpty ? path : parts.last;
  }

  RCIMIWConversationType _combineConversationType(
    RCIMIWCombineV2Message message,
    ChatForwardTarget target,
  ) {
    final index = message.combineConversationType;
    if (index != null &&
        index >= 0 &&
        index < RCIMIWConversationType.values.length) {
      return RCIMIWConversationType.values[index];
    }

    return args?.conversationType ?? target.conversationType;
  }

  Future<String> _senderName(String? senderUserId) async {
    final userId = senderUserId ?? '';
    if (userId.isEmpty) {
      return '未知用户';
    }

    try {
      final user = await UserDisplayStateCenter().getUser(userId);
      final name = user?.name.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    } catch (_) {}

    return userId.length > 8 ? userId.substring(userId.length - 8) : userId;
  }

  String? _messageObjectName(RCIMIWMessage message) {
    if (RongCallSummaryParser.tryParse(message) != null) {
      return RongCallSummaryParser.objectName;
    }

    if (message is RCIMIWUnknownMessage) {
      return message.objectName;
    }

    if (message is RCIMIWNativeCustomMessage) {
      return message.messageIdentifier;
    }

    if (message is RCIMIWCustomMessage) {
      return message.identifier;
    }

    switch (message.messageType) {
      case RCIMIWMessageType.text:
        return 'RC:TxtMsg';
      case RCIMIWMessageType.image:
        return 'RC:ImgMsg';
      case RCIMIWMessageType.voice:
        return 'RC:VcMsg';
      case RCIMIWMessageType.file:
        return 'RC:FileMsg';
      case RCIMIWMessageType.sight:
        return 'RC:SightMsg';
      case RCIMIWMessageType.reference:
        return 'RC:ReferenceMsg';
      case RCIMIWMessageType.combineV2:
        return 'RC:CombineV2Msg';
      default:
        return null;
    }
  }

  Future<void> recallMessage(ChatDetailMessage message) async {
    final raw = message.extra;
    if (raw is! RCIMIWMessage) {
      AppToast.show('撤回失败');
      return;
    }

    final success = await _messageManager.recallMessage(message: raw);

    if (!success) {
      AppToast.show('撤回失败');
    }
  }

  void _listenConversation() {
    _conversationChangeSub = ImConversationManager().changeStream.listen((
      ConversationChangeEvent event,
    ) {
      final conversation = event.conversation;
      if (conversation == null) return;
      if (conversation.targetId != args?.targetId) return;
      if (event.type == ConversationChangeType.delete) {
        context?.go('/chat');
      }
    });
  }


  void _listenGroup() {
    _groupChangeSub = ImDataCenter().groupInfoStream.listen((
        groupIds
        ) async {
      if (!groupIds.contains(args?.targetId)) return;
      final info = await GroupStateCenter().getGroup(args?.targetId ?? '');
      if (info == null) return;
      final group = GroupModel(info: info);
      final name = await group.name;
      args = args?.copyWith(
        isGroup: true,
        name: name,
        avatar: info.portraitUri
      );
      notifyListeners();
    });
  }

  void _listenProfile() {
    _profileChangeSub = ImDataCenter().profileStream.listen((
        userIds
        ) async {
      if (!userIds.contains(args?.targetId)) return;
      final user = await UserDisplayStateCenter().getUser(args?.targetId ?? '');
      if (user == null) return;
      final name = user.name;
      args = args?.copyWith(
          isGroup: false,
          name: name,
          avatar: user.avatar
      );
      notifyListeners();
    });
  }
  Future<void> quoteMessage(ChatDetailMessage message) async {
    final raw = message.extra;
    if (raw is! RCIMIWMessage || _isRecallMessage(raw)) {
      return;
    }

    quotedMessage = raw;
    quotedText = await ChatDetailMessageMapper.quoteSummaryForMessage(raw);
    isMenuExpanded = false;
    isVoiceMode = false;
    notifyListeners();
  }

  void clearQuote() {
    quotedMessage = null;
    quotedText = null;
    notifyListeners();
  }

  /// =========================
  /// 消息监听
  /// =========================
  Future<void> _subscribeMessages() async {
    _messageSub = _messageManager.messageStream.listen((event) async {
      if (args == null) {
        return;
      }

      switch (event.type) {
        /// =========================
        /// 新消息
        /// =========================
        case MessageEventType.add:
          final message = event.message;

          if (message == null) {
            return;
          }

          if (message.targetId != args!.targetId) {
            return;
          }

          if (message.conversationType != args!.conversationType) {
            return;
          }

          final msg = await ChatDetailMessageMapper.mapMessage(message);

          /// ⭐ append
          engine.append(msg);

          /// 标记已读
          _markConversationRead(timestamp: message.sentTime);

          if (engine.isAtBottom) {
            engine.scrollToBottom();
          }

          break;

        /// =========================
        /// 删除消息
        /// =========================
        case MessageEventType.delete:
          final deleteList = event.messages ?? [];

          if (deleteList.isEmpty) {
            return;
          }

          final uids = deleteList
              .map((e) => e.messageUId)
              .whereType<String>()
              .where((e) => e.isNotEmpty)
              .toSet();
          final ids = deleteList
              .map((e) => e.messageId)
              .whereType<int>()
              .where((e) => e > 0)
              .toSet();

          engine.removeWhere((e) {
            final raw = e.extra;

            if (raw is! RCIMIWMessage) {
              return false;
            }

            if (raw.targetId != args!.targetId) {
              return false;
            }

            if (raw.conversationType != args!.conversationType) {
              return false;
            }

            final uid = raw.messageUId;
            if (uid != null && uid.isNotEmpty && uids.contains(uid)) {
              return true;
            }

            final id = raw.messageId;
            return id != null && id > 0 && ids.contains(id);
          });

          break;

        /// =========================
        /// 撤回消息
        /// =========================
        case MessageEventType.recall:
          final recallMessage = event.message;

          if (recallMessage == null) {
            return;
          }

          if (!_isMessageInCurrentConversation(recallMessage)) {
            return;
          }

          final newMsg = await ChatDetailMessageMapper.mapMessage(
            recallMessage,
          );

          engine.replaceWhere(
            (e) => _matchesRecallMessage(e, recallMessage),
            newMsg,
          );

          break;

        /// =========================
        /// 清空消息
        /// =========================
        case MessageEventType.clear:
          if (event.targetId != args!.targetId) {
            return;
          }

          if (event.conversationType != args!.conversationType) {
            return;
          }

          engine.removeWhere((e) {
            final raw = e.extra;

            if (raw is! RCIMIWMessage) {
              return false;
            }

            return (raw.sentTime ?? 0) <= (event.timestamp ?? 0);
          });

          break;

        /// =========================
        /// 更新消息
        /// =========================
        case MessageEventType.update:
          break;
      }
    });

    /// =========================
    /// 在线状态
    /// =========================
    if (args?.isGroup != true) {
      _eventSub = _subscribeEventManager.stream.listen((map) {
        final status = map[args!.targetId] ?? PresenceState.unknown;
        isOnline = status == PresenceState.online;
        notifyListeners();
      });

      _subscribeEventManager.subscribeOnlineStatus([args!.targetId]);
    }
  }

  bool _matchesRecallMessage(
    ChatDetailMessage item,
    RCIMIWMessage recallMessage,
  ) {
    final raw = item.extra;

    if (raw is! RCIMIWMessage) {
      return false;
    }

    if (raw.targetId != args!.targetId) {
      return false;
    }

    if (raw.conversationType != args!.conversationType) {
      return false;
    }

    final originalMessage = recallMessage is RCIMIWRecallNotificationMessage
        ? recallMessage.originalMessage
        : null;

    if (originalMessage != null && _isSameMessage(raw, originalMessage)) {
      return true;
    }

    if (_isSameMessage(raw, recallMessage)) {
      return true;
    }

    final recallTime = recallMessage is RCIMIWRecallNotificationMessage
        ? recallMessage.recallTime
        : null;
    if (recallTime != null && recallTime > 0) {
      final rawTime = raw.sentTime ?? raw.receivedTime;
      return rawTime != null && rawTime == recallTime;
    }

    return false;
  }

  bool _isMessageInCurrentConversation(RCIMIWMessage message) {
    if (_isSameConversation(message)) {
      return true;
    }

    final originalMessage = message is RCIMIWRecallNotificationMessage
        ? message.originalMessage
        : null;
    return originalMessage != null && _isSameConversation(originalMessage);
  }

  bool _isSameConversation(RCIMIWMessage message) {
    return message.targetId == args!.targetId &&
        message.conversationType == args!.conversationType;
  }

  bool _isSameMessage(RCIMIWMessage left, RCIMIWMessage right) {
    final leftUid = left.messageUId;
    final rightUid = right.messageUId;
    if (leftUid != null &&
        leftUid.isNotEmpty &&
        rightUid != null &&
        rightUid.isNotEmpty) {
      return leftUid == rightUid;
    }

    final leftId = left.messageId;
    final rightId = right.messageId;
    return leftId != null &&
        leftId > 0 &&
        rightId != null &&
        rightId > 0 &&
        leftId == rightId;
  }

  bool _isRecallMessage(RCIMIWMessage message) {
    return message is RCIMIWRecallNotificationMessage ||
        message.messageType == RCIMIWMessageType.recall;
  }

  Future<void> _markConversationRead({int? timestamp}) async {
    if (args == null) {
      return;
    }

    await _conversationManager.markConversationRead(
      type: args!.conversationType,
      targetId: args!.targetId,
      channelId: args!.channelId,
      timestamp: timestamp,
    );
  }

  /// =========================
  /// 语音监听
  /// =========================
  void _subscribeVoice() {
    voiceManager.onSend = (path, duration) {
      sendVoice(path, duration);

      VoiceRecordOverlay.hide();
    };

    voiceManager.onStart = () {
      isRecording = true;

      notifyListeners();
    };

    voiceManager.onCancel = () {
      isRecording = false;

      notifyListeners();

      VoiceRecordOverlay.hide();
    };

    voiceManager.onVolume = (volume) {
      VoiceRecordOverlay.update(volume: volume);
    };

    voiceManager.onTooShort = () {
      VoiceRecordOverlay.update(isTooShort: true, text: '录音太短');

      Future.delayed(const Duration(milliseconds: 800), () {
        VoiceRecordOverlay.hide();
      });
    };
  }

  /// =========================
  /// 发送消息
  /// =========================
  Future<void> sendText() async {
    final text = inputController.text.trim();

    if (args == null || text.isEmpty) {
      return;
    }

    final quote = quotedMessage;
    final message = quote == null
        ? TextMessage(
            conversationType: args!.conversationType,
            targetId: args!.targetId,
            content: text,
          )
        : ReferenceMessage(
            conversationType: args!.conversationType,
            targetId: args!.targetId,
            channelId: args!.channelId,
            referenceMessage: quote,
            content: text,
          );

    await ImSender.instance.send(message: message);

    inputController.clear();
    quotedMessage = null;
    quotedText = null;
    notifyListeners();
  }

  Future<void> sendImage(String path) async {
    await ImSender.instance.send(
      message: ImageMessage(
        conversationType: args!.conversationType,
        targetId: args!.targetId,
        path: path,
      ),
    );
  }

  Future<void> sendVideo(MediaInfo media, String thumbnailBase64String) async {
    await ImSender.instance.send(
      message: VideoMessage(
        conversationType: args!.conversationType,
        targetId: args!.targetId,
        path: media.path ?? '',
        duration: (media.duration ?? 0).toInt(),
        thumbnailBase64String: thumbnailBase64String,
      ),
    );
  }

  Future<void> sendFile(String path, int size, String name) async {
    await ImSender.instance.send(
      message: FileMessage(
        conversationType: args!.conversationType,
        targetId: args!.targetId,
        path: path,
        size: size,
        name: name,
      ),
    );
  }

  Future<void> sendVoice(String path, int duration) async {
    await ImSender.instance.send(
      message: VoiceMessage(
        conversationType: args!.conversationType,
        targetId: args!.targetId,
        path: path,
        duration: duration,
      ),
    );
  }

  Future<void> handleAssetEntity(AssetEntity entity) async {
    final file = await entity.file;

    if (file == null) {
      return;
    }

    if (entity.type == AssetType.video) {
      await _handleVideo(file, entity);
    } else {
      await _handleImage(file);
    }
  }

  /// =========================
  /// 语音
  /// =========================
  Future<void> voiceStart() async {
    await voiceManager.startRecord();

    VoiceRecordOverlay.show(context!, isUp: false, volume: 0.1, text: '松开发送');
  }

  Future<void> voiceEnd() async {
    if (isCancelling) {
      await voiceManager.cancelRecord();
    } else {
      await voiceManager.stopRecord();
    }

    isRecording = false;

    isCancelling = false;

    notifyListeners();
  }

  Future<void> voiceUpdate(LongPressMoveUpdateDetails d) async {
    final dy = d.localPosition.dy;

    final cancel = dy < -50;

    if (cancel != isCancelling) {
      isCancelling = cancel;

      VoiceRecordOverlay.update(isUp: cancel, text: cancel ? '松开取消' : '松开发送');
    }
  }

  Future<void> voicePlay(String id, {String? path, String? url}) async {
    if (path == null) {
      return;
    }

    voicePlayerManager.play(id: id, path: path, url: url);
  }

  /// =========================
  /// UI 操作
  /// =========================
  void toggleMenu() {
    if (engine.isAtBottom) {
      engine.scrollToBottom();
    }

    FocusScope.of(context!).unfocus();

    isMenuExpanded = !isMenuExpanded;

    isVoiceMode = false;

    notifyListeners();
  }

  void toggleVoice() {
    FocusScope.of(context!).unfocus();

    isVoiceMode = !isVoiceMode;

    isMenuExpanded = false;

    notifyListeners();
  }

  void toggleAction() {
    if (isInputEmpty) {
      FocusScope.of(context!).unfocus();

      toggleMenu();
    } else {
      sendText();
    }
  }

  Future<void> toggleAlbum() async {
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context!,
      pickerConfig: const AssetPickerConfig(),
    );

    if (result == null) {
      return;
    }

    for (final e in result) {
      await handleAssetEntity(e);
    }
  }

  Future<void> toggleCamera() async {
    final AssetEntity? entity = await CameraPicker.pickFromCamera(
      context!,
      pickerConfig: const CameraPickerConfig(enableRecording: true),
    );

    if (entity == null) {
      return;
    }

    await handleAssetEntity(entity);
  }

  Future<void> toggleFile() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: false,
    );

    if (result == null) {
      return;
    }

    for (final f in result.files) {
      final path = f.path;

      if (path == null) {
        continue;
      }

      final file = File(path);

      await _handleFile(file, f.name, f.size);
    }
  }

  Future<void> _handleVideo(File file, AssetEntity entity) async {
    final thumb = await entity.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
    );

    String thumbnailBase64String = '';

    if (thumb != null && thumb.isNotEmpty) {
      thumbnailBase64String = base64Encode(thumb);
    }

    final compressed = await MediaHandleUtil.compressedVideoQuality(file);

    if (compressed?.video == null) {
      return;
    }

    sendVideo(compressed!.video!, thumbnailBase64String);
  }

  Future<void> _handleImage(File file) async {
    final path = await MediaHandleUtil.compressedImageQuality(file.path);

    sendImage(path);
  }

  Future<void> _handleFile(File file, String name, int size) async {
    sendFile(file.path, size, name);
  }

  void openMediaViewer({required List<MediaItem> list, required int index}) {
    Navigator.push(
      context!,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AppMediaGallery(list: list, initialIndex: index),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void navigateToSettings() {
    if (args?.isGroup ?? false) {
      context?.push('/group-details', extra: args);
    } else {
      final encodedName = Uri.encodeComponent(sessionName);
      context?.push('/session-details/$encodedName', extra: args);
    }
  }

  void navigateToProfile() {
    if (args?.isGroup ?? false) {
      navigateToSettings();
      return;
    }

    context?.push('/user-profile', extra: args?.targetId ?? '');
  }

  Future<void> openCallPage({required bool isVideo}) async {
    if (args?.isGroup ?? false) {
      AppToast.showInfo('群通话暂未开放');
      isMenuExpanded = false;
      notifyListeners();
      return;
    }

    final encoded = Uri.encodeComponent(sessionName);
    final media = isVideo ? 'video' : 'voice';

    isMenuExpanded = false;
    notifyListeners();
    final started = await RongCallManager().startPrivateCall(
      targetId: targetId,
      displayName: sessionName,
      mediaType: isVideo ? RCCallMediaType.audio_video : RCCallMediaType.audio,
    );
    if (!started) return;
    context?.push('/chat-private-$media/$encoded');
  }

  String get sessionName => args?.name ?? '';

  bool get isGroupSession => args?.isGroup ?? false;

  String get targetId => args?.targetId ?? '';

  String get headerAvatar => args?.avatar ?? '';
}
