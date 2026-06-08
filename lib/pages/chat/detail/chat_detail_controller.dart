import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/core/network/api/upload_file_api.dart';
import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/modules/im/listener/im_data_center.dart';
import 'package:paracosm/modules/im/manager/im_burn_after_reading_manager.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/manager/im_conversation_manager.dart';
import 'package:paracosm/modules/im/manager/im_message_manager.dart';
import 'package:paracosm/modules/im/manager/im_subscribe_event_manager.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:paracosm/pages/chat/chat_detail_message_mapper.dart';
import 'package:paracosm/pages/chat/chat_session_args.dart';
import 'package:paracosm/pages/chat/detail/scroll_engine.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rongcloud_call_wrapper_plugin/wrapper/rongcloud_call_constants.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:video_compress/video_compress.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

import '../../../core/models/media_item.dart';
import '../../../modules/call/rong_call_manager.dart';
import '../../../modules/call/rong_call_summary_parser.dart';
import '../../../modules/im/message/base/im_message.dart';
import '../../../modules/im/message/custom_face_message.dart';
import '../../../modules/im/message/send/im_sender.dart';
import '../../../modules/manager/voice_player_manager.dart';
import '../../../modules/manager/voice_record_manager.dart';
import '../../../util/media_handle_util.dart';
import '../../../util/string_util.dart';
import '../../../widgets/chat/chat_forward_target_modal.dart';
import '../../../widgets/base/app_localizations.dart';
import '../../../widgets/chat/voice_record_overlay.dart';
import '../../../widgets/common/app_media_gallery.dart';
import '../../../widgets/common/app_toast.dart';
import 'file_download_state.dart';
import 'file_send_progress.dart';
import 'video_send_progress.dart';

class ChatDetailController extends ChangeNotifier {
  ChatDetailController(this.args);

  ChatSessionArgs? args;

  BuildContext? context;

  final ImMessageManager _messageManager = ImMessageManager();

  String _tr(String key, [Map<String, dynamic>? params]) =>
      AppLocalizations.currentText(key, params);

  final ImConversationManager _conversationManager = ImConversationManager();

  final ImSubscribeEventManager _subscribeEventManager =
      ImSubscribeEventManager();

  final Map<String, ValueNotifier<ChatDetailMessage>>
  _pendingVideoMessageNotifiers = {};

  final Map<String, String> _pendingVideoMessageIdsByRemote = {};

  final Map<String, ValueNotifier<ChatDetailMessage>>
  _pendingFileMessageNotifiers = {};

  final Map<String, String> _pendingFileMessageIdsByRemote = {};

  final Map<String, ValueNotifier<FileDownloadState>> _fileDownloadNotifiers =
      {};

  final Dio _downloadDio = Dio();

  final inputController = TextEditingController();
  int _readTimestamp = 0;
  final Set<String> _requestedGroupReadReceiptMessageUIds = {};
  final Set<String> _respondedGroupReadReceiptMessageUIds = {};

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

  bool isEmojiPanelExpanded = false;

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
      if (list.isNotEmpty) {
        _markConversationRead(timestamp: list.last.sentTime);
      }
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
    for (final notifier in _pendingVideoMessageNotifiers.values) {
      notifier.dispose();
    }
    _pendingVideoMessageNotifiers.clear();
    _pendingVideoMessageIdsByRemote.clear();
    for (final notifier in _pendingFileMessageNotifiers.values) {
      notifier.dispose();
    }
    _pendingFileMessageNotifiers.clear();
    _pendingFileMessageIdsByRemote.clear();
    for (final notifier in _fileDownloadNotifiers.values) {
      notifier.dispose();
    }
    _fileDownloadNotifiers.clear();

    final targetId = args?.targetId;
    if (targetId != null) {
      _subscribeEventManager.unsubscribe([targetId]);
    }

    inputController.dispose();

    engine.dispose();

    _messageSub?.cancel();

    _eventSub?.cancel();

    _conversationChangeSub?.cancel();

    _groupChangeSub?.cancel();

    _profileChangeSub?.cancel();

    super.dispose();
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

  ValueListenable<ChatDetailMessage>? pendingVideoMessageListenable(
    String messageId,
  ) {
    return _pendingVideoMessageNotifiers[messageId];
  }

  ValueListenable<ChatDetailMessage>? pendingFileMessageListenable(
    String messageId,
  ) {
    return _pendingFileMessageNotifiers[messageId];
  }

  ValueListenable<FileDownloadState> fileDownloadListenable(String messageId) {
    return _fileDownloadNotifier(messageId);
  }

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
      AppToast.show(_tr('chat_detail_delete_failed'));
      return false;
    }

    final success = await _messageManager.deleteLocalMessages(
      messages: rawMessages,
    );

    if (!success) {
      AppToast.show(_tr('chat_detail_delete_failed'));
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
      AppToast.show(_tr('chat_detail_no_forwardable_message'));
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

    AppToast.show(
      allSuccess
          ? _tr('chat_detail_forward_success')
          : _tr('chat_detail_forward_failed'),
    );
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
      AppToast.show(_tr('chat_detail_no_forwardable_message'));
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
      AppToast.show(_tr('chat_detail_no_forwardable_message'));
      return false;
    }

    AppToast.show(
      allSuccess
          ? _tr('chat_detail_forward_success')
          : _tr('chat_detail_forward_failed'),
    );
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
      return _tr('chat_detail_unknown_user');
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
      AppToast.show(_tr('chat_detail_recall_failed'));
      return;
    }

    final success = await _messageManager.recallMessage(message: raw);

    if (!success) {
      AppToast.show(_tr('chat_detail_recall_failed'));
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
    _groupChangeSub = ImDataCenter().groupInfoStream.listen((groupIds) async {
      if (!groupIds.contains(args?.targetId)) return;
      final info = await GroupStateCenter().getGroup(args?.targetId ?? '');
      if (info == null) return;
      final group = GroupModel(info: info);
      final name = await group.name;
      args = args?.copyWith(
        isGroup: true,
        name: name,
        avatar: info.portraitUri,
      );
      notifyListeners();
    });
  }

  void _listenProfile() {
    _profileChangeSub = ImDataCenter().profileStream.listen((userIds) async {
      if (!userIds.contains(args?.targetId)) return;
      final user = await UserDisplayStateCenter().getUser(args?.targetId ?? '');
      if (user == null) return;
      final name = user.name;
      args = args?.copyWith(isGroup: false, name: name, avatar: user.avatar);
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

          if (_replaceExistingMediaMessage(msg)) {
            unawaited(_requestGroupReadReceiptIfNeeded(message, msg));
            if (!msg.isMe) {
              _markConversationRead(timestamp: message.sentTime);
            }
            if (engine.isAtBottom) {
              engine.scrollToBottom();
            }
            break;
          }

          /// ⭐ append
          engine.append(msg);
          unawaited(_requestGroupReadReceiptIfNeeded(message, msg));

          if (!msg.isMe) {
            _markConversationRead(timestamp: message.sentTime);
          }

          if (engine.isAtBottom) {
            engine.scrollToBottom();
          }

          break;

        /// =========================
        /// 删除消息
        /// =========================
        case MessageEventType.delete:
          if (!_deleteEventCanApplyToCurrentConversation(event)) {
            return;
          }

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

            if (!_messageCanApplyToCurrentConversation(raw, event)) {
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
          if (!_replaceExistingMessage(msg)) {
            engine.append(msg);
          }
          unawaited(_requestGroupReadReceiptIfNeeded(message, msg));
          break;

        case MessageEventType.privateReadReceipt:
          if (event.targetId != args!.targetId) {
            return;
          }

          if (args!.conversationType != RCIMIWConversationType.private) {
            return;
          }

          final timestamp = event.timestamp;
          if (timestamp == null) {
            return;
          }

          _handlePrivateReadReceipt(timestamp);
          break;

        case MessageEventType.groupReadReceiptRequest:
          if (event.targetId != args!.targetId) {
            return;
          }

          if (args!.conversationType != RCIMIWConversationType.group) {
            return;
          }

          unawaited(
            _sendVisibleGroupReadReceiptResponses(messageUId: event.messageUId),
          );
          break;

        case MessageEventType.groupReadReceiptResponse:
          if (event.targetId != args!.targetId) {
            return;
          }

          if (args!.conversationType != RCIMIWConversationType.group) {
            return;
          }

          final messageUId = event.messageUId;
          if (messageUId == null || messageUId.isEmpty) {
            return;
          }

          _handleGroupReadReceiptResponse(messageUId, event.respondUserIds);
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

  bool _deleteEventCanApplyToCurrentConversation(MessageEvent event) {
    final session = args;
    if (session == null) {
      return false;
    }

    final eventType = event.conversationType;
    if (eventType != null && eventType != session.conversationType) {
      return false;
    }

    final eventTargetId = event.targetId;
    if (eventTargetId != null &&
        eventTargetId.isNotEmpty &&
        eventTargetId != session.targetId) {
      return false;
    }

    final eventChannelId = event.channelId;
    final sessionChannelId = session.channelId;
    if (eventChannelId != null &&
        eventChannelId.isNotEmpty &&
        sessionChannelId != null &&
        sessionChannelId.isNotEmpty &&
        eventChannelId != sessionChannelId) {
      return false;
    }

    return true;
  }

  bool _messageCanApplyToCurrentConversation(
    RCIMIWMessage message,
    MessageEvent event,
  ) {
    final session = args;
    if (session == null) {
      return false;
    }

    final messageType = message.conversationType;
    if (messageType != null && messageType != session.conversationType) {
      return false;
    }

    final messageTargetId = message.targetId;
    if (messageTargetId != null &&
        messageTargetId.isNotEmpty &&
        messageTargetId != session.targetId) {
      return false;
    }

    final messageChannelId = message.channelId;
    final sessionChannelId = session.channelId;
    if (messageChannelId != null &&
        messageChannelId.isNotEmpty &&
        sessionChannelId != null &&
        sessionChannelId.isNotEmpty &&
        messageChannelId != sessionChannelId) {
      return false;
    }

    return _deleteEventCanApplyToCurrentConversation(event);
  }

  Future<void> _requestGroupReadReceiptIfNeeded(
    RCIMIWMessage raw,
    ChatDetailMessage message,
  ) async {
    final session = args;
    if (session == null ||
        session.conversationType != RCIMIWConversationType.group ||
        !message.isMe ||
        !message.showReadReceipt ||
        !ChatDetailMessageMapper.supportsReadReceiptKind(message.kind)) {
      return;
    }

    if (!_isMessageInCurrentConversation(raw)) {
      return;
    }

    final messageUId = raw.messageUId;
    if (messageUId == null || messageUId.isEmpty) {
      return;
    }

    if (_requestedGroupReadReceiptMessageUIds.contains(messageUId)) {
      return;
    }

    _requestedGroupReadReceiptMessageUIds.add(messageUId);
    final success = await _messageManager.sendGroupReadReceiptRequest(
      message: raw,
    );
    if (!success) {
      _requestedGroupReadReceiptMessageUIds.remove(messageUId);
    }
  }

  void _handlePrivateReadReceipt(int timestamp) {
    engine.updateWhere(
      (message) {
        final raw = message.extra;
        final sentTime = message.sentTime;
        return message.isMe &&
            message.showReadReceipt &&
            ChatDetailMessageMapper.supportsReadReceiptKind(message.kind) &&
            raw is RCIMIWMessage &&
            raw.conversationType == RCIMIWConversationType.private &&
            sentTime != null &&
            sentTime <= timestamp;
      },
      (message) {
        final raw = message.extra;
        if (raw is RCIMIWMessage) {
          raw.sentStatus = RCIMIWSentStatus.read;
        }
        return message.copyWith(isRead: true, extra: raw);
      },
    );
  }

  void _handleGroupReadReceiptResponse(String messageUId, Map? respondUserIds) {
    final readCount = respondUserIds?.length ?? 0;

    engine.updateWhere(
      (message) {
        final raw = message.extra;
        return message.isMe &&
            message.showReadReceipt &&
            raw is RCIMIWMessage &&
            raw.messageUId == messageUId;
      },
      (message) =>
          message.copyWith(isRead: readCount > 0, groupReadCount: readCount),
    );
  }

  Future<void> _sendVisibleGroupReadReceiptResponses({
    String? messageUId,
  }) async {
    final session = args;
    if (session == null ||
        session.conversationType != RCIMIWConversationType.group) {
      return;
    }

    final messages = <RCIMIWMessage>[];
    final respondingUIds = <String>[];

    for (final item in engine.list) {
      if (item.isMe ||
          !ChatDetailMessageMapper.supportsReadReceiptKind(item.kind)) {
        continue;
      }

      final raw = item.extra;
      if (raw is! RCIMIWMessage || !_isMessageInCurrentConversation(raw)) {
        continue;
      }

      final rawMessageUId = raw.messageUId;
      if (rawMessageUId == null || rawMessageUId.isEmpty) {
        continue;
      }

      if (messageUId != null && rawMessageUId != messageUId) {
        continue;
      }

      if (_respondedGroupReadReceiptMessageUIds.contains(rawMessageUId)) {
        continue;
      }

      final receiptInfo = raw.groupReadReceiptInfo;
      if (receiptInfo?.hasRespond == true) {
        _respondedGroupReadReceiptMessageUIds.add(rawMessageUId);
        continue;
      }

      if (messageUId == null && receiptInfo?.readReceiptMessage != true) {
        continue;
      }

      messages.add(raw);
      respondingUIds.add(rawMessageUId);
    }

    if (messages.isEmpty) {
      return;
    }

    _respondedGroupReadReceiptMessageUIds.addAll(respondingUIds);
    final success = await _messageManager.sendGroupReadReceiptResponse(
      targetId: session.targetId,
      channelId: session.channelId,
      messages: messages,
    );

    if (!success) {
      _respondedGroupReadReceiptMessageUIds.removeAll(respondingUIds);
    }
  }

  Future<void> _markConversationRead({int? timestamp}) async {
    if (args == null) {
      return;
    }
    if (timestamp == null) {
      return;
    }
    if (_readTimestamp >= timestamp) return;
    _readTimestamp = timestamp;

    if (kDebugMode) {
      debugPrint('_markConversationRead---$timestamp');
    }
    final success = await _conversationManager.markConversationRead(
      type: args!.conversationType,
      targetId: args!.targetId,
      channelId: args!.channelId,
      timestamp: timestamp,
    );
    if (!success) {
      return;
    }

    if (args!.conversationType == RCIMIWConversationType.private) {
      unawaited(
        _messageManager.markMessagesReadForBurnAfterReading(
          messages: _readBurnAfterReadingMessages(timestamp),
        ),
      );

      unawaited(
        _messageManager.sendPrivateReadReceiptMessage(
          targetId: args!.targetId,
          channelId: args!.channelId,
          timestamp: timestamp,
        ),
      );
      return;
    }

    if (args!.conversationType == RCIMIWConversationType.group) {
      unawaited(_sendVisibleGroupReadReceiptResponses());
    }
  }

  List<RCIMIWMessage> _readBurnAfterReadingMessages(int timestamp) {
    final session = args;
    if (session == null ||
        session.conversationType != RCIMIWConversationType.private) {
      return [];
    }

    final messages = <RCIMIWMessage>[];
    for (final item in engine.list) {
      if (item.isMe) {
        continue;
      }

      final raw = item.extra;
      if (raw is! RCIMIWMessage || !_isMessageInCurrentConversation(raw)) {
        continue;
      }

      if ((raw.destructDuration ?? 0) <= 0) {
        continue;
      }

      final sentTime = raw.sentTime;
      if (sentTime == null || sentTime > timestamp) {
        continue;
      }

      messages.add(raw);
    }

    return messages;
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
      VoiceRecordOverlay.update(
        isTooShort: true,
        text: _tr('chat_detail_voice_too_short'),
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        VoiceRecordOverlay.hide();
      });
    };
  }

  /// =========================
  /// 发送消息
  /// =========================
  Future<int> _burnAfterReadingSecondsForCurrentSession() async {
    final session = args;
    if (session == null ||
        session.conversationType != RCIMIWConversationType.private) {
      return 0;
    }

    return ImBurnAfterReadingManager().getDurationSeconds(
      type: session.conversationType,
      targetId: session.targetId,
      channelId: session.channelId,
    );
  }

  Future<void> sendText() async {
    final text = inputController.text.trim();

    if (args == null || text.isEmpty) {
      return;
    }

    final quote = quotedMessage;
    final burnSeconds = await _burnAfterReadingSecondsForCurrentSession();
    final message = quote == null
        ? TextMessage(
            conversationType: args!.conversationType,
            targetId: args!.targetId,
            channelId: args!.channelId,
            content: text,
            destructDuration: burnSeconds,
          )
        : ReferenceMessage(
            conversationType: args!.conversationType,
            targetId: args!.targetId,
            channelId: args!.channelId,
            referenceMessage: quote,
            content: text,
            destructDuration: burnSeconds,
          );

    await ImSender.instance.send(message: message);

    inputController.clear();
    quotedMessage = null;
    quotedText = null;
    notifyListeners();
  }

  Future<void> sendCustomFace(ChatCustomFace face) async {
    final session = args;
    if (session == null) return;

    final burnSeconds = await _burnAfterReadingSecondsForCurrentSession();
    final sent = await ImSender.instance.send(
      message: CustomFaceMessage(
        conversationType: session.conversationType,
        targetId: session.targetId,
        channelId: session.channelId,
        face: face,
        destructDuration: burnSeconds,
      ),
    );

    if (!sent) {
      AppToast.show(_tr('chat_detail_send_failed'));
    }
  }

  Future<void> sendImage(String path) async {
    final session = args;
    final imagePath = path.trim();

    if (session == null || imagePath.isEmpty || !File(imagePath).existsSync()) {
      AppToast.show(_tr('chat_detail_image_send_failed'));
      return;
    }

    final burnSeconds = await _burnAfterReadingSecondsForCurrentSession();
    final sent = await ImSender.instance.send(
      message: ImageMessage(
        conversationType: session.conversationType,
        targetId: session.targetId,
        channelId: session.channelId,
        path: imagePath,
        destructDuration: burnSeconds,
      ),
    );

    if (!sent) {
      AppToast.show(_tr('chat_detail_image_send_failed'));
    }
  }

  Future<bool> sendVideo(
    MediaInfo media,
    String thumbnailBase64String, {
    required String remoteUrl,
    required String coverUrl,
    void Function(int progress)? onProgress,
  }) async {
    final session = args;
    final videoPath = media.path?.trim();
    final trimmedRemoteUrl = remoteUrl.trim();
    final trimmedCoverUrl = coverUrl.trim();

    if (session == null ||
        videoPath == null ||
        videoPath.isEmpty ||
        !File(videoPath).existsSync() ||
        trimmedRemoteUrl.isEmpty ||
        trimmedCoverUrl.isEmpty) {
      AppToast.show(_tr('chat_detail_video_send_failed'));
      return false;
    }

    final burnSeconds = await _burnAfterReadingSecondsForCurrentSession();
    final sent = await ImSender.instance.sendAndWait(
      message: VideoMessage(
        conversationType: session.conversationType,
        targetId: session.targetId,
        channelId: session.channelId,
        path: videoPath,
        duration: (media.duration ?? 0).toInt(),
        thumbnailBase64String: thumbnailBase64String,
        remoteUrl: trimmedRemoteUrl,
        coverUrl: trimmedCoverUrl,
        destructDuration: burnSeconds,
      ),
      onProgress: onProgress,
      pushSavedMessage: false,
    );

    if (!sent) {
      AppToast.show(_tr('chat_detail_video_send_failed'));
    }

    return sent;
  }

  Future<bool> sendFile(
    String path,
    int size,
    String name, {
    String? remoteUrl,
    void Function(int progress)? onProgress,
    bool pushSavedMessage = true,
  }) async {
    final session = args;
    final filePath = path.trim();
    final trimmedRemoteUrl = remoteUrl?.trim();

    if (session == null || filePath.isEmpty || !File(filePath).existsSync()) {
      AppToast.show(_tr('chat_detail_send_failed'));
      return false;
    }

    final burnSeconds = await _burnAfterReadingSecondsForCurrentSession();

    final message = FileMessage(
      conversationType: session.conversationType,
      targetId: session.targetId,
      channelId: session.channelId,
      path: filePath,
      size: size,
      name: name,
      remoteUrl: trimmedRemoteUrl,
      destructDuration: burnSeconds,
    );

    final sent = onProgress == null && pushSavedMessage
        ? await ImSender.instance.send(message: message)
        : await ImSender.instance.sendAndWait(
            message: message,
            onProgress: onProgress,
            pushSavedMessage: pushSavedMessage,
          );

    if (!sent) {
      AppToast.show(_tr('chat_detail_send_failed'));
    }

    return sent;
  }

  Future<void> sendVoice(String path, int duration) async {
    final session = args;
    if (session == null) return;

    final burnSeconds = await _burnAfterReadingSecondsForCurrentSession();
    await ImSender.instance.send(
      message: VoiceMessage(
        conversationType: session.conversationType,
        targetId: session.targetId,
        channelId: session.channelId,
        path: path,
        duration: duration,
        destructDuration: burnSeconds,
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

    VoiceRecordOverlay.show(
      context!,
      isUp: false,
      volume: 0.1,
      text: _tr('chat_detail_release_to_send'),
    );
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

      VoiceRecordOverlay.update(
        isUp: cancel,
        text: cancel
            ? _tr('chat_detail_release_to_cancel')
            : _tr('chat_detail_release_to_send'),
      );
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

    isEmojiPanelExpanded = false;

    isVoiceMode = false;

    notifyListeners();
  }

  void toggleEmojiPanel() {
    if (engine.isAtBottom) {
      engine.scrollToBottom();
    }

    FocusScope.of(context!).unfocus();

    isEmojiPanelExpanded = !isEmojiPanelExpanded;
    isMenuExpanded = false;
    isVoiceMode = false;

    notifyListeners();
  }

  void handleTextFieldTap() {
    var changed = false;
    if (isMenuExpanded) {
      isMenuExpanded = false;
      changed = true;
    }
    if (isEmojiPanelExpanded) {
      isEmojiPanelExpanded = false;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  void insertEmoji(String emoji) {
    ChatEmojiInputEditor.insert(inputController, emoji);
  }

  void deleteInputCharacter() {
    ChatEmojiInputEditor.deletePreviousCharacter(inputController);
  }

  void toggleVoice() {
    FocusScope.of(context!).unfocus();

    isVoiceMode = !isVoiceMode;

    isMenuExpanded = false;

    isEmojiPanelExpanded = false;

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
    final pendingId = 'pending-video-${DateTime.now().microsecondsSinceEpoch}';
    var thumbnailBase64String = await _thumbnailBase64FromEntity(entity);
    var pendingPath = file.path;
    var pendingDuration = formatDurationFromSeconds(entity.duration);

    final initialMessage = _pendingVideoMessage(
      messageId: pendingId,
      thumbnailBase64String: thumbnailBase64String,
      path: pendingPath,
      duration: pendingDuration,
      status: MediaSendStatus.sending,
      progress: 0,
    );
    _pendingVideoMessageNotifiers[pendingId] = ValueNotifier(initialMessage);

    engine.append(initialMessage);
    unawaited(engine.scrollToBottom());

    Subscription? compressSub;

    try {
      compressSub = VideoCompress.compressProgress$.subscribe((progress) {
        _updatePendingVideoMessage(
          messageId: pendingId,
          thumbnailBase64String: thumbnailBase64String,
          path: pendingPath,
          duration: pendingDuration,
          status: MediaSendStatus.sending,
          progress: mapVideoCompressionProgress(progress),
        );
      });

      final compressed = await MediaHandleUtil.compressedVideoQuality(file);

      compressSub.unsubscribe();
      compressSub = null;

      final videoPath = compressed?.video?.path;
      final coverPath = compressed?.thumbnail?.path;

      if (compressed == null ||
          compressed.video == null ||
          videoPath == null ||
          videoPath.trim().isEmpty ||
          coverPath == null ||
          coverPath.trim().isEmpty ||
          !File(videoPath).existsSync() ||
          !File(coverPath).existsSync()) {
        _markPendingVideoFailed(
          messageId: pendingId,
          thumbnailBase64String: thumbnailBase64String,
          path: pendingPath,
          duration: pendingDuration,
        );
        AppToast.show(_tr('chat_detail_video_send_failed'));
        return;
      }

      pendingPath = videoPath;
      pendingDuration = formatDurationFromMs(
        (compressed.video!.duration ?? 0).toInt(),
      );
      final coverBytes = await File(coverPath).readAsBytes();
      if (coverBytes.isNotEmpty) {
        thumbnailBase64String = base64Encode(coverBytes);
      }

      _updatePendingVideoMessage(
        messageId: pendingId,
        thumbnailBase64String: thumbnailBase64String,
        path: pendingPath,
        duration: pendingDuration,
        status: MediaSendStatus.sending,
        progress: 40,
        replaceInEngine: true,
      );

      var videoSent = 0;
      var videoTotal = 0;
      var coverSent = 0;
      var coverTotal = 0;

      void updateUploadProgress() {
        _updatePendingVideoMessage(
          messageId: pendingId,
          thumbnailBase64String: thumbnailBase64String,
          path: pendingPath,
          duration: pendingDuration,
          status: MediaSendStatus.sending,
          progress: mapVideoUploadProgress(
            videoSent: videoSent,
            videoTotal: videoTotal,
            coverSent: coverSent,
            coverTotal: coverTotal,
          ),
        );
      }

      final uploadResults = await Future.wait<String?>([
        UploadFileApi.uploadFileByPath(
          videoPath,
          onSendProgress: (sent, total) {
            videoSent = sent;
            videoTotal = total;
            updateUploadProgress();
          },
        ),
        UploadFileApi.uploadFileByPath(
          coverPath,
          onSendProgress: (sent, total) {
            coverSent = sent;
            coverTotal = total;
            updateUploadProgress();
          },
        ),
      ]);

      final remoteUrl = uploadResults[0];
      final coverUrl = uploadResults[1];

      if (remoteUrl == null ||
          remoteUrl.trim().isEmpty ||
          coverUrl == null ||
          coverUrl.trim().isEmpty) {
        _markPendingVideoFailed(
          messageId: pendingId,
          thumbnailBase64String: thumbnailBase64String,
          path: pendingPath,
          duration: pendingDuration,
        );
        AppToast.show(_tr('chat_detail_video_upload_failed'));
        return;
      }

      _registerPendingVideoRemote(messageId: pendingId, remote: remoteUrl);

      _updatePendingVideoMessage(
        messageId: pendingId,
        thumbnailBase64String: thumbnailBase64String,
        path: pendingPath,
        remote: remoteUrl,
        duration: pendingDuration,
        status: MediaSendStatus.sending,
        progress: 90,
        replaceInEngine: true,
      );

      final sent = await sendVideo(
        compressed.video!,
        thumbnailBase64String,
        remoteUrl: remoteUrl,
        coverUrl: coverUrl,
        onProgress: (progress) {
          _updatePendingVideoMessage(
            messageId: pendingId,
            thumbnailBase64String: thumbnailBase64String,
            path: pendingPath,
            remote: remoteUrl,
            duration: pendingDuration,
            status: MediaSendStatus.sending,
            progress: mapVideoImSendProgress(progress),
          );
        },
      );

      if (!sent) {
        _markPendingVideoFailed(
          messageId: pendingId,
          thumbnailBase64String: thumbnailBase64String,
          path: pendingPath,
          duration: pendingDuration,
        );
      }
    } catch (_) {
      _markPendingVideoFailed(
        messageId: pendingId,
        thumbnailBase64String: thumbnailBase64String,
        path: pendingPath,
        duration: pendingDuration,
      );
      AppToast.show(_tr('chat_detail_video_send_failed'));
    } finally {
      compressSub?.unsubscribe();
    }
  }

  Future<String> _thumbnailBase64FromEntity(AssetEntity entity) async {
    try {
      final thumb = await entity.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
      );
      if (thumb == null || thumb.isEmpty) {
        return '';
      }
      return base64Encode(thumb);
    } catch (_) {
      return '';
    }
  }

  ChatDetailMessage _pendingVideoMessage({
    required String messageId,
    required String thumbnailBase64String,
    required String path,
    required String duration,
    required MediaSendStatus status,
    required int progress,
    String? remote,
  }) {
    return ChatDetailMessage(
      messageId: messageId,
      kind: ChatDetailMessageKind.video,
      isMe: true,
      sentTime: DateTime.now().millisecondsSinceEpoch,
      thumbnailBase64String: thumbnailBase64String,
      path: path,
      remote: remote,
      duration: duration,
      mediaSendStatus: status,
      mediaSendProgress: progress.clamp(0, 100).toInt(),
    );
  }

  void _updatePendingVideoMessage({
    required String messageId,
    required String thumbnailBase64String,
    required String path,
    required String duration,
    required MediaSendStatus status,
    required int progress,
    String? remote,
    bool replaceInEngine = false,
  }) {
    if (!engine.containsId(messageId)) {
      return;
    }

    final next = _pendingVideoMessage(
      messageId: messageId,
      thumbnailBase64String: thumbnailBase64String,
      path: path,
      remote: remote,
      duration: duration,
      status: status,
      progress: progress,
    );

    final notifier = _pendingVideoMessageNotifiers[messageId];
    if (notifier == null) {
      _pendingVideoMessageNotifiers[messageId] = ValueNotifier(next);
    } else if (_shouldPublishPendingVideoMessage(notifier.value, next)) {
      notifier.value = next;
    }

    if (replaceInEngine) {
      engine.replace(next);
    }
  }

  bool _shouldPublishPendingVideoMessage(
    ChatDetailMessage previous,
    ChatDetailMessage next,
  ) {
    return shouldNotifyVideoSendProgress(
          previousProgress: previous.mediaSendProgress,
          nextProgress: next.mediaSendProgress,
          statusChanged: previous.mediaSendStatus != next.mediaSendStatus,
        ) ||
        previous.thumbnailBase64String != next.thumbnailBase64String ||
        previous.path != next.path ||
        previous.remote != next.remote ||
        previous.duration != next.duration;
  }

  void _markPendingVideoFailed({
    required String messageId,
    required String thumbnailBase64String,
    required String path,
    required String duration,
  }) {
    _removePendingVideoRemoteMappings(messageId);
    _updatePendingVideoMessage(
      messageId: messageId,
      thumbnailBase64String: thumbnailBase64String,
      path: path,
      duration: duration,
      status: MediaSendStatus.failed,
      progress: 0,
      replaceInEngine: true,
    );
  }

  Future<void> _handleImage(File file) async {
    final path = await MediaHandleUtil.compressedImageQuality(file.path);

    await sendImage(path);
  }

  Future<void> _handleFile(File file, String name, int size) async {
    final pendingId = 'pending-file-${DateTime.now().microsecondsSinceEpoch}';
    final filePath = file.path;

    final initialMessage = _pendingFileMessage(
      messageId: pendingId,
      path: filePath,
      name: name,
      size: size,
      status: MediaSendStatus.sending,
      progress: 0,
    );
    _pendingFileMessageNotifiers[pendingId] = ValueNotifier(initialMessage);

    engine.append(initialMessage);
    unawaited(engine.scrollToBottom());

    try {
      final remoteUrl = await UploadFileApi.uploadFileByPath(
        filePath,
        onSendProgress: (sent, total) {
          _updatePendingFileMessage(
            messageId: pendingId,
            path: filePath,
            name: name,
            size: size,
            status: MediaSendStatus.sending,
            progress: mapFileUploadProgress(sent: sent, total: total),
          );
        },
      );

      if (remoteUrl == null || remoteUrl.trim().isEmpty) {
        _markPendingFileFailed(
          messageId: pendingId,
          path: filePath,
          name: name,
          size: size,
        );
        AppToast.show(_tr('common_upload_failed'));
        return;
      }

      _registerPendingFileRemote(messageId: pendingId, remote: remoteUrl);

      _updatePendingFileMessage(
        messageId: pendingId,
        path: filePath,
        remote: remoteUrl,
        name: name,
        size: size,
        status: MediaSendStatus.sending,
        progress: 90,
        replaceInEngine: true,
      );

      final sent = await sendFile(
        filePath,
        size,
        name,
        remoteUrl: remoteUrl,
        onProgress: (progress) {
          _updatePendingFileMessage(
            messageId: pendingId,
            path: filePath,
            remote: remoteUrl,
            name: name,
            size: size,
            status: MediaSendStatus.sending,
            progress: mapFileImSendProgress(progress),
          );
        },
        pushSavedMessage: false,
      );

      if (!sent) {
        _markPendingFileFailed(
          messageId: pendingId,
          path: filePath,
          name: name,
          size: size,
        );
      }
    } catch (_) {
      _markPendingFileFailed(
        messageId: pendingId,
        path: filePath,
        name: name,
        size: size,
      );
      AppToast.show(_tr('chat_detail_send_failed'));
    }
  }

  ChatDetailMessage _pendingFileMessage({
    required String messageId,
    required String path,
    required String name,
    required int size,
    required MediaSendStatus status,
    required int progress,
    String? remote,
  }) {
    return ChatDetailMessage(
      messageId: messageId,
      kind: ChatDetailMessageKind.file,
      isMe: true,
      sentTime: DateTime.now().millisecondsSinceEpoch,
      fileName: name,
      fileSize: formatFileSize(size),
      path: path,
      remote: remote,
      mediaSendStatus: status,
      mediaSendProgress: progress.clamp(0, 100).toInt(),
    );
  }

  void _updatePendingFileMessage({
    required String messageId,
    required String path,
    required String name,
    required int size,
    required MediaSendStatus status,
    required int progress,
    String? remote,
    bool replaceInEngine = false,
  }) {
    if (!engine.containsId(messageId)) {
      return;
    }

    final next = _pendingFileMessage(
      messageId: messageId,
      path: path,
      remote: remote,
      name: name,
      size: size,
      status: status,
      progress: progress,
    );

    final notifier = _pendingFileMessageNotifiers[messageId];
    if (notifier == null) {
      _pendingFileMessageNotifiers[messageId] = ValueNotifier(next);
    } else if (_shouldPublishPendingFileMessage(notifier.value, next)) {
      notifier.value = next;
    }

    if (replaceInEngine) {
      engine.replace(next);
    }
  }

  bool _shouldPublishPendingFileMessage(
    ChatDetailMessage previous,
    ChatDetailMessage next,
  ) {
    return shouldNotifyFileSendProgress(
          previousProgress: previous.mediaSendProgress,
          nextProgress: next.mediaSendProgress,
          statusChanged: previous.mediaSendStatus != next.mediaSendStatus,
        ) ||
        previous.path != next.path ||
        previous.remote != next.remote ||
        previous.fileName != next.fileName ||
        previous.fileSize != next.fileSize;
  }

  void _markPendingFileFailed({
    required String messageId,
    required String path,
    required String name,
    required int size,
  }) {
    _removePendingFileRemoteMappings(messageId);
    _updatePendingFileMessage(
      messageId: messageId,
      path: path,
      name: name,
      size: size,
      status: MediaSendStatus.failed,
      progress: 0,
      replaceInEngine: true,
    );
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

  Future<void> handleFileTap(ChatDetailMessage message) async {
    if (message.kind != ChatDetailMessageKind.file ||
        message.mediaSendStatus != MediaSendStatus.sent) {
      return;
    }

    final messageId = message.messageId;
    final currentState = _fileDownloadNotifier(messageId).value;
    if (currentState.status == FileDownloadStatus.downloading) {
      return;
    }

    final existingPath =
        _existingLocalFilePath(currentState.localPath) ??
        _existingLocalFilePath(message.path);
    if (existingPath != null) {
      _setFileDownloadState(
        messageId,
        FileDownloadState(
          status: FileDownloadStatus.downloaded,
          progress: 100,
          localPath: existingPath,
        ),
      );
      await _openLocalFile(existingPath);
      return;
    }

    final remoteUrl = message.remote?.trim();
    if (remoteUrl == null || remoteUrl.isEmpty) {
      _markFileDownloadFailed(messageId);
      AppToast.show(_tr('common_download_failed'));
      return;
    }

    final targetPath = await _downloadPathForMessage(message);
    final downloadedPath = _existingLocalFilePath(targetPath);
    if (downloadedPath != null) {
      _setFileDownloadState(
        messageId,
        FileDownloadState(
          status: FileDownloadStatus.downloaded,
          progress: 100,
          localPath: downloadedPath,
        ),
      );
      await _openLocalFile(downloadedPath);
      return;
    }

    await _downloadFileMessage(
      message: message,
      remoteUrl: remoteUrl,
      targetPath: targetPath,
    );
  }

  ValueNotifier<FileDownloadState> _fileDownloadNotifier(String messageId) {
    return _fileDownloadNotifiers.putIfAbsent(
      messageId,
      () => ValueNotifier(const FileDownloadState()),
    );
  }

  void _setFileDownloadState(String messageId, FileDownloadState state) {
    _fileDownloadNotifier(messageId).value = state;
  }

  Future<void> _downloadFileMessage({
    required ChatDetailMessage message,
    required String remoteUrl,
    required String targetPath,
  }) async {
    final messageId = message.messageId;
    _setFileDownloadState(
      messageId,
      const FileDownloadState(status: FileDownloadStatus.downloading),
    );

    try {
      await File(targetPath).parent.create(recursive: true);
      await _downloadDio.download(
        remoteUrl,
        targetPath,
        onReceiveProgress: (received, total) {
          _setFileDownloadState(
            messageId,
            FileDownloadState(
              status: FileDownloadStatus.downloading,
              progress: mapFileDownloadProgress(
                received: received,
                total: total,
              ),
              localPath: targetPath,
            ),
          );
        },
      );

      if (!File(targetPath).existsSync()) {
        _markFileDownloadFailed(messageId);
        AppToast.show(_tr('common_download_failed'));
        return;
      }

      _setFileDownloadState(
        messageId,
        FileDownloadState(
          status: FileDownloadStatus.downloaded,
          progress: 100,
          localPath: targetPath,
        ),
      );
      await _openLocalFile(targetPath);
    } catch (e) {
      debugPrint('file download failed: $e');
      _markFileDownloadFailed(messageId);
      AppToast.show(_tr('common_download_failed'));
    }
  }

  Future<String> _downloadPathForMessage(ChatDetailMessage message) async {
    final dir = await getApplicationDocumentsDirectory();
    return buildChatFileDownloadPath(
      directoryPath: '${dir.path}/chat_files',
      messageId: message.messageId,
      remoteUrl: message.remote,
      fileName: message.fileName,
    );
  }

  String? _existingLocalFilePath(String? path) {
    if (!isUsableLocalFilePath(path)) {
      return null;
    }

    try {
      final uri = Uri.tryParse(path!.trim());
      final filePath = uri != null && uri.scheme == 'file'
          ? uri.toFilePath()
          : path.trim();
      return File(filePath).existsSync() ? filePath : null;
    } catch (_) {
      return null;
    }
  }

  void _markFileDownloadFailed(String messageId) {
    _setFileDownloadState(
      messageId,
      const FileDownloadState(status: FileDownloadStatus.failed),
    );
  }

  Future<void> _openLocalFile(String path) async {
    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        AppToast.show(_tr('common_download_failed'));
      }
    } catch (e) {
      debugPrint('open file failed: $e');
      AppToast.show(_tr('common_download_failed'));
    }
  }

  bool _replaceExistingMediaMessage(ChatDetailMessage incoming) {
    if (incoming.kind != ChatDetailMessageKind.image &&
        incoming.kind != ChatDetailMessageKind.video &&
        incoming.kind != ChatDetailMessageKind.file) {
      return false;
    }

    if (engine.containsId(incoming.messageId)) {
      return false;
    }

    if (incoming.kind == ChatDetailMessageKind.video) {
      final pendingId = _pendingVideoMessageIdForRemote(incoming.remote);
      if (pendingId != null && engine.containsId(pendingId)) {
        _clearPendingVideoMessageState(pendingId);
        engine.replaceWhere(
          (existing) => existing.messageId == pendingId,
          incoming,
        );
        return true;
      }
    }

    if (incoming.kind == ChatDetailMessageKind.file) {
      final pendingId = _pendingFileMessageIdForRemote(incoming.remote);
      if (pendingId != null && engine.containsId(pendingId)) {
        _clearPendingFileMessageState(pendingId);
        engine.replaceWhere(
          (existing) => existing.messageId == pendingId,
          incoming,
        );
        return true;
      }
    }

    final match = _firstMessageWhere(
      (existing) => _isSameMediaMessage(existing, incoming),
    );
    if (match == null) {
      return false;
    }

    _clearPendingVideoMessageState(match.messageId);
    _clearPendingFileMessageState(match.messageId);

    engine.replaceWhere(
      (existing) => _isSameMediaMessage(existing, incoming),
      incoming,
    );
    return true;
  }

  ChatDetailMessage? _firstMessageWhere(
    bool Function(ChatDetailMessage message) test,
  ) {
    for (final message in messages) {
      if (test(message)) {
        return message;
      }
    }

    return null;
  }

  void _registerPendingVideoRemote({
    required String messageId,
    required String? remote,
  }) {
    final key = normalizeVideoRemoteUrl(remote);
    if (key == null) {
      return;
    }

    _pendingVideoMessageIdsByRemote[key] = messageId;
  }

  String? _pendingVideoMessageIdForRemote(String? remote) {
    final key = normalizeVideoRemoteUrl(remote);
    if (key == null) {
      return null;
    }

    return _pendingVideoMessageIdsByRemote[key];
  }

  void _clearPendingVideoMessageState(String messageId) {
    final notifier = _pendingVideoMessageNotifiers.remove(messageId);
    notifier?.dispose();
    _removePendingVideoRemoteMappings(messageId);
  }

  void _removePendingVideoRemoteMappings(String messageId) {
    _pendingVideoMessageIdsByRemote.removeWhere((key, value) {
      return value == messageId;
    });
  }

  void _registerPendingFileRemote({
    required String messageId,
    required String? remote,
  }) {
    final key = normalizeFileRemoteUrl(remote);
    if (key == null) {
      return;
    }

    _pendingFileMessageIdsByRemote[key] = messageId;
  }

  String? _pendingFileMessageIdForRemote(String? remote) {
    final key = normalizeFileRemoteUrl(remote);
    if (key == null) {
      return null;
    }

    return _pendingFileMessageIdsByRemote[key];
  }

  void _clearPendingFileMessageState(String messageId) {
    final notifier = _pendingFileMessageNotifiers.remove(messageId);
    notifier?.dispose();
    _removePendingFileRemoteMappings(messageId);
  }

  void _removePendingFileRemoteMappings(String messageId) {
    _pendingFileMessageIdsByRemote.removeWhere((key, value) {
      return value == messageId;
    });
  }

  bool _replaceExistingMessage(ChatDetailMessage incoming) {
    if (engine.containsId(incoming.messageId)) {
      engine.replace(incoming);
      return true;
    }

    final hasRawMatch = messages.any(
      (existing) => _isSameRawMessage(existing, incoming),
    );
    if (hasRawMatch) {
      engine.replaceWhere(
        (existing) => _isSameRawMessage(existing, incoming),
        incoming,
      );
      return true;
    }

    if (incoming.kind == ChatDetailMessageKind.image ||
        incoming.kind == ChatDetailMessageKind.video ||
        incoming.kind == ChatDetailMessageKind.file) {
      return _replaceExistingMediaMessage(incoming);
    }

    return false;
  }

  bool _isSameRawMessage(
    ChatDetailMessage existing,
    ChatDetailMessage incoming,
  ) {
    final oldRaw = existing.extra;
    final newRaw = incoming.extra;
    if (oldRaw is! RCIMIWMessage || newRaw is! RCIMIWMessage) {
      return false;
    }

    if (oldRaw.conversationType != newRaw.conversationType ||
        oldRaw.targetId != newRaw.targetId ||
        oldRaw.channelId != newRaw.channelId ||
        oldRaw.senderUserId != newRaw.senderUserId ||
        oldRaw.messageType != newRaw.messageType) {
      return false;
    }

    final oldUid = oldRaw.messageUId;
    final newUid = newRaw.messageUId;
    if (oldUid != null &&
        oldUid.isNotEmpty &&
        newUid != null &&
        newUid.isNotEmpty &&
        oldUid == newUid) {
      return true;
    }

    final oldId = oldRaw.messageId;
    final newId = newRaw.messageId;
    return oldId != null &&
        oldId > 0 &&
        newId != null &&
        newId > 0 &&
        oldId == newId;
  }

  bool _isSameMediaMessage(
    ChatDetailMessage existing,
    ChatDetailMessage incoming,
  ) {
    if (existing.kind != incoming.kind) {
      return false;
    }

    if (existing.mediaSendStatus != MediaSendStatus.sent) {
      final remoteMatches = incoming.kind == ChatDetailMessageKind.file
          ? isSamePendingFileRemote(
              pendingRemote: existing.remote,
              incomingRemote: incoming.remote,
            )
          : isSamePendingVideoRemote(
              pendingRemote: existing.remote,
              incomingRemote: incoming.remote,
            );
      if (remoteMatches) {
        return true;
      }

      final oldPath = existing.path?.trim();
      final newPath = incoming.path?.trim();
      if (oldPath != null &&
          oldPath.isNotEmpty &&
          newPath != null &&
          newPath.isNotEmpty &&
          oldPath == newPath) {
        return true;
      }

      final oldThumbnail = existing.thumbnailBase64String;
      final newThumbnail = incoming.thumbnailBase64String;
      return oldThumbnail != null &&
          oldThumbnail.isNotEmpty &&
          newThumbnail != null &&
          newThumbnail.isNotEmpty &&
          oldThumbnail == newThumbnail;
    }

    final oldRaw = existing.extra;
    final newRaw = incoming.extra;
    if (oldRaw is! RCIMIWMediaMessage || newRaw is! RCIMIWMediaMessage) {
      return false;
    }

    if (oldRaw.conversationType != newRaw.conversationType ||
        oldRaw.targetId != newRaw.targetId ||
        oldRaw.channelId != newRaw.channelId ||
        oldRaw.senderUserId != newRaw.senderUserId ||
        oldRaw.messageType != newRaw.messageType) {
      return false;
    }

    final oldPath = _mediaPathForMatch(oldRaw);
    final newPath = _mediaPathForMatch(newRaw);
    if (oldPath != null && newPath != null && oldPath == newPath) {
      return true;
    }

    if (existing.thumbnailBase64String != null &&
        existing.thumbnailBase64String!.isNotEmpty &&
        existing.thumbnailBase64String == incoming.thumbnailBase64String) {
      return true;
    }

    final oldTime = oldRaw.sentTime ?? oldRaw.receivedTime;
    final newTime = newRaw.sentTime ?? newRaw.receivedTime;
    return (oldPath == null || newPath == null) &&
        oldTime != null &&
        newTime != null &&
        (oldTime - newTime).abs() <= const Duration(seconds: 10).inMilliseconds;
  }

  String? _mediaPathForMatch(RCIMIWMediaMessage message) {
    final local = message.local?.trim();
    if (local != null && local.isNotEmpty) {
      return local;
    }

    final remote = message.remote?.trim();
    if (remote != null && remote.isNotEmpty) {
      return remote;
    }

    return null;
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
    final media = isVideo ? 'video' : 'voice';
    final displayName = sessionName.isNotEmpty ? sessionName : targetId;
    final encoded = Uri.encodeComponent(displayName);
    final encodedTargetId = Uri.encodeQueryComponent(targetId);

    if (args?.isGroup ?? false) {
      isMenuExpanded = false;
      notifyListeners();
      final started = await RongCallManager().startGroupCall(
        targetId: targetId,
        displayName: displayName,
        mediaType: isVideo
            ? RCCallMediaType.audio_video
            : RCCallMediaType.audio,
      );
      if (!started) return;
      context?.push('/chat-group-$media/$encoded?targetId=$encodedTargetId');
      return;
    }

    isMenuExpanded = false;
    notifyListeners();
    final started = await RongCallManager().startPrivateCall(
      targetId: targetId,
      displayName: displayName,
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
