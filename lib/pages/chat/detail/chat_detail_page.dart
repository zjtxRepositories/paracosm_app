import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/media_item.dart';
import '../../../modules/im/listener/im_data_center.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../tool/keyboard_detector.dart';
import '../../../widgets/base/app_localizations.dart';
import '../../../widgets/base/app_page.dart';
import '../../../widgets/chat/chat_detail_header.dart';
import '../../../widgets/chat/chat_forward_target_modal.dart';
import '../../../widgets/chat/chat_input_bar.dart';
import '../../../widgets/chat/chat_message_contents.dart';
import '../../../widgets/chat/chat_message_context_menu.dart';
import '../../../widgets/chat/chat_message_item.dart';
import '../../../widgets/chat/chat_more_panel.dart';
import '../../../widgets/common/app_checkbox.dart';
import '../../../widgets/common/app_modal.dart';
import '../../../widgets/common/app_toast.dart';
import '../chat_detail_message.dart';
import '../chat_session_args.dart';
import 'chat_detail_controller.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class ChatDetailPage extends StatefulWidget {
  final ChatSessionArgs? sessionArgs;
  final String fallbackName;

  const ChatDetailPage({super.key, required ChatSessionArgs this.sessionArgs})
    : fallbackName = '';

  const ChatDetailPage.missingArgs({super.key, required this.fallbackName})
    : sessionArgs = null;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  late final ChatDetailController controller;
  final Map<String, GlobalKey> _messageKeys = {};
  bool _didScrollToAnchor = false;
  String? _flashMessageId;
  int _flashToken = 0;
  bool _isSelectingMessages = false;
  final Set<String> _selectedMessageIds = {};

  @override
  void initState() {
    super.initState();
    controller = ChatDetailController(widget.sessionArgs);
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller.context = context;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return AppPage(
          isCustomHeader: true,
          isAddBottomMargin: false,
          onBeforeBack: _isSelectingMessages
              ? () async {
                  _exitSelectionMode();
                  return false;
                }
              : null,
          renderCustomHeader: _isSelectingMessages
              ? _buildSelectionHeader()
              : ChatDetailHeader(
                  name: controller.sessionName,
                  isGroup: controller.isGroupSession,
                  avatar: controller.headerAvatar,
                  targetId: controller.targetId,
                  isOnline: controller.isOnline,
                  onMoreTap: controller.navigateToSettings,
                  onAvatarTap: controller.navigateToProfile,
                ),
          child: KeyboardDetector(
            builder: (keyboardHeight) {
              if (!_isSelectingMessages &&
                  keyboardHeight > 0 &&
                  controller.engine.isAtBottom) {
                controller.engine.scrollToBottom();
              }
              return Column(
                children: [
                  Expanded(child: _buildMessageList()),
                  if (_isSelectingMessages)
                    _buildSelectionActionBar()
                  else ...[
                    ChatInputBar(
                      controller: controller.inputController,
                      isVoiceMode: controller.isVoiceMode,
                      isRecording: controller.isRecording,
                      isCancelling: controller.isCancelling,
                      isMenuExpanded: controller.isMenuExpanded,
                      isInputEmpty: controller.isInputEmpty,
                      quoteText: controller.quotedText,
                      onClearQuote: controller.clearQuote,
                      onToggleVoiceMode: controller.toggleVoice,
                      onTextFieldTap: () {
                        if (controller.isMenuExpanded) {
                          controller.isMenuExpanded = false;
                          setState(() {});
                        }
                      },
                      onActionTap: controller.toggleAction,
                      onVoiceLongPressStart: (d) => controller.voiceStart(),
                      onVoiceLongPressMoveUpdate: (d) =>
                          controller.voiceUpdate(d),
                      onVoiceLongPressEnd: (d) => controller.voiceEnd(),
                    ),
                    if (controller.isMenuExpanded)
                      ChatMorePanel(
                        onItemTap: (item) async {
                          switch (item.type) {
                            case ChatMoreAction.album:
                              controller.toggleAlbum();
                            case ChatMoreAction.camera:
                              controller.toggleCamera();
                            case ChatMoreAction.videoCall:
                              await controller.openCallPage(isVideo: true);
                            case ChatMoreAction.audioCall:
                              await controller.openCallPage(isVideo: false);
                            case ChatMoreAction.redbag:
                              // TODO: Handle this case.
                              throw UnimplementedError();
                            case ChatMoreAction.file:
                              controller.toggleFile();
                          }
                        },
                      ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectionHeader() {
    final count = _selectedMessages.length;

    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.grey200)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _exitSelectionMode,
            child: Text(
              '取消',
              style: AppTextStyles.body.copyWith(
                color: AppColors.grey900,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '已选择 $count 条',
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.grey900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 64),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (widget.sessionArgs == null) {
      return const Center(child: Text('缺少会话参数'));
    }

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    _scheduleAnchorScroll();
    return NotificationListener<ScrollNotification>(
      onNotification: (scroll) {
        if (scroll.metrics.pixels <= 100 && controller.messages.isNotEmpty) {
          controller.loadMoreMessages();
        }
        return false;
      },
      child: ListView.builder(
        controller: controller.engine.scrollController,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        itemCount: controller.messages.length,
        itemBuilder: (context, index) {
          final message = controller.messages[index];
          final node = _buildMessageNode(message);
          return KeyedSubtree(
            key: _keyForMessage(message.messageId),
            child: _isSelectingMessages
                ? _buildSelectableMessageNode(message, node)
                : node,
          );
        },
      ),
    );
  }

  Widget _buildSelectableMessageNode(ChatDetailMessage message, Widget child) {
    if (!_canSelectMessage(message)) {
      return child;
    }

    final selected = _selectedMessageIds.contains(message.messageId);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggleSelectedMessage(message),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 32, child: AppCheckbox(value: selected)),
          Expanded(child: IgnorePointer(child: child)),
        ],
      ),
    );
  }

  GlobalKey _keyForMessage(String messageId) {
    return _messageKeys.putIfAbsent(messageId, GlobalKey.new);
  }

  List<ChatDetailMessage> get _selectedMessages {
    return controller.messages
        .where(
          (message) =>
              _selectedMessageIds.contains(message.messageId) &&
              _canSelectMessage(message),
        )
        .toList();
  }

  Widget _buildSelectionActionBar() {
    final hasSelected = _selectedMessages.isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.grey200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSelectionAction(
                icon: 'assets/images/chat/delete-msg.png',
                label: '删除',
                enabled: hasSelected,
                onTap: _confirmDeleteSelectedMessages,
              ),
            ),
            Expanded(
              child: _buildSelectionAction(
                icon: 'assets/images/chat/share.png',
                label: '转发',
                enabled: hasSelected,
                onTap: _forwardSelectedMessages,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionAction({
    required String icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final color = enabled ? AppColors.grey900 : AppColors.grey400;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(icon, width: 24, height: 24, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _startSelectionMode(ChatDetailMessage message) {
    if (!_canSelectMessage(message)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      controller.isMenuExpanded = false;
      controller.isVoiceMode = false;
      _isSelectingMessages = true;
      _selectedMessageIds
        ..clear()
        ..add(message.messageId);
    });
  }

  void _exitSelectionMode() {
    if (!_isSelectingMessages) {
      return;
    }

    setState(() {
      _isSelectingMessages = false;
      _selectedMessageIds.clear();
    });
  }

  void _toggleSelectedMessage(ChatDetailMessage message) {
    if (!_canSelectMessage(message)) {
      return;
    }

    setState(() {
      if (_selectedMessageIds.contains(message.messageId)) {
        _selectedMessageIds.remove(message.messageId);
      } else {
        _selectedMessageIds.add(message.messageId);
      }
    });
  }

  Future<void> _confirmDeleteSelectedMessages() async {
    final selectedMessages = _selectedMessages;
    if (selectedMessages.isEmpty) {
      return;
    }

    await AppModal.show(
      context,
      title: '删除消息',
      description: '确定删除选中的 ${selectedMessages.length} 条消息吗？',
      confirmText: '删除',
      cancelText: '取消',
      confirmColor: AppColors.error,
      confirmWidth: 161,
      cancelWidth: 161,
      cancelBorder: const BorderSide(color: AppColors.grey300),
      onConfirm: () async {
        Navigator.of(context, rootNavigator: true).pop();
        final success = await controller.deleteMessages(selectedMessages);
        if (!mounted) {
          return;
        }

        if (success) {
          _exitSelectionMode();
        }
      },
    );
  }

  Future<void> _forwardSelectedMessages() async {
    final selectedMessages = _selectedMessages;
    if (selectedMessages.isEmpty) {
      return;
    }

    final targets = await ChatForwardTargetModal.show(
      context,
      friends: ImDataCenter().friendListSnapshot,
      groups: ImDataCenter().groupListSnapshot,
    );

    if (!mounted || targets == null || targets.isEmpty) {
      return;
    }

    final success = await controller.forwardMessages(
      messages: selectedMessages,
      targets: targets,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _exitSelectionMode();
    }
  }

  Future<void> _forwardMessage(ChatDetailMessage message) async {
    final targets = await ChatForwardTargetModal.show(
      context,
      friends: ImDataCenter().friendListSnapshot,
      groups: ImDataCenter().groupListSnapshot,
    );

    if (!mounted || targets == null || targets.isEmpty) {
      return;
    }

    await controller.forwardMessage(message: message, targets: targets);
  }

  void _scheduleAnchorScroll() {
    final anchorMessageId = controller.anchorMessageId;
    if (_didScrollToAnchor || anchorMessageId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didScrollToAnchor) return;

      final targetContext = _messageKeys[anchorMessageId]?.currentContext;
      if (targetContext == null) return;

      _didScrollToAnchor = true;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.35,
      );
    });
  }

  Future<void> _jumpToQuotedMessage(ChatDetailMessage message) async {
    var target = _findQuotedMessage(message);
    if (target != null && await _scrollToMessage(target.messageId)) {
      return;
    }

    final quoteSentTime = message.quoteSentTime;
    if (quoteSentTime == null || quoteSentTime <= 0) {
      AppToast.show('消息未找到');
      return;
    }

    final loaded = await controller.loadMessagesAroundTime(quoteSentTime);
    if (!loaded) {
      AppToast.show('消息未找到');
      return;
    }

    if (!mounted) {
      return;
    }

    await _waitForNextFrame();
    if (!mounted) {
      return;
    }

    target = _findQuotedMessage(message);
    if (target != null && await _scrollToMessage(target.messageId)) {
      return;
    }

    AppToast.show('消息未找到');
  }

  ChatDetailMessage? _findQuotedMessage(ChatDetailMessage quoteMessage) {
    final quoteMessageUId = quoteMessage.quoteMessageUId;
    if (quoteMessageUId != null && quoteMessageUId.isNotEmpty) {
      final target = _findMessageByRaw(
        (raw) => raw.messageUId == quoteMessageUId,
      );
      if (target != null) {
        return target;
      }
    }

    final quoteRawMessageId = quoteMessage.quoteRawMessageId;
    if (quoteRawMessageId != null && quoteRawMessageId > 0) {
      final target = _findMessageByRaw(
        (raw) => raw.messageId != null && raw.messageId == quoteRawMessageId,
      );
      if (target != null) {
        return target;
      }
    }

    final quoteMessageId = quoteMessage.quoteMessageId;
    if (quoteMessageId != null && quoteMessageId.isNotEmpty) {
      final target = _findMessage((e) => e.messageId == quoteMessageId);
      if (target != null) {
        return target;
      }
    }

    final quoteSentTime = quoteMessage.quoteSentTime;
    final quoteSenderUserId = quoteMessage.quoteSenderUserId;
    final quoteMessageType = quoteMessage.quoteMessageType;
    if (quoteSentTime == null ||
        quoteSentTime <= 0 ||
        quoteSenderUserId == null ||
        quoteSenderUserId.isEmpty ||
        quoteMessageType == null) {
      return null;
    }

    return _findMessageByRaw((raw) {
      final rawTime = raw.sentTime ?? raw.receivedTime;
      return rawTime == quoteSentTime &&
          raw.senderUserId == quoteSenderUserId &&
          raw.messageType?.index == quoteMessageType;
    });
  }

  ChatDetailMessage? _findMessage(
    bool Function(ChatDetailMessage message) test,
  ) {
    for (final message in controller.messages) {
      if (test(message)) {
        return message;
      }
    }

    return null;
  }

  ChatDetailMessage? _findMessageByRaw(bool Function(RCIMIWMessage raw) test) {
    for (final message in controller.messages) {
      final raw = message.extra;
      if (raw is RCIMIWMessage && test(raw)) {
        return message;
      }
    }

    return null;
  }

  bool _hasQuoteLocator(ChatDetailMessage message) {
    return (message.quoteMessageUId?.isNotEmpty ?? false) ||
        (message.quoteRawMessageId != null && message.quoteRawMessageId! > 0) ||
        (message.quoteMessageId?.isNotEmpty ?? false) ||
        (message.quoteSentTime != null &&
            message.quoteSentTime! > 0 &&
            (message.quoteSenderUserId?.isNotEmpty ?? false) &&
            message.quoteMessageType != null);
  }

  Future<bool> _scrollToMessage(String messageId) async {
    var targetContext = _messageKeys[messageId]?.currentContext;
    if (targetContext != null) {
      await _ensureVisibleMessage(targetContext);
      return true;
    }

    final index = controller.messages.indexWhere(
      (e) => e.messageId == messageId,
    );
    if (index < 0) {
      return false;
    }

    final scrollController = controller.engine.scrollController;
    if (!scrollController.hasClients || controller.messages.length <= 1) {
      return false;
    }

    final maxExtent = scrollController.position.maxScrollExtent;
    final targetOffset = (maxExtent * index / (controller.messages.length - 1))
        .clamp(0.0, maxExtent)
        .toDouble();

    await scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
    await _waitForNextFrame();

    if (!mounted) {
      return false;
    }

    final visibleContext = _messageKeys[messageId]?.currentContext;
    if (visibleContext == null || !visibleContext.mounted) {
      return false;
    }

    await _ensureVisibleMessage(visibleContext);
    return true;
  }

  Future<void> _ensureVisibleMessage(BuildContext targetContext) async {
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: 0.35,
    );

    if (!mounted) {
      return;
    }

    final token = ++_flashToken;
    setState(() {
      _flashMessageId = _messageIdForContext(targetContext);
    });

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || token != _flashToken) {
        return;
      }

      setState(() {
        _flashMessageId = null;
      });
    });
  }

  String? _messageIdForContext(BuildContext targetContext) {
    for (final entry in _messageKeys.entries) {
      if (entry.value.currentContext == targetContext) {
        return entry.key;
      }
    }

    return null;
  }

  Future<void> _waitForNextFrame() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future;
  }

  Widget _buildMessageNode(ChatDetailMessage message) {
    switch (message.kind) {
      case ChatDetailMessageKind.timestamp:
        return _buildCenterTextMessage(message);
      case ChatDetailMessageKind.withdrawnNotice:
        return _buildCenterTextMessage(
          ChatDetailMessage(
            messageId: message.messageId,
            kind: message.kind,
            text: AppLocalizations.of(context)!.chatDetailWithdrewMessage,
            sentTime: message.sentTime,
            extra: message.extra,
          ),
        );
      case ChatDetailMessageKind.fm:
        return GestureDetector(
          onLongPressStart: (d) =>
              _showContextMenu(context, d.globalPosition, message),
          child: _buildCenterTextMessage(message),
        );
      default:
        return ChatMessageItem(
          isMe: message.isMe,
          isUnread: message.isUnread,
          showBubble: message.showBubble,
          isFlashing: _flashMessageId == message.messageId,
          readReceiptText: _readReceiptText(message),
          onLongPressStart: (d) =>
              _showContextMenu(context, d.globalPosition, message),
          child: _buildMessageContent(message),
        );
    }
  }

  String? _readReceiptText(ChatDetailMessage message) {
    if (!message.showReadReceipt || !message.isMe) {
      return null;
    }

    final localizations = AppLocalizations.of(context)!;
    if (controller.args?.conversationType == RCIMIWConversationType.group) {
      final count = message.groupReadCount;
      return count > 0
          ? localizations.chatDetailGroupReadCount(count)
          : localizations.chatDetailUnread;
    }

    return message.isRead
        ? localizations.chatDetailRead
        : localizations.chatDetailUnread;
  }

  Widget _buildCenterTextMessage(ChatDetailMessage message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          message.text ?? '',
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
        return ChatTextMessageContent(
          message: message.text ?? '',
          quoteText: message.quoteText,
          onQuoteTap: !_hasQuoteLocator(message)
              ? null
              : () => _jumpToQuotedMessage(message),
        );
      case ChatDetailMessageKind.voice:
        return buildVoiceItem(message, key: ValueKey(message.messageId));
      case ChatDetailMessageKind.fm:
        return ChatTextMessageContent(
          message: message.text ?? '',
          quoteText: message.quoteText,
          onQuoteTap: !_hasQuoteLocator(message)
              ? null
              : () => _jumpToQuotedMessage(message),
        );
      case ChatDetailMessageKind.image:
        return GestureDetector(
          onTap: () {
            final list = _buildImageMediaList();
            if (list.isEmpty) {
              return;
            }
            controller.openMediaViewer(
              list: list,
              index: _getImageIndex(message),
            );
          },
          child: ChatImageMessageContent(
            imagePath: message.imagePath ?? '',
            remoteUrl: message.remote,
            thumbnailBase64String: message.thumbnailBase64String,
          ),
        );
      case ChatDetailMessageKind.video:
        return _buildVideoMessageContent(message);
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
              ? () => _openCombineForwardDetail(raw)
              : null,
        );
      case ChatDetailMessageKind.call:
        return ChatCallMessageContent(
          text: message.text ?? '',
          isVideo: message.isVideo,
          isMe: message.isMe,
        );
      default:
        return ChatTextMessageContent(message: message.text ?? '');
    }
  }

  Widget _buildVideoMessageContent(ChatDetailMessage message) {
    final listenable = controller.pendingVideoMessageListenable(
      message.messageId,
    );
    if (listenable == null) {
      return _buildVideoGesture(message);
    }

    return ValueListenableBuilder<ChatDetailMessage>(
      valueListenable: listenable,
      builder: (context, pendingMessage, child) {
        return _buildVideoGesture(pendingMessage);
      },
    );
  }

  Widget _buildVideoGesture(ChatDetailMessage message) {
    return GestureDetector(
      onTap: message.mediaSendStatus == MediaSendStatus.sent
          ? () {
              var list = _buildVideoMediaList();
              if (list.isEmpty) {
                AppToast.show('视频暂不可预览');
                return;
              }
              var index = _getVideoIndex(message);
              if (index < 0) {
                final current = _videoMediaItem(message);
                if (current == null) {
                  AppToast.show('视频暂不可预览');
                  return;
                }
                list = [current];
                index = 0;
              }
              controller.openMediaViewer(list: list, index: index);
            }
          : null,
      child: ChatVideoMessageContent(
        thumbnailBase64String: message.thumbnailBase64String ?? '',
        duration: message.duration,
        sendStatus: message.mediaSendStatus,
        sendProgress: message.mediaSendProgress,
      ),
    );
  }

  void _openCombineForwardDetail(RCIMIWCombineV2Message message) {
    context.push('/chat-combine-forward-detail', extra: message);
  }

  Widget buildVoiceItem(ChatDetailMessage message, {Key? key}) {
    return KeyedSubtree(
      key: key,
      child: GestureDetector(
        onTap: () {
          controller.voicePlay(
            message.messageId,
            path: message.path,
            url: message.remote,
          );
        },
        child: StreamBuilder<String?>(
          stream: controller.voicePlayerManager.currentIdStream,
          builder: (context, snapshot) {
            final currentId = snapshot.data;
            final isPlaying = currentId == message.messageId;
            return ChatVoiceMessageContent(
              duration: message.duration ?? '',
              isPlaying: isPlaying,
            );
          },
        ),
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    ChatDetailMessage message,
  ) {
    if (_isSelectingMessages) {
      return;
    }

    ChatMessageContextMenu.show(
      context,
      position: position,
      copyText: _copyTextForMessage(message),
      onForward: _canForwardMessage(message)
          ? () => _forwardMessage(message)
          : null,
      onQuote: _canQuoteMessage(message)
          ? () => controller.quoteMessage(message)
          : null,
      onRecall: _canRecallMessage(message)
          ? () => controller.recallMessage(message)
          : null,
      onDelete: _canDeleteMessage(message)
          ? () => controller.deleteMessage(message)
          : null,
      onSelect: _canSelectMessage(message)
          ? () => _startSelectionMode(message)
          : null,
    );
  }

  bool _canRecallMessage(ChatDetailMessage message) {
    if (!message.isMe) return false;
    if (message.kind == ChatDetailMessageKind.timestamp ||
        message.kind == ChatDetailMessageKind.withdrawnNotice) {
      return false;
    }

    final raw = message.extra;
    if (raw is! RCIMIWMessage) return false;

    final sentTime = message.sentTime ?? raw.sentTime ?? raw.receivedTime;
    if (sentTime == null || sentTime <= 0) return false;

    final elapsed = DateTime.now().millisecondsSinceEpoch - sentTime;
    return elapsed <= const Duration(minutes: 2).inMilliseconds;
  }

  bool _canDeleteMessage(ChatDetailMessage message) {
    return message.extra is RCIMIWMessage;
  }

  bool _canSelectMessage(ChatDetailMessage message) {
    if (message.kind == ChatDetailMessageKind.timestamp ||
        message.kind == ChatDetailMessageKind.withdrawnNotice) {
      return false;
    }

    final raw = message.extra;
    if (raw is! RCIMIWMessage) return false;

    return raw is! RCIMIWRecallNotificationMessage &&
        raw.messageType != RCIMIWMessageType.recall;
  }

  bool _canForwardMessage(ChatDetailMessage message) {
    if (message.kind == ChatDetailMessageKind.timestamp ||
        message.kind == ChatDetailMessageKind.withdrawnNotice) {
      return false;
    }

    final raw = message.extra;
    if (raw is! RCIMIWMessage) return false;
    if (raw is RCIMIWRecallNotificationMessage ||
        raw.messageType == RCIMIWMessageType.recall) {
      return false;
    }

    if (raw is RCIMIWImageMessage ||
        raw is RCIMIWVoiceMessage ||
        raw is RCIMIWSightMessage ||
        raw is RCIMIWFileMessage) {
      final local = (raw as RCIMIWMediaMessage).local;
      return _hasUsableLocalPath(local);
    }

    if (raw is RCIMIWTextMessage) {
      return raw.text?.trim().isNotEmpty ?? false;
    }

    if (raw is RCIMIWReferenceMessage) {
      return raw.referenceMessage != null;
    }

    if (raw is RCIMIWCombineV2Message) {
      return raw.msgList?.isNotEmpty ?? false;
    }

    if (raw is RCIMIWCustomMessage) {
      return (raw.identifier?.isNotEmpty ?? false) && raw.fields != null;
    }

    return false;
  }

  bool _hasUsableLocalPath(String? path) {
    return _existingLocalMediaFile(path) != null;
  }

  bool _canQuoteMessage(ChatDetailMessage message) {
    if (message.kind == ChatDetailMessageKind.timestamp ||
        message.kind == ChatDetailMessageKind.withdrawnNotice) {
      return false;
    }

    final raw = message.extra;
    if (raw is! RCIMIWMessage) return false;

    return raw is! RCIMIWRecallNotificationMessage &&
        raw.messageType != RCIMIWMessageType.recall;
  }

  String? _copyTextForMessage(ChatDetailMessage message) {
    switch (message.kind) {
      case ChatDetailMessageKind.text:
      case ChatDetailMessageKind.fm:
      case ChatDetailMessageKind.call:
        return message.text;
      default:
        return null;
    }
  }

  List<MediaItem> _buildImageMediaList() {
    final list = <MediaItem>[];

    for (final msg in controller.messages) {
      if (msg.kind == ChatDetailMessageKind.image) {
        final mediaItem = _imageMediaItem(msg);
        if (mediaItem != null) {
          list.add(mediaItem);
        }
      }
    }

    return list;
  }

  List<MediaItem> _buildVideoMediaList() {
    final list = <MediaItem>[];

    for (final msg in controller.messages) {
      if (msg.kind == ChatDetailMessageKind.video) {
        final mediaItem = _videoMediaItem(msg);
        if (mediaItem != null) {
          list.add(mediaItem);
        }
      }
    }

    return list;
  }

  int _getImageIndex(ChatDetailMessage message) {
    int index = 0;

    for (final msg in controller.messages) {
      if (msg.kind == ChatDetailMessageKind.image &&
          _imageMediaItem(msg) != null) {
        if (msg.messageId == message.messageId) {
          return index;
        }
        index++;
      }
    }

    return 0;
  }

  int _getVideoIndex(ChatDetailMessage message) {
    int index = 0;

    for (final msg in controller.messages) {
      if (msg.kind == ChatDetailMessageKind.video &&
          _videoMediaItem(msg) != null) {
        if (msg.messageId == message.messageId) {
          return index;
        }
        index++;
      }
    }

    return -1;
  }

  MediaItem? _imageMediaItem(ChatDetailMessage message) {
    final file = _existingLocalMediaFile(message.imagePath);
    if (file != null) {
      return MediaItem(type: MediaType.image, file: file);
    }

    final remote = message.remote?.trim();
    if (remote != null &&
        remote.isNotEmpty &&
        (remote.startsWith('http://') || remote.startsWith('https://'))) {
      return MediaItem(type: MediaType.image, url: remote);
    }

    return null;
  }

  MediaItem? _videoMediaItem(ChatDetailMessage message) {
    if (message.mediaSendStatus != MediaSendStatus.sent) {
      return null;
    }

    final file = _existingLocalMediaFile(message.path);
    if (file != null) {
      return MediaItem(
        type: MediaType.video,
        file: file,
        thumbnailBase64String: message.thumbnailBase64String,
      );
    }

    final remote = message.remote?.trim();
    if (remote != null &&
        remote.isNotEmpty &&
        (remote.startsWith('http://') || remote.startsWith('https://'))) {
      return MediaItem(
        type: MediaType.video,
        url: remote,
        thumbnailBase64String: message.thumbnailBase64String,
      );
    }

    return null;
  }

  File? _existingLocalMediaFile(String? path) {
    final normalized = _localMediaPath(path);
    if (normalized == null) {
      return null;
    }

    final file = File(normalized);
    return file.existsSync() ? file : null;
  }

  String? _localMediaPath(String? path) {
    final value = path?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'file') {
      return uri.toFilePath();
    }

    return value;
  }
}
