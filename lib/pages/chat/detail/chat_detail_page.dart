import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
import '../../../widgets/chat/voice_record_overlay.dart';
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
    controller.context = context;

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
                onToggleVoiceMode:controller.toggleVoice,
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
                  onItemTap: (item) {
                    switch (item.type) {
                      case ChatMoreAction.album:
                        controller.toggleAlbum();
                      case ChatMoreAction.camera:
                        controller.toggleCamera();
                      case ChatMoreAction.videoCall:
                        // TODO: Handle this case.
                        throw UnimplementedError();
                      case ChatMoreAction.audioCall:
                        // TODO: Handle this case.
                        throw UnimplementedError();
                      case ChatMoreAction.redbag:
                        // TODO: Handle this case.
                        throw UnimplementedError();
                      case ChatMoreAction.file:
                        controller.toggleFile();
                    }
                  },
                )
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
          controller: controller.engine.scrollController,
          padding: const EdgeInsets.symmetric(vertical: 20,horizontal: 16),
          itemCount: controller.messages.length,
          itemBuilder: (context, index) {
            final message = controller.messages[index];
            return _buildMessageNode(message);
          },
        )
    );
  }

  Widget _buildMessageNode(ChatDetailMessage message) {
    switch (message.kind) {
      case ChatDetailMessageKind.timestamp:
      case ChatDetailMessageKind.fm:
        return Center(
            child:Padding(padding: EdgeInsets.only(top: 10),
            child: Text(message.text ?? '',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.grey400,
                fontSize: 12,
              ),),)
       );
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
      case ChatDetailMessageKind.voice:
        return ChatVoiceMessageContent(duration: message.duration ?? '');
      case ChatDetailMessageKind.fm:
        return ChatTextMessageContent(message: message.text ?? '');
      case ChatDetailMessageKind.image:
        return ChatImageMessageContent(imagePath: message.imagePath ?? '');
      case ChatDetailMessageKind.video:
        return ChatVideoMessageContent(thumbnailBase64String: message.thumbnailBase64String ?? '',duration: message.duration);
      case ChatDetailMessageKind.file:
        return ChatFileMessageContent(fileName: message.fileName ?? '', fileSize: message.fileSize ?? '');
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