import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/models/media_item.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../tool/keyboard_detector.dart';
import '../../../widgets/base/app_localizations.dart';
import '../../../widgets/base/app_page.dart';
import '../../../widgets/chat/chat_detail_header.dart';
import '../../../widgets/chat/chat_input_bar.dart';
import '../../../widgets/chat/chat_message_contents.dart';
import '../../../widgets/chat/chat_message_context_menu.dart';
import '../../../widgets/chat/chat_message_item.dart';
import '../../../widgets/chat/chat_more_panel.dart';
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

  @override
  void initState() {
    super.initState();
    controller = ChatDetailController(widget.sessionArgs);
    controller.init(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller.context = context;

    return AppPage(
      isCustomHeader: true,
      isAddBottomMargin: false,
      renderCustomHeader: ChatDetailHeader(
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
          if (keyboardHeight > 0 && controller.engine.isAtBottom) {
            controller.engine.scrollToBottom();
          }
          return Column(
            children: [
              Expanded(child: _buildMessageList()),
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
                onVoiceLongPressMoveUpdate: (d) => controller.voiceUpdate(d),
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
          );
        },
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
          return KeyedSubtree(
            key: _keyForMessage(message.messageId),
            child: _buildMessageNode(message),
          );
        },
      ),
    );
  }

  GlobalKey _keyForMessage(String messageId) {
    return _messageKeys.putIfAbsent(messageId, GlobalKey.new);
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
          onLongPressStart: (d) =>
              _showContextMenu(context, d.globalPosition, message),
          child: _buildMessageContent(message),
        );
    }
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
            controller.openMediaViewer(
              list: _buildMediaList(message),
              index: _getIndex(message),
            );
          },
          child: ChatImageMessageContent(imagePath: message.imagePath ?? ''),
        );
      case ChatDetailMessageKind.video:
        return GestureDetector(
          onTap: () {
            controller.openMediaViewer(
              list: _buildMediaList(message),
              index: _getIndex(message),
            );
          },
          child: ChatVideoMessageContent(
            thumbnailBase64String: message.thumbnailBase64String ?? '',
            duration: message.duration,
          ),
        );
      case ChatDetailMessageKind.file:
        return ChatFileMessageContent(
          fileName: message.fileName ?? '',
          fileSize: message.fileSize ?? '',
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
    ChatMessageContextMenu.show(
      context,
      position: position,
      copyText: _copyTextForMessage(message),
      onQuote: _canQuoteMessage(message)
          ? () => controller.quoteMessage(message)
          : null,
      onRecall: _canRecallMessage(message)
          ? () => controller.recallMessage(message)
          : null,
      onDelete: _canDeleteMessage(message)
          ? () => controller.deleteMessage(message)
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

  List<MediaItem> _buildMediaList(ChatDetailMessage current) {
    final list = <MediaItem>[];

    for (final msg in controller.messages) {
      if (msg.kind == ChatDetailMessageKind.image) {
        list.add(MediaItem(type: MediaType.image, file: File(msg.imagePath!)));
      }

      if (msg.kind == ChatDetailMessageKind.video) {
        list.add(
          MediaItem(
            type: MediaType.video,
            file: File(msg.path!),
            thumbnailBase64String: msg.thumbnailBase64String,
          ),
        );
      }
    }

    return list;
  }

  int _getIndex(ChatDetailMessage message) {
    int index = 0;

    for (final msg in controller.messages) {
      if (msg.kind == ChatDetailMessageKind.image ||
          msg.kind == ChatDetailMessageKind.video) {
        if (msg.messageId == message.messageId) {
          return index;
        }
        index++;
      }
    }

    return 0;
  }
}
