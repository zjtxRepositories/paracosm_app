import 'package:flutter/material.dart';
import 'dart:async';
import 'package:paracosm/modules/im/manager/im_message_manager.dart';
import 'package:paracosm/modules/im/manager/im_send_manager.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:paracosm/pages/chat/chat_detail_message_mapper.dart';
import 'package:paracosm/pages/chat/chat_session_args.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/chat/chat_detail_header.dart';
import 'package:paracosm/widgets/chat/chat_input_bar.dart';
import 'package:paracosm/widgets/chat/chat_message_contents.dart';
import 'package:paracosm/widgets/chat/chat_message_context_menu.dart';
import 'package:paracosm/widgets/chat/chat_message_item.dart';
import 'package:paracosm/widgets/chat/chat_more_panel.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:oktoast/oktoast.dart';
import 'package:go_router/go_router.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

/// 聊天详情页面
class ChatDetailPage extends StatefulWidget {
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
  final TextEditingController _inputController = TextEditingController();
  final ImMessageManager _messageManager = ImMessageManager();
  bool _isInputEmpty = true;
  bool _isMenuExpanded = false;
  bool _isVoiceMode = false;
  bool _isRecording = false;
  bool _isCancelling = false;
  bool _isLoading = false;
  String? _errorText;
  List<ChatDetailMessage> _messages = const [];
  StreamSubscription<RCIMIWMessage>? _messageSubscription;
  ToastFuture? _voiceToast;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      final bool isEmpty = _inputController.text.trim().isEmpty;
      if (isEmpty != _isInputEmpty) {
        setState(() {
          _isInputEmpty = isEmpty;
        });
      }
    });
    _loadMessages();
    _subscribeMessages();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (!_isMenuExpanded) {
      // 打开菜单前隐藏键盘
      FocusScope.of(context).unfocus();
      if (_isVoiceMode) {
        setState(() {
          _isVoiceMode = false;
        });
      }
    }
    setState(() {
      _isMenuExpanded = !_isMenuExpanded;
    });
  }

  void _toggleVoiceMode() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
      if (_isVoiceMode) {
        _isMenuExpanded = false;
        FocusScope.of(context).unfocus();
      }
    });
  }

  void _showVoiceOverlay(String icon, String text) {
    _voiceToast?.dismiss();
    _voiceToast = showToastWidget(
      Center(
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/chat/$icon.png',
                width: 60,
                height: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      duration: const Duration(days: 1), // 持续显示直到手动关闭
      position: ToastPosition.center,
      handleTouch: false,
    );
  }

  void _hideVoiceOverlay() {
    _voiceToast?.dismiss();
    _voiceToast = null;
  }

  void _handleSend() {
    _sendTextMessage();
  }

  void _navigateToDetail() {
    final name = widget.sessionArgs?.name ?? widget.fallbackName;
    final encodedName = Uri.encodeComponent(name);
    if (_isGroupSession) {
      context.push('/group-details/$encodedName');
    } else {
      context.push('/user-profile/$encodedName?avatar=assets/images/chat/avatar.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      isCustomHeader: true,
      renderCustomHeader: ChatDetailHeader(
        name: _sessionName,
        isGroup: _isGroupSession,
        avatars: _headerAvatars,
        onMoreTap: _navigateToDetail,
      ),
      child: Column(
        children: [
          // 消息列表
          Expanded(child: _buildMessageList()),
          // 底部输入框
          ChatInputBar(
            controller: _inputController,
            isVoiceMode: _isVoiceMode,
            isRecording: _isRecording,
            isCancelling: _isCancelling,
            isMenuExpanded: _isMenuExpanded,
            isInputEmpty: _isInputEmpty,
            onToggleVoiceMode: _toggleVoiceMode,
            onTextFieldTap: () {
              if (_isMenuExpanded) {
                setState(() {
                  _isMenuExpanded = false;
                });
              }
            },
            onActionTap: _isInputEmpty ? _toggleMenu : _handleSend,
            onVoiceLongPressStart: (details) {
              setState(() {
                _isRecording = true;
                _isCancelling = false;
              });
              _showVoiceOverlay('union', 'Slide up to cancel');
            },
            onVoiceLongPressMoveUpdate: (details) {
              final bool isCancelling = details.localOffsetFromOrigin.dy < -50;
              if (isCancelling != _isCancelling) {
                setState(() {
                  _isCancelling = isCancelling;
                });
                if (_isCancelling) {
                  _showVoiceOverlay('cancel', 'Release to cancel');
                } else {
                  _showVoiceOverlay('union', 'Slide up to cancel');
                }
              }
            },
            onVoiceLongPressEnd: (details) {
              if (_isCancelling) {
                AppToast.show(AppLocalizations.of(context)!.chatDetailRecordCanceled);
              } else {
                _handleSend();
              }
              setState(() {
                _isRecording = false;
                _isCancelling = false;
              });
              _hideVoiceOverlay();
            },
          ),
          // 更多功能面板
          if (_isMenuExpanded) const ChatMorePanel(),
        ],
      ),
    );
  }

  /// 构建消息列表
  Widget _buildMessageList() {
    if (widget.sessionArgs == null) {
      return Center(
        child: Text(
          '缺少会话参数',
          style: AppTextStyles.body.copyWith(color: AppColors.grey400),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorText != null) {
      return Center(
        child: Text(
          _errorText!,
          style: AppTextStyles.body.copyWith(color: AppColors.error),
        ),
      );
    }

    if (_messages.isEmpty) {
      return AppEmptyView(
        text: AppLocalizations.of(context)!.chatSearchNoData,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageNode(_messages[index]),
    );
  }

  Widget _buildMessageNode(ChatDetailMessage message) {
    switch (message.kind) {
      case ChatDetailMessageKind.timestamp:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Center(
            child: Text(
              message.text ?? '',
              style: AppTextStyles.caption.copyWith(color: AppColors.grey400),
            ),
          ),
        );
      case ChatDetailMessageKind.redBagNotice:
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/chat/redbag-active.png',
                  width: 14,
                  height: 16,
                ),
                const SizedBox(width: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: AppLocalizations.of(context)!.chatDetailReceivedRedPacket(
                          message.noticeName ?? '',
                        ),
                      ),
                      TextSpan(
                        text: AppLocalizations.of(context)!.chatDetailRedPacket,
                        style: const TextStyle(color: AppColors.grey800),
                      ),
                    ],
                  ),
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey400),
                ),
              ],
            ),
          ),
        );
      case ChatDetailMessageKind.withdrawnNotice:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.chatDetailWithdrewMessage,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey400),
            ),
          ),
        );
      default:
        return ChatMessageItem(
          isMe: message.isMe,
          isUnread: message.isUnread,
          showBubble: message.showBubble,
          onLongPressStart: (details) =>
              _showContextMenu(context, details.globalPosition),
          child: _buildMessageContent(message),
        );
    }
  }

  Widget _buildMessageContent(ChatDetailMessage message) {
    switch (message.kind) {
      case ChatDetailMessageKind.text:
        return ChatTextMessageContent(message: message.text ?? '');
      case ChatDetailMessageKind.image:
        return ChatImageMessageContent(imagePath: message.imagePath ?? '');
      case ChatDetailMessageKind.voice:
        return ChatVoiceMessageContent(duration: message.duration ?? '');
      case ChatDetailMessageKind.call:
        return ChatCallMessageContent(
          text: message.text == 'canceled'
              ? AppLocalizations.of(context)!.chatDetailCanceled
              : AppLocalizations.of(context)!.chatDetailCallDuration(
            message.text ?? '00:00',
          ),
          isVideo: message.isVideo,
          isMe: message.isMe,
        );
      case ChatDetailMessageKind.file:
        return ChatFileMessageContent(
          fileName: message.fileName ?? '',
          fileSize: message.fileSize ?? '',
        );
      case ChatDetailMessageKind.contactCard:
        return ChatContactCardMessageContent(
          name: message.contactName ?? '',
          avatarPath: message.avatarPath ?? '',
          footerLabel: AppLocalizations.of(context)!.chatDetailContactCard,
        );
      case ChatDetailMessageKind.redBag:
        return ChatRedBagMessageContent(isClaimed: message.isClaimed ?? false);
      case ChatDetailMessageKind.timestamp:
      case ChatDetailMessageKind.redBagNotice:
      case ChatDetailMessageKind.withdrawnNotice:
        return const SizedBox.shrink();
    }
  }

  /// 显示长按菜单
  void _showContextMenu(BuildContext context, Offset position) {
    ChatMessageContextMenu.show(context, position: position);
  }

  Future<void> _loadMessages() async {
    final args = widget.sessionArgs;
    if (args == null) {
      setState(() {
        _errorText = '缺少会话参数';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final messages = await _messageManager.getMessages(
        type: args.conversationType,
        targetId: args.targetId,
        channelId: args.channelId,
        sentTime: 0,
        order: RCIMIWTimeOrder.before,
        policy: RCIMIWMessageOperationPolicy.local,
        count: 50,
      );

      if (!mounted) return;

      setState(() {
        _messages = ChatDetailMessageMapper.mapMessages(
          messages.reversed.toList(),
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeMessages() {
    _messageSubscription = _messageManager.messageStream.listen((message) {
      final args = widget.sessionArgs;
      if (args == null) return;
      if (message.targetId != args.targetId) return;
      if (message.conversationType != args.conversationType) return;
      if (message.channelId != args.channelId) return;

      final mapped = ChatDetailMessageMapper.mapMessages([message]);
      if (mapped.isEmpty || !mounted) return;

      setState(() {
        _messages = [..._messages, ...mapped];
      });
    });
  }

  Future<void> _sendTextMessage() async {
    final args = widget.sessionArgs;
    final text = _inputController.text.trim();
    if (args == null || text.isEmpty) return;
    try {
      await ImSendManager.instance.sendText(
        type: args.conversationType,
        targetId: args.targetId,
        channelId: args.channelId,
        content: text,
      );
      if (!mounted) return;
      _inputController.clear();
    } catch (error) {
      if (!mounted) return;
      AppToast.show(error.toString());
    }
  }

  String get _sessionName => widget.sessionArgs?.name ?? widget.fallbackName;

  bool get _isGroupSession => widget.sessionArgs?.isGroup ?? false;

  List<String> get _headerAvatars {
    final avatar = widget.sessionArgs?.avatar;
    if (avatar != null && avatar.isNotEmpty) {
      return [avatar];
    }
    return const [
      'assets/images/chat/avatar.png',
      'assets/images/chat/avatar.png',
      'assets/images/chat/avatar.png',
      'assets/images/chat/avatar.png',
    ];
  }
}
