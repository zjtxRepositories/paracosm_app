import 'dart:async';
import 'package:flutter/material.dart';
import 'package:paracosm/modules/im/manager/im_message_manager.dart';
import 'package:paracosm/modules/im/manager/im_subscribe_event_manager.dart';
import 'package:paracosm/modules/im/message/text_message.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:paracosm/pages/chat/chat_detail_message_mapper.dart';
import 'package:paracosm/pages/chat/chat_session_args.dart';
import 'package:paracosm/pages/chat/detail/scroll_engine.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import '../../../modules/im/message/send/im_sender.dart';

class ChatDetailController {
  ChatDetailController(this.args);

  final ChatSessionArgs? args;

  BuildContext? context;

  final ImMessageManager _messageManager = ImMessageManager();
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

  int? _oldestTime;

  /// =========================
  /// Stream
  /// =========================
  StreamSubscription<RCIMIWMessage>? _messageSub;
  StreamSubscription<Map<String, bool>>? _onlineSub;

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

    _loadMessages().then((list) {
      engine.merge(list);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        engine.onFirstLoaded();
      });
    });

    _subscribeMessages();
  }

  void dispose() {
    _subscribeEventManager.unsubscribe([args!.targetId]);

    inputController.dispose();
    engine.dispose();

    _messageSub?.cancel();
    _onlineSub?.cancel();
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
  List<ChatDetailMessage> get messages =>
      engine.list.cast<ChatDetailMessage>();

  /// =========================
  /// 初始加载
  /// =========================
  Future<List<ChatDetailMessage>> _loadMessages() async {
    if (args == null) return [];

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

      final list = ChatDetailMessageMapper.mapMessages(result.reversed.toList());

      if (list.isNotEmpty) {
        _oldestTime = list.first.sentTime;
      }

      return list;
    } catch (e) {
      debugPrint("load error: $e");
      return [];
    } finally {
      isLoading = false;
      notify?.call();
    }
  }

  /// =========================
  /// 加载更多（完全交给 engine）
  /// =========================
  Future<void> loadMoreMessages() async {
    if (args == null) return;
    if (isLoadingMore || !hasMore || _oldestTime == null) return;

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

      final list =
      ChatDetailMessageMapper.mapMessages(result.reversed.toList());

      if (list.isEmpty) {
        hasMore = false;
      } else {
        _oldestTime = list.first.sentTime;

        /// ⭐ 核心：只交给 engine
        engine.prepend(list);
      }
    } catch (e) {
      debugPrint("load more error: $e");
    }

    isLoadingMore = false;
    notify?.call();
  }

  /// =========================
  /// 消息监听
  /// =========================
  void _subscribeMessages() {
    _messageSub = _messageManager.messageStream.listen((message) {
      if (args == null) return;

      if (message.targetId != args!.targetId) return;
      if (message.conversationType != args!.conversationType) return;

      final msg = ChatDetailMessageMapper.mapMessage(message);

      /// ⭐ 核心：统一入口
      engine.append(msg);

      if (engine.isAtBottom) {
        engine.scrollToBottom();
      }
    });

    /// 在线状态
    if (args?.isGroup != true) {
      _onlineSub = _subscribeEventManager.stream.listen((map) {
        isOnline = map[args!.targetId] ?? false;
        notify?.call();
      });

      _subscribeEventManager.subscribeOnlineStatus([args!.targetId]);
    }
  }

  /// =========================
  /// 发送消息
  /// =========================
  Future<void> sendText() async {
    final text = inputController.text.trim();
    if (args == null || text.isEmpty) return;

    await ImSender.instance.send(
      message: TextMessage(
        conversationType: args!.conversationType,
        targetId: args!.targetId,
        content: text,
      ),
    );

    inputController.clear();
  }

  /// =========================
  /// UI 操作
  /// =========================
  void toggleMenu() {
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
}