import 'dart:async';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:paracosm/modules/im/manager/im_message_manager.dart';
import 'package:paracosm/modules/im/manager/im_send_manager.dart';
import 'package:paracosm/modules/im/manager/im_subscribe_event_manager.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:paracosm/pages/chat/chat_detail_message_mapper.dart';
import 'package:paracosm/pages/chat/chat_session_args.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class ChatDetailController {
  ChatDetailController(this.args);

  final ChatSessionArgs? args;
  BuildContext? context;
  final ImMessageManager _messageManager = ImMessageManager();
  final ImSubscribeEventManager _subscribeEventManager = ImSubscribeEventManager();

  final inputController = TextEditingController();

  bool hasMore = true;
  bool isLoadingMore = false;
  int? _oldestTime;

  /// 状态
  bool isInputEmpty = true;
  bool isMenuExpanded = false;
  bool isVoiceMode = false;
  bool isRecording = false;
  bool isCancelling = false;
  bool isLoading = false;
  bool isOnline = false;

  List<ChatDetailMessage> messages = [];

  ToastFuture? voiceToast;

  late StreamSubscription<RCIMIWMessage> _messageSub;
  late StreamSubscription<Map<String, bool>> _onlineSub;

  VoidCallback? notify;
  final ScrollController scrollController = ScrollController();

  bool isAtBottom = true;     // 是否在底部
  double _oldMaxScroll = 0;   // 用于防跳

  void init(VoidCallback refresh) {
    notify = refresh;

    inputController.addListener(() {
      final empty = inputController.text.trim().isEmpty;
      if (empty != isInputEmpty) {
        isInputEmpty = empty;
        notify?.call();
      }
    });

    _loadMessages().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
    });
    _subscribeMessages();

    /// ⭐等UI渲染后滚到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });

  }

  void dispose() {
    _subscribeEventManager.unsubscribe([args!.targetId]);

    inputController.dispose();
    _messageSub.cancel();
    _onlineSub.cancel();
  }

  /// =========================
  /// 消息加载
  /// =========================
  Future<void> _loadMessages() async {
    if (args == null) return;

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
      final list = result.reversed.toList();

      if (list.isNotEmpty) {
        _oldestTime = list.first.sentTime;
      }

      messages = ChatDetailMessageMapper.mapMessages(list);
    } catch (e) {
      print('获取历史消息 $e');
    }

    isLoading = false;
    notify?.call();
  }
  /// =========================
  /// 下拉加载更多
  /// =========================
  Future<void> loadMoreMessages() async {
    if (args == null) return;
    if (isLoadingMore || !hasMore) return;
    if (_oldestTime == null) return;

    isLoadingMore = true;
    notify?.call();

    try {
      final result = await _messageManager.getMessages(
        type: args!.conversationType,
        targetId: args!.targetId,
        sentTime: _oldestTime!, // ⭐关键：用最早时间继续往前查
        order: RCIMIWTimeOrder.before,
        policy: RCIMIWMessageOperationPolicy.localRemote,
      );

      final list = result.reversed.toList();

      if (list.isEmpty) {
        hasMore = false;
      } else {
        _oldestTime = list.first.sentTime;

        final mapped =
        ChatDetailMessageMapper.mapMessages(list);

        final oldMax =
            scrollController.position.maxScrollExtent;

        final oldOffset = scrollController.offset;
        /// ⭐ 去重 + 插入顶部
        messages = [...mapped, ...messages];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!scrollController.hasClients) return;

          final newMax =
              scrollController.position.maxScrollExtent;

          final diff = newMax - oldMax;

          scrollController.jumpTo(oldOffset + diff);
        });
      }
    } catch (e) {
      print('加载更多失败: $e');
    }

    isLoadingMore = false;
    notify?.call();
  }

  /// =========================
  /// 消息订阅
  /// =========================
  void _subscribeMessages() {
    _messageSub = _messageManager.messageStream.listen((message) {
      if (args == null) return;

      if (message.targetId != args!.targetId) return;
      if (message.conversationType != args!.conversationType) return;

      final mapped = ChatDetailMessageMapper.mapMessages([message]);
      if (mapped.isEmpty) return;
      messages = [...messages, ...mapped];
      notify?.call();
      if (isAtBottom) {
        scrollToBottom(animate: true);
      }
    });

    if (args?.isGroup == true) return;
    _onlineSub = _subscribeEventManager.stream.listen((onlineMap) {
      isOnline = onlineMap[args!.targetId] ?? false;
      notify?.call();
    });
    _subscribeEventManager.subscribeOnlineStatus([args!.targetId]);

  }

  /// =========================
  /// 发送消息
  /// =========================
  Future<void> sendText() async {
    final text = inputController.text.trim();
    if (args == null || text.isEmpty) return;

    await ImSendManager.instance.sendText(
      type: args!.conversationType,
      targetId: args!.targetId,
      content: text,
    );

    inputController.clear();
  }

  void listenScroll() {
    scrollController.addListener(() {
      if (!scrollController.hasClients) return;

      final position = scrollController.position;

      isAtBottom = position.pixels >=
          position.maxScrollExtent - 100;
    });
  }

  void scrollToBottom({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      final pos = scrollController.position.maxScrollExtent;

      if (animate) {
        scrollController.animateTo(
          pos,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        scrollController.jumpTo(pos);
      }
    });
  }

  /// =========================
  /// UI操作
  /// =========================
  void toggleMenu() {
    FocusScope.of(context!).unfocus();
    isMenuExpanded = !isMenuExpanded;
    isVoiceMode = false;
    // print('isMenuExpanded---$isMenuExpanded');
    notify?.call();
  }

  void toggleVoice() {
    FocusScope.of(context!).unfocus();
    isVoiceMode = !isVoiceMode;
    isMenuExpanded = false;
    notify?.call();
  }

  void toggleAction() {
    if (isInputEmpty){
      FocusScope.of(context!).unfocus();
    }
    isInputEmpty ? toggleMenu() : sendText();
  }

  void toggleAlbum() {
    if (isInputEmpty){
      FocusScope.of(context!).unfocus();
    }
    isInputEmpty ? toggleMenu() : sendText();
  }

}