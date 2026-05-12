import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rongcloud_call_wrapper_plugin/rongcloud_call_wrapper_plugin.dart';

import '../../../core/models/media_item.dart';
import '../../../modules/call/rong_call_manager.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../tool/keyboard_detector.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/base/app_page.dart';
import '../../../widgets/chat/chat_detail_header.dart';
import '../../../widgets/chat/chat_input_bar.dart';
import '../../../widgets/chat/chat_message_contents.dart';
import '../../../widgets/chat/chat_message_context_menu.dart';
import '../../../widgets/chat/chat_message_item.dart';
import '../../../widgets/chat/chat_more_panel.dart';
import '../chat_detail_message.dart';
import '../chat_session_args.dart';
import 'chat_detail_controller.dart';

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
        onMoreTap: _navigateToSettings,
        onAvatarTap: _navigateToProfile,
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
                        await _openCallPage(isVideo: true);
                      case ChatMoreAction.audioCall:
                        await _openCallPage(isVideo: false);
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

  Widget _buildMessageNode(ChatDetailMessage message) {
    switch (message.kind) {
      case ChatDetailMessageKind.timestamp:
      case ChatDetailMessageKind.fm:
        return Center(
          child: Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              message.text ?? '',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.grey400,
                fontSize: 12,
              ),
            ),
          ),
        );
      default:
        return ChatMessageItem(
          isMe: message.isMe,
          isUnread: message.isUnread,
          showBubble: message.showBubble,
          onLongPressStart: (d) => _showContextMenu(context, d.globalPosition),
          child: _buildMessageContent(message),
        );
    }
  }

  Widget _buildMessageContent(ChatDetailMessage message) {
    switch (message.kind) {
      case ChatDetailMessageKind.text:
        return ChatTextMessageContent(message: message.text ?? '');
      case ChatDetailMessageKind.voice:
        return buildVoiceItem(message, key: ValueKey(message.messageId));
      case ChatDetailMessageKind.fm:
        return ChatTextMessageContent(message: message.text ?? '');
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

  void _showContextMenu(BuildContext context, Offset position) {
    ChatMessageContextMenu.show(context, position: position);
  }

  void _navigateToSettings() {
    final name = widget.sessionArgs?.name ?? widget.fallbackName;
    final encoded = Uri.encodeComponent(name);

    if (_isGroupSession) {
      context.push('/group-details/$encoded', extra: widget.sessionArgs);
    } else {
      context.push('/session-details/$encoded', extra: widget.sessionArgs);
    }
  }

  void _navigateToProfile() {
    if (_isGroupSession) {
      _navigateToSettings();
      return;
    }

    if (_targetId.isEmpty) {
      _navigateToSettings();
      return;
    }

    context.push('/user-profile', extra: _targetId);
  }

  Future<void> _openCallPage({required bool isVideo}) async {
    if (_isGroupSession) {
      AppToast.showInfo('群通话暂未开放');
      controller.isMenuExpanded = false;
      setState(() {});
      return;
    }

    final encoded = Uri.encodeComponent(_sessionName);
    final media = isVideo ? 'video' : 'voice';

    controller.isMenuExpanded = false;
    setState(() {});
    final started = await RongCallManager().startPrivateCall(
      targetId: _targetId,
      displayName: _sessionName,
      mediaType: isVideo ? RCCallMediaType.audio_video : RCCallMediaType.audio,
    );
    if (!mounted || !started) return;
    context.push('/chat-private-$media/$encoded');
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

  String get _sessionName => widget.sessionArgs?.name ?? widget.fallbackName;

  bool get _isGroupSession => widget.sessionArgs?.isGroup ?? false;

  String get _targetId => widget.sessionArgs?.targetId ?? '';

  String get _headerAvatar => widget.sessionArgs?.avatar ?? '';
}
