import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:oktoast/oktoast.dart';
import 'package:go_router/go_router.dart';

/// 聊天详情页面
class ChatDetailPage extends StatefulWidget {
  /// 聊天对象的名称
  final String name;

  const ChatDetailPage({
    super.key,
    required this.name,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _inputController = TextEditingController();
  bool _isInputEmpty = true;
  bool _isMenuExpanded = false;
  bool _isVoiceMode = false;
  bool _isRecording = false;
  bool _isCancelling = false;
  ToastFuture? _voiceToast;

  // --- 手动控制群聊效果 (开发调试用) ---
  final bool _isGroup = false; // 改为 true 查看群聊效果
  final List<String> _avatars = [
    'assets/images/chat/avatar.png',
    'assets/images/chat/avatar.png',
    'assets/images/chat/avatar.png',
    'assets/images/chat/avatar.png',
  ];
  // ------------------------------

  /// 构建更多功能面板
  Widget _buildMorePanel() {
    final List<Map<String, String>> functions = [
      {'icon': 'assets/images/common/photo.png', 'label': AppLocalizations.of(context)!.chatDetailAlbum},
      {'icon': 'assets/images/common/camera.png', 'label': AppLocalizations.of(context)!.chatDetailCamera},
      {'icon': 'assets/images/common/video.png', 'label': AppLocalizations.of(context)!.chatDetailVideoCall},
      {'icon': 'assets/images/common/voice.png', 'label': AppLocalizations.of(context)!.chatDetailAudioCall},
      {'icon': 'assets/images/common/redbag.png', 'label': AppLocalizations.of(context)!.chatDetailRedPacket},
      {'icon': 'assets/images/common/file.png', 'label': AppLocalizations.of(context)!.chatDetailFile},
    ];

    return Container(
      height: 260,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(color: Colors.white),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 18,
          crossAxisSpacing: 24,
          childAspectRatio: 0.8,
        ),
        itemCount: functions.length,
        itemBuilder: (context, index) {
          final func = functions[index];
          return Column(
            children: [
              Image.asset(func['icon']!, width: 44, height: 44),
              const SizedBox(height: 8),
              Text(
                func['label']!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.grey700,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

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
  }

  @override
  void dispose() {
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
    if (_inputController.text.trim().isNotEmpty) {
      // TODO: 实现发送逻辑
      print('发送消息: ${_inputController.text}');
      _inputController.clear();
    }
  }

  void _navigateToDetail() {
    final encodedName = Uri.encodeComponent(widget.name);
    if (_isGroup) {
      context.push('/group-details/$encodedName');
    } else {
      context.push('/user-profile/$encodedName?avatar=assets/images/chat/avatar.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      isCustomHeader: true,
      renderCustomHeader: _buildCustomHeader(context),
      child: Column(
        children: [
          // 消息列表
          Expanded(child: _buildMessageList()),
          // 底部输入框
          _buildInputBar(context),
          // 更多功能面板
          if (_isMenuExpanded) _buildMorePanel(),
        ],
      ),
    );
  }

  /// 构建自定义导航栏
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: AppColors.grey200)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          IconButton(
            icon: Image.asset(
              'assets/images/common/back-icon.png',
              width: 32,
              height: 32,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          GestureDetector(
            onTap: () {
              final encodedName = Uri.encodeComponent(widget.name);
              context.push('/session-details/$encodedName');
            },
            child: _buildHeaderAvatar(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.name,
                  style: AppTextStyles.h2.copyWith(fontSize: 16),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.onlineBg,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.chatDetailActive,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Image.asset(
              'assets/images/chat/more.png',
              width: 32,
              height: 32,
            ),
            onPressed: _navigateToDetail,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildHeaderAvatar() {
    if (!_isGroup || _avatars.isEmpty) {
      // 单聊头像
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: const DecorationImage(
            image: AssetImage('assets/images/chat/avatar.png'),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // 群聊头像 (2x2 网格)
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: _avatars.length > 4 ? 4 : _avatars.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.asset(
              _avatars[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  /// 构建消息列表
  Widget _buildMessageList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        Center(
          child: Text(
            'Mar 25 2025 09:50',
            style: AppTextStyles.caption.copyWith(color: AppColors.grey400),
          ),
        ),
        const SizedBox(height: 16),
        _buildMessageItem(
          context,
          isMe: false,
          child: _buildTextContent('You have unread about GameFi?'),
        ),
        _buildMessageItem(
          context,
          isMe: true,
          child: _buildTextContent('Yeah, It\'s great.'),
        ),
        _buildMessageItem(
          context,
          isMe: false,
          child: _buildImageContent('assets/images/chat/friend-img.png'),
        ),
        _buildMessageItem(
          context,
          isMe: false,
          isUnread: true,
          child: _buildVoiceContent('12"'),
        ),
        _buildMessageItem(
          context,
          isMe: false,
          child: _buildCallContent(AppLocalizations.of(context)!.chatDetailCanceled, isVideo: false, isMe: false),
        ),
        _buildMessageItem(
          context,
          isMe: true,
          child: _buildCallContent(AppLocalizations.of(context)!.chatDetailCallDuration('00:05'), isVideo: false, isMe: true),
        ),
        _buildMessageItem(
          context,
          isMe: false,
          child: _buildCallContent(AppLocalizations.of(context)!.chatDetailCanceled, isVideo: true, isMe: false),
        ),
        _buildMessageItem(
          context,
          isMe: true,
          child: _buildCallContent(AppLocalizations.of(context)!.chatDetailCallDuration('00:05'), isVideo: true, isMe: true),
        ),
        _buildMessageItem(
          context,
          isMe: false,
          child: _buildFileContent('12345.pdf', '7.1KB'),
        ),
        _buildMessageItem(
          context,
          isMe: false,
          child: _buildContactCardContent(
            'Kristen',
            'assets/images/chat/avatar.png',
          ),
        ),
        _buildMessageItem(
          context,
          isMe: true,
          showBubble: false,
          child: _buildRedBagContent(isClaimed: false),
        ),
        _buildMessageItem(
          context,
          isMe: false,
          showBubble: false,
          child: _buildRedBagContent(isClaimed: true),
        ),
        const SizedBox(height: 16),
        Center(
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
                    TextSpan(text: AppLocalizations.of(context)!.chatDetailReceivedRedPacket('Kristen')),
                    TextSpan(
                      text: AppLocalizations.of(context)!.chatDetailRedPacket,
                      style: TextStyle(color: AppColors.grey800),
                    ),
                  ],
                ),
                style: AppTextStyles.caption.copyWith(color: AppColors.grey400),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            AppLocalizations.of(context)!.chatDetailWithdrewMessage,
            style: AppTextStyles.caption.copyWith(color: AppColors.grey400),
          ),
        ),
      ],
    );
  }

  /// 通用消息项包裹（处理头像和对齐）
  Widget _buildMessageItem(
    BuildContext context, {
    required bool isMe,
    required Widget child,
    bool isUnread = false,
    bool showBubble = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatar(),
          if (!isMe) const SizedBox(width: 12), // 别人发送：间距 12
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center, // 关键：让气泡和红点垂直居中对齐
              children: [
                Flexible(
                  child: GestureDetector(
                    onLongPressStart: (details) =>
                        _showContextMenu(context, details.globalPosition),
                    child: showBubble
                        ? CustomPaint(
                            painter: ChatBubblePainter(
                              color: isMe
                                  ? const Color(0xFFF1FADC)
                                  : Colors.white,
                              isMe: isMe,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(10), // 内 padding 10
                              child: child,
                            ),
                          )
                        : child,
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 0), // 自己发送：间距 0
        ],
      ),
    );
  }

  /// 文本消息内容
  Widget _buildTextContent(String message) {
    return Text(
      message,
      style: AppTextStyles.body.copyWith(
        color: AppColors.grey900,
        fontSize: 16,
      ),
    );
  }

  /// 图片消息内容
  Widget _buildImageContent(String imagePath) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140, maxHeight: 140),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }

  /// 语音消息内容
  Widget _buildVoiceContent(String duration) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/chat/voice.png',
          width: 18,
          height: 28,
          color: AppColors.grey900,
        ),
        const SizedBox(width: 10),
        Text(
          duration,
          style: AppTextStyles.body.copyWith(
            color: AppColors.grey900,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// 通话消息内容 (语音/视频)
  Widget _buildCallContent(
    String text, {
    required bool isVideo,
    required bool isMe,
  }) {
    final String iconPath = isVideo
        ? 'assets/images/chat/video.png'
        : (isMe
              ? 'assets/images/chat/self-call.png'
              : 'assets/images/chat/other-call.png');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isMe) ...[
          Image.asset(iconPath, width: 18, height: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: AppColors.grey900,
              fontSize: 14,
            ),
          ),
        ] else ...[
          Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: AppColors.grey900,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          Image.asset(
            iconPath,
            width: 18,
            height: 18,
            color: AppColors.grey900,
          ),
        ],
      ],
    );
  }

  /// 文件消息内容
  Widget _buildFileContent(String fileName, String fileSize) {
    return Container(
      width: 230,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/chat/file.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fileName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey900,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fileSize,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 名片消息内容
  Widget _buildContactCardContent(String name, String avatarPath) {
    return Container(
      width: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  avatarPath,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey900,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.chatDetailContactCard,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 红包消息内容
  Widget _buildRedBagContent({required bool isClaimed}) {
    return Image.asset(
      isClaimed
          ? 'assets/images/chat/redbag-default.png'
          : 'assets/images/chat/redbag-active.png',
      width: 120,
      height: 180,
      fit: BoxFit.contain,
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: const DecorationImage(
          image: AssetImage('assets/images/chat/avatar.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// 显示长按菜单
  void _showContextMenu(BuildContext context, Offset position) {
    final screenHeight = MediaQuery.of(context).size.height;
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          Positioned(
            left: 20,
            right: 20,
            bottom: screenHeight - position.dy + 25, // 向上偏移，确保不遮挡消息
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Wrap(
                      spacing: 0,
                      runSpacing: 20,
                      alignment: WrapAlignment.start,
                      children: [
                        _buildMenuItem('assets/images/chat/copy.png', 'Copy'),
                        _buildMenuItem(
                          'assets/images/chat/share.png',
                          'transpond',
                        ),
                        _buildMenuItem(
                          'assets/images/chat/translate.png',
                          'translate',
                        ),
                        _buildMenuItem('assets/images/chat/quote.png', 'quote'),
                        _buildMenuItem(
                          'assets/images/chat/recall.png',
                          'recall',
                        ),
                        _buildMenuItem(
                          'assets/images/chat/delete-msg.png',
                          'Delete',
                        ),
                        _buildMenuItem(
                          'assets/images/chat/select.png',
                          'select',
                        ),
                      ],
                    ),
                  ),
                  // 小箭头放在 Container 下方，并根据触摸位置偏移
                  Padding(
                    padding: EdgeInsets.only(
                      left: (position.dx - 20 - 10).clamp(
                        16.0,
                        MediaQuery.of(context).size.width - 72,
                      ),
                    ),
                    child: CustomPaint(
                      size: const Size(20, 10),
                      painter: TrianglePainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String icon, String label) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: (MediaQuery.of(context).size.width - 72) / 4, // 动态计算 4 列宽度
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(icon, width: 24, height: 24, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建底部输入栏
  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleVoiceMode,
            child: Image.asset(
              _isVoiceMode
                  ? 'assets/images/chat/keyboard.png'
                  : 'assets/images/chat/microphone.png',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isVoiceMode
                ? GestureDetector(
                    onLongPressStart: (details) {
                      setState(() {
                        _isRecording = true;
                        _isCancelling = false;
                      });
                      _showVoiceOverlay('union', 'Slide up to cancel');
                    },
                    onLongPressMoveUpdate: (details) {
                      // 向上滑动超过一定距离（如 50）认为是要取消
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
                    onLongPressEnd: (details) {
                      if (_isCancelling) {
                        AppToast.show(AppLocalizations.of(context)!.chatDetailRecordCanceled);
                      } else {
                        // 如果录音时间太短（这里简单模拟，真实情况需要计时）
                        // AppToast.show('Short speech');
                        _handleSend();
                      }
                      setState(() {
                        _isRecording = false;
                        _isCancelling = false;
                      });
                      _hideVoiceOverlay();
                    },
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.topBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _isRecording
                            ? (_isCancelling
                                ? AppLocalizations.of(context)!.chatDetailReleaseToCancel
                                : AppLocalizations.of(context)!.chatDetailReleaseToEnd)
                            : AppLocalizations.of(context)!.chatDetailHoldToTalk,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.topBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _inputController,
                      onTap: () {
                        if (_isMenuExpanded) {
                          setState(() {
                            _isMenuExpanded = false;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Image.asset('assets/images/chat/emoj.png', width: 24, height: 24),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isInputEmpty ? _toggleMenu : _handleSend,
            child: Image.asset(
              !_isInputEmpty
                  ? 'assets/images/chat/send.png'
                  : (_isMenuExpanded
                        ? 'assets/images/chat/function-close.png'
                        : 'assets/images/chat/more-function.png'),
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 聊天气泡背景绘制
class ChatBubblePainter extends CustomPainter {
  final Color color;
  final bool isMe;

  ChatBubblePainter({required this.color, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const radius = 16.0;
    const tailWidth = 8.0;
    const tailHeight = 8.0;

    if (isMe) {
      // 自己发送的消息：右下角尖角
      path.addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, size.width, size.height),
          topLeft: const Radius.circular(radius),
          topRight: const Radius.circular(radius),
          bottomLeft: const Radius.circular(radius),
          bottomRight: const Radius.circular(0), // 右下角设为0
        ),
      );

      // 绘制右下角尖角
      path.moveTo(size.width, size.height - 12); // 从圆角上方开始
      path.lineTo(size.width + tailWidth, size.height); // 尖端
      path.lineTo(size.width - 12, size.height); // 回到下方边缘
    } else {
      // 别人发送的消息：左上角尖角
      path.addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, size.width, size.height),
          topLeft: const Radius.circular(0), // 左上角设为0
          topRight: const Radius.circular(radius),
          bottomLeft: const Radius.circular(radius),
          bottomRight: const Radius.circular(radius),
        ),
      );

      // 绘制左上角尖角
      path.moveTo(0, 12); // 从圆角下方开始
      path.lineTo(-tailWidth, 0); // 尖端
      path.lineTo(12, 0); // 回到上方边缘
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ChatBubblePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isMe != isMe;
}
