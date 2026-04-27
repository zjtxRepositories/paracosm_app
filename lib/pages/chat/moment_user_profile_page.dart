import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_action_pop_menu.dart';
import 'package:paracosm/widgets/common/app_button.dart';

/// 个人主页详情页
/// 保留社区详情页的主体结构，只显示看板下面的内容列表，移除 TabController 和其他 Tab 区域。
class MomentUserProfilePage extends StatefulWidget {
  final String communityName;

  const MomentUserProfilePage({super.key, this.communityName = 'Kristen'});

  @override
  State<MomentUserProfilePage> createState() => _MomentUserProfilePageState();
}

class _MomentUserProfilePageState extends State<MomentUserProfilePage> {
  static const double _sendMomentSize = 44;
  Offset? _sendMomentOffset;
  bool _sendMomentInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sendMomentInitialized) {
      return;
    }

    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.of(context).padding;
    _sendMomentOffset = Offset(
      size.width - 20 - _sendMomentSize,
      size.height - padding.bottom - 50 - _sendMomentSize,
    );
    _sendMomentInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPage(
      showNav: true,
      isCustomHeader: true,
      renderCustomHeader: _buildCustomHeader(context),
      extendBodyBehindAppBar: true,
      navBackgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/moments/moment-bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 140),
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 140,
                    ),
                    decoration: const BoxDecoration(color: AppColors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAvatarAndJoinAction(context, l10n),
                              const SizedBox(height: 16),
                              _buildCommunityTitleAndAddress(),
                              const SizedBox(height: 4),
                              _buildFollowStats(),
                              const SizedBox(height: 16),
                              const Divider(
                                height: 1,
                                color: AppColors.grey200,
                              ),
                              const SizedBox(height: 16),
                              _buildDynamicSection(),
                            ],
                          ),
                        ),
                        _buildDashboardContent(l10n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_sendMomentOffset != null)
            Positioned(
              left: _sendMomentOffset!.dx,
              top: _sendMomentOffset!.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final size = MediaQuery.sizeOf(context);
                  final padding = MediaQuery.of(context).padding;
                  final maxX = size.width - _sendMomentSize;
                  final maxY = size.height - padding.bottom - _sendMomentSize;
                  final nextOffset = Offset(
                    (_sendMomentOffset!.dx + details.delta.dx).clamp(0.0, maxX),
                    (_sendMomentOffset!.dy + details.delta.dy).clamp(0.0, maxY),
                  );

                  setState(() {
                    _sendMomentOffset = nextOffset;
                  });
                },
                child: Image.asset(
                  'assets/images/moments/send-moment.png',
                  width: _sendMomentSize,
                  height: _sendMomentSize,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 自定义导航栏
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Image.asset(
              'assets/images/community/back.png',
              width: 32,
              height: 32,
            ),
          ),
          Builder(
            builder: (context) {
              final moreButtonKey = GlobalKey();

              return GestureDetector(
                key: moreButtonKey,
                onTap: () {
                  AppActionPopMenu.show(
                    context,
                    buttonKey: moreButtonKey,
                    width: 152,
                    rightOffset: 5,
                    items: [
                      AppActionPopMenuItem(
                        icon: 'assets/images/moments/block.png',
                        label: 'Block this user',
                        onTap: () {},
                      ),
                      AppActionPopMenuItem(
                        icon: 'assets/images/moments/report.png',
                        label: 'Report',
                        onTap: () {},
                        showDivider: false,
                      ),
                    ],
                  );
                },
                child: Image.asset(
                  'assets/images/moments/black-more.png',
                  width: 32,
                  height: 32,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 头像与操作按钮
  Widget _buildAvatarAndJoinAction(
      BuildContext context,
      AppLocalizations l10n,
      ) {
    return SizedBox(
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(top: -16, left: 0, child: _buildGridAvatar()),
          Positioned(
            bottom: 16,
            right: 0,
            child: AppButton(
              text:'Follow',
              onPressed: () {},
              width: 85,
              height: 28,
              borderRadius: 28,
              backgroundColor: AppColors.grey900,
              textColor: AppColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 头像
  Widget _buildGridAvatar() {
    return SizedBox(
      width: 64,
      height: 64,
      child: Image.asset('assets/images/chat/avatar.png', fit: BoxFit.cover),
    );
  }

  /// 社区标题和地址
  Widget _buildCommunityTitleAndAddress() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.communityName,
              style: AppTextStyles.h1.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.grey200, width: 1),
                borderRadius: BorderRadius.circular(61),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/common/copy-black.png',
                    width: 12,
                    height: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    l10n.communityMockAddressDetail,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 10,
                      color: AppColors.grey900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 关注数与粉丝数
  Widget _buildFollowStats() {
    return Row(
      children: [
        Text(
          '10',
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.grey900,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'Following',
          style: AppTextStyles.body.copyWith(
            fontSize: 10,
            color: AppColors.grey400,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '16,987',
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.grey900,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'Followers',
          style: AppTextStyles.body.copyWith(
            fontSize: 10,
            color: AppColors.grey400,
          ),
        ),
      ],
    );
  }

  /// Dynamic 区域
  Widget _buildDynamicSection() {
    return Row(
      children: [
        Image.asset(
          'assets/images/moments/mike.png',
          width: 20,
          height: 20,
        ),
        const SizedBox(width: 4),
        Text(
          'Dynamic',
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.grey900,
          ),
        ),
      ],
    );
  }

  /// 内容列表
  Widget _buildDashboardContent(AppLocalizations l10n) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      itemCount: 2,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        return Column(
          children: [
            _buildPostItem(l10n),
            const SizedBox(height: 12),
            _buildPostInteraction(l10n),
          ],
        );
      },
    );
  }

  /// 帖子内容
  Widget _buildPostItem(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/chat/avatar.png',
                width: 36,
                height: 36,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kristen',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '22:03 2025-04-18',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 10,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'What kind of photos can a novice take after learning by himself for half a What kind of photos can a novice take after learning by himself for half',
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: const Color(0xFF404040),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildPostImageGrid(),
        const SizedBox(height: 12),
      ],
    );
  }

  /// 帖子图片网格
  Widget _buildPostImageGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 4;
        final double size = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(6, (index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/images/moments/moment1.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            );
          }),
        );
      },
    );
  }

  /// 帖子互动区
  Widget _buildPostInteraction(AppLocalizations l10n) {
    return _PostActionBar(
      initialLiked: false,
      initialCollected: false,
      likeCount: 1,
      collectCount: 1,
      commentCount: 12,
      shareCount: 1,
    );
  }
}

class _PostActionBar extends StatefulWidget {
  final bool initialLiked;
  final bool initialCollected;
  final int likeCount;
  final int collectCount;
  final int commentCount;
  final int shareCount;

  const _PostActionBar({
    required this.initialLiked,
    required this.initialCollected,
    required this.likeCount,
    required this.collectCount,
    required this.commentCount,
    required this.shareCount,
  });

  @override
  State<_PostActionBar> createState() => _PostActionBarState();
}

class _PostActionBarState extends State<_PostActionBar> {
  late bool _isLiked;
  late bool _isCollected;
  late int _likeCount;
  late int _collectCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialLiked;
    _isCollected = widget.initialCollected;
    _likeCount = widget.likeCount;
    _collectCount = widget.collectCount;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : (_likeCount > 0 ? _likeCount - 1 : 0);
    });
  }

  void _toggleCollect() {
    setState(() {
      _isCollected = !_isCollected;
      _collectCount = _isCollected ? _collectCount + 1 : (_collectCount > 0 ? _collectCount - 1 : 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionIconTextButton(
          icon: _isLiked ? 'assets/images/moments/like-active.png' : 'assets/images/moments/like.png',
          text: '$_likeCount',
          active: _isLiked,
          onTap: _toggleLike,
        ),
        const SizedBox(width: 24),
        _ActionIconTextButton(
          icon: _isCollected ? 'assets/images/moments/collect-active.png' : 'assets/images/moments/collect.png',
          text: '$_collectCount',
          active: _isCollected,
          onTap: _toggleCollect,
        ),
        const SizedBox(width: 24),
        _ActionIconTextButton(
          icon: 'assets/images/moments/comment.png',
          text: '${widget.commentCount}',
        ),
        const Spacer(),
        _ActionIconTextButton(
          icon: 'assets/images/moments/share.png',
          text: '${widget.shareCount}',
        ),
      ],
    );
  }
}

class _ActionIconTextButton extends StatelessWidget {
  final String icon;
  final String text;
  final bool active;
  final VoidCallback? onTap;

  const _ActionIconTextButton({
    required this.icon,
    required this.text,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          icon,
          width: 16,
          height: 16,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.grey900,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
