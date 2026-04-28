import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../tool/keyboard_detector.dart';
import '../../../widgets/base/app_localizations.dart';
import '../../../widgets/base/app_page.dart';
import '../../../widgets/chat/chat_detail_header.dart';
import '../../../widgets/chat/chat_input_bar.dart';
import '../../../widgets/chat/chat_message_contents.dart';
import '../../../widgets/chat/chat_message_context_menu.dart';
import '../../../widgets/chat/chat_message_item.dart';
import '../../../widgets/chat/chat_more_panel.dart';
import '../../../widgets/common/app_empty_view.dart';
import '../chat_detail_message.dart';
import '../chat_session_args.dart';
import 'chat_detail_controller.dart';

class ChatDetailPage extends StatefulWidget{
  final ChatSessionArgs? sessionArgs;
  final String fallbackName;

  const ChatDetailPage({
    super.key,
    required ChatSessionArgs this.sessionArgs,
  }) : fallbackName = '';

  const ChatDetailPage.missingArgs({
    super.key,
    required this.fallbackName,
  }) : sessionArgs = null;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  late final ChatDetailController controller;

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
    return AppPage(
      isCustomHeader: true,
      isAddBottomMargin: false,
      renderCustomHeader: ChatDetailHeader(
        name: _sessionName,
        isGroup: _isGroupSession,
        avatar: _headerAvatar,
        targetId: _targetId,
        isOnline: controller.isOnline,
        onMoreTap: _navigateToDetail,
      ),
      child: KeyboardDetector(
        builder: (keyboardHeight) {
          if (keyboardHeight > 0 && controller.isAtBottom) {
            controller.scrollToBottom();
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
                onToggleVoiceMode: controller.toggleVoice,
                onTextFieldTap: () {
                  if (controller.isMenuExpanded) {
                    controller.isMenuExpanded = false;
                    setState(() {});
                  }
                },
                onActionTap: controller.isInputEmpty
                    ? controller.toggleMenu
                    : () => controller.sendText(),
                onVoiceLongPressStart: (d) {},
                onVoiceLongPressMoveUpdate: (d) {},
                onVoiceLongPressEnd: (d) {},
              ),
              // if (controller.isMenuExpanded) const ChatMorePanel(),
            ],
          );
        },
      )
    );
  }

  Widget _buildMessageList() {
    if (widget.sessionArgs == null) {
      return const Center(child: Text('缺少会话参数'));
    }

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (scroll) {
        if (scroll.metrics.pixels <= 100 && controller.messages.isNotEmpty) {
          controller.loadMoreMessages();
        }
        return false;
      },
      child: ListView.builder(
        controller: controller.scrollController,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: 20,
        ),
        itemCount: controller.messages.length,
        itemBuilder: (context, index) =>
            _buildMessageNode(controller.messages[index]),
      )
    );
  }

  Widget _buildMessageNode(ChatDetailMessage message) {
    switch (message.kind) {
      case ChatDetailMessageKind.timestamp:
        return Center(child: Text(message.text ?? ''));
      default:
        return ChatMessageItem(
          isMe: message.isMe,
          isUnread: message.isUnread,
          showBubble: message.showBubble,
          onLongPressStart: (d) =>
              _showContextMenu(context, d.globalPosition),
          child: _buildMessageContent(message),
        );
    }
  }

  Widget _buildMessageContent(ChatDetailMessage message) {
    switch (message.kind) {
      case ChatDetailMessageKind.text:
        return ChatTextMessageContent(message: message.text ?? '');
      default:
        return const SizedBox();
    }
  }

  void _showContextMenu(BuildContext context, Offset position) {
    ChatMessageContextMenu.show(context, position: position);
  }

  void _navigateToDetail() {
    final name = widget.sessionArgs?.name ?? widget.fallbackName;
    final encoded = Uri.encodeComponent(name);

    if (_isGroupSession) {
      context.push('/group-details/$encoded');
    } else {
      context.push('/user-profile/$encoded');
    }
  }

  String get _sessionName =>
      widget.sessionArgs?.name ?? widget.fallbackName;

  bool get _isGroupSession =>
      widget.sessionArgs?.isGroup ?? false;

  String get _targetId =>
      widget.sessionArgs?.targetId ?? '';

  String get _headerAvatar =>
      widget.sessionArgs?.avatar ?? '';
}