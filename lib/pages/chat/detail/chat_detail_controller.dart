import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../../modules/im/message/base/im_message.dart';
import '../../../modules/im/message/send/im_sender.dart';
import '../../../modules/manager/voice_player_manager.dart';
import '../../../modules/manager/voice_record_manager.dart';
import '../../../util/media_handle_util.dart';
import '../../../widgets/chat/voice_record_overlay.dart';
import '../../../widgets/common/app_media_gallery.dart';
import '../../../widgets/common/app_toast.dart';

class ChatDetailController {
  ChatDetailController(this.args);

  final ChatSessionArgs? args;

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
    onUpdate: () => notify?.call(),
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

  /// =========================
  /// UI notify
  /// =========================
  VoidCallback? notify;

  /// =========================
  /// init
  /// =========================
  void init(VoidCallback refresh) {
    notify = refresh;

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
  }

  void dispose() {
    _subscribeEventManager.unsubscribe([args!.targetId]);

    inputController.dispose();

    engine.dispose();

    _messageSub?.cancel();

    _eventSub?.cancel();

    _conversationChangeSub?.cancel();
  }

  /// =========================
  /// input
  /// =========================
  void _initInputListener() {
    inputController.addListener(() {
      final empty = inputController.text.trim().isEmpty;

      if (empty != isInputEmpty) {
        isInputEmpty = empty;

        notify?.call();
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

    notify?.call();

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

      notify?.call();
    }
  }

  Future<List<ChatDetailMessage>> _loadMessagesAroundAnchor() async {
    if (args == null || args!.anchorSentTime == null) {
      return [];
    }

    isLoading = true;

    notify?.call();

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

      notify?.call();
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

    notify?.call();

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

    notify?.call();
  }

  Future<bool> loadMessagesAroundTime(int sentTime) async {
    if (args == null || isLoadingMore) {
      return false;
    }

    isLoadingMore = true;
    notify?.call();

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
      notify?.call();
    }
  }

  Future<void> deleteMessage(ChatDetailMessage message) async {
    final raw = message.extra;
    if (raw is! RCIMIWMessage) {
      AppToast.show('删除失败');
      return;
    }

    final success = await _messageManager.deleteLocalMessages(messages: [raw]);

    if (!success) {
      AppToast.show('删除失败');
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
    _conversationChangeSub = ImConversationManager().changeStream
        .listen((ConversationChangeEvent event){
              final conversation = event.conversation;
              if (conversation == null) return;
              if (conversation.targetId != args?.targetId) return;
              if (event.type == ConversationChangeType.delete){
                context?.go('/chat');
              }
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
    notify?.call();
  }

  void clearQuote() {
    quotedMessage = null;
    quotedText = null;
    notify?.call();
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
        notify?.call();
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

      notify?.call();
    };

    voiceManager.onCancel = () {
      isRecording = false;

      notify?.call();

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
    notify?.call();
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

    notify?.call();
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

    notify?.call();
  }

  void toggleVoice() {
    FocusScope.of(context!).unfocus();

    isVoiceMode = !isVoiceMode;

    isMenuExpanded = false;

    notify?.call();
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
      notify;
      return;
    }

    final encoded = Uri.encodeComponent(sessionName);
    final media = isVideo ? 'video' : 'voice';

    isMenuExpanded = false;
    notify;
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
