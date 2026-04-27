import 'package:flutter/material.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_checkbox.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/chat/select_members_modal.dart';

class NewPostPage extends StatefulWidget {
  final bool isRetweet;

  const NewPostPage({super.key, this.isRetweet = false});

  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  String _visibilityId = 'public';
  int _partiallyVisibleCount = 0;
  bool _showRetweetDeleteBar = false;
  bool _showRetweetPreview = true;

  void _showDeleteBar() {
    if (!_showRetweetDeleteBar) {
      setState(() {
        _showRetweetDeleteBar = true;
      });
    }
  }

  void _hideDeleteBar() {
    if (_showRetweetDeleteBar) {
      setState(() {
        _showRetweetDeleteBar = false;
      });
    }
  }

  void _deleteRetweetPreview() {
    setState(() {
      _showRetweetPreview = false;
      _showRetweetDeleteBar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pageTitle = widget.isRetweet
        ? l10n.translate('moments_retweet_post_title')
        : l10n.translate('moments_new_post_title');

    return AppPage(
      title: pageTitle,
      backgroundColor: Colors.white,
      navBackgroundColor: Colors.white,
      showNavBorder: true,
      headerActions: [
        GestureDetector(
          onTap: () {
            _showSaveDraftHintModal(context);
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Image.asset(
              'assets/images/moments/save-btn.png',
              width: 32,
              height: 32,
            ),
          ),
        ),
      ],
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _hideDeleteBar,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            minLines: 1,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.grey900,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.translate('moments_thoughts_placeholder'),
                              hintStyle: AppTextStyles.body.copyWith(
                                color: AppColors.grey400,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                            // 输入框占位文案保持本地化，布局不变。
                          Row(
                            children: [
                              _ImagePreview(
                                imagePath: 'assets/images/moments/moment1.png',
                              ),
                              const SizedBox(width: 8),
                              _ImagePreview(
                                imagePath: 'assets/images/moments/moment1.png',
                              ),
                              const SizedBox(width: 8),
                              _UploadTile(),
                            ],
                          ),
                          if (widget.isRetweet && _showRetweetPreview) ...[
                            const SizedBox(height: 16),
                            _RetweetPreviewCard(
                              onLongPress: _showDeleteBar,
                            ),
                            const SizedBox(height: 80),
                          ] else ...[
                            const SizedBox(height: 80),
                          ],
                          Container(
                            height: 1,
                            color: AppColors.grey100,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/community/user.png',
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.translate('moments_who_can_see'),
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.grey900,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _showVisibilityModal(context);
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      _buildVisibilityTitle(l10n),
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.grey400,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Image.asset(
                                      'assets/images/common/next.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: l10n.translate('moments_release'),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          if (_showRetweetDeleteBar)
            Positioned.fill(
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _deleteRetweetPreview,
                        child: Container(
                          height: 82,
                          color: AppColors.error,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/chat/delete-msg.png',
                                width: 26,
                                height: 26,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.translate('common_delete'),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _buildVisibilityTitle(AppLocalizations l10n) {
    switch (_visibilityId) {
      case 'private':
        return l10n.translate('moments_private');
      case 'visible_friends':
        return l10n.translate('moments_visible_to_friends');
      case 'partially_visible':
        return l10n.translate('moments_partially_visible');
      case 'hidden_everyone':
        return l10n.translate('moments_dont_show_it_to_anyone');
      case 'public':
      default:
        return l10n.translate('moments_public');
    }
  }

  void _showVisibilityModal(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = <_VisibilityOption>[
      _VisibilityOption(
        id: 'public',
        title: l10n.translate('moments_public'),
        subtitle: l10n.translate('moments_visible_to_everyone'),
      ),
      _VisibilityOption(
        id: 'private',
        title: l10n.translate('moments_private'),
        subtitle: l10n.translate('moments_visible_only_to_me'),
      ),
      _VisibilityOption(
        id: 'visible_friends',
        title: l10n.translate('moments_visible_to_friends'),
        subtitle: l10n.translate('moments_visible_to_all_friend'),
      ),
      _VisibilityOption(
        id: 'partially_visible',
        title: l10n.translate('moments_partially_visible'),
        subtitle: l10n.translate('moments_visible_to_selected_friends').replaceAll('{count}', '0'),
        countSubtitleKey: 'moments_visible_to_selected_friends',
        showChevron: true,
      ),
      _VisibilityOption(
        id: 'hidden_everyone',
        title: l10n.translate('moments_dont_show_it_to_anyone'),
        subtitle: l10n.translate('moments_selected_friends_invisible').replaceAll('{count}', '0'),
        countSubtitleKey: 'moments_selected_friends_invisible',
        showChevron: true,
      ),
    ];

    AppModal.show(
      context,
        title: l10n.translate('moments_who_can_watch'),
        confirmText: null,
      child: _VisibilityModalContent(
        options: options,
        selectedId: _visibilityId,
        partiallyVisibleCount: _partiallyVisibleCount,
        onSelected: (option) {
          setState(() {
            _visibilityId = option.id;
          });
          Navigator.pop(context);
        },
        onPartiallyVisibleSelected: (count) {
          setState(() {
            _visibilityId = 'partially_visible';
            _partiallyVisibleCount = count;
          });
        },
      ),
      onConfirm: () {},
    );
  }
}

class _VisibilityOption {
  final String id;
  final String title;
  final String subtitle;
  final String? countSubtitleKey;
  final bool showChevron;

  const _VisibilityOption({
    required this.id,
    required this.title,
    required this.subtitle,
    this.countSubtitleKey,
    this.showChevron = false,
  });
}

class _VisibilityModalContent extends StatefulWidget {
  final List<_VisibilityOption> options;
  final String selectedId;
  final int partiallyVisibleCount;
  final ValueChanged<_VisibilityOption> onSelected;
  final ValueChanged<int> onPartiallyVisibleSelected;

  const _VisibilityModalContent({
    required this.options,
    required this.selectedId,
    required this.partiallyVisibleCount,
    required this.onSelected,
    required this.onPartiallyVisibleSelected,
  });

  @override
  State<_VisibilityModalContent> createState() => _VisibilityModalContentState();
}

class _VisibilityModalContentState extends State<_VisibilityModalContent> {
  late String _selectedId;
  late int _partiallyVisibleCount;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
    _partiallyVisibleCount = widget.partiallyVisibleCount;
  }

  @override
  void didUpdateWidget(covariant _VisibilityModalContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      _selectedId = widget.selectedId;
    }
    if (oldWidget.partiallyVisibleCount != widget.partiallyVisibleCount) {
      _partiallyVisibleCount = widget.partiallyVisibleCount;
    }
  }

  Future<void> _handleTap(_VisibilityOption option) async {
    if (option.id == 'partially_visible') {
      final selectedMembers = await SelectMembersModal.show(
        context,
        showTag: false,
        confirmText: AppLocalizations.of(context)!.translate('moments_ok'),
        showSelectedCount: true,
      );
      if (!mounted || selectedMembers == null) {
        return;
      }

      setState(() {
        _selectedId = option.id;
        _partiallyVisibleCount = selectedMembers.length;
      });
      widget.onPartiallyVisibleSelected(selectedMembers.length);
      return;
    }

    widget.onSelected(option);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widget.options
          .map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VisibilityModalItem(
                option: option,
                selected: option.id == _selectedId,
                subtitle: option.subtitle,
                countSubtitleKey: option.countSubtitleKey,
                countValue:
                    option.id == 'partially_visible' ? _partiallyVisibleCount : null,
                onTap: () => _handleTap(option),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _VisibilityModalItem extends StatelessWidget {
  final _VisibilityOption option;
  final bool selected;
  final String subtitle;
  final String? countSubtitleKey;
  final int? countValue;
  final VoidCallback onTap;

  const _VisibilityModalItem({
    required this.option,
    required this.selected,
    required this.subtitle,
    required this.countSubtitleKey,
    required this.countValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final int count = countValue ?? 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Row(
          children: [
            AppCheckbox(
              value: selected,
              isRadio: false,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.grey900,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  countSubtitleKey == null
                      ? Text(
                          subtitle,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey400,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      : _buildCountSubtitle(l10n, countSubtitleKey!, count),
                ],
              ),
            ),
            if (option.showChevron) ...[
              // const SizedBox(width: 16),
              Image.asset(
                'assets/images/common/next.png',
                width: 16,
                height: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCountSubtitle(
    AppLocalizations l10n,
    String templateKey,
    int count,
  ) {
    final template = l10n.translate(templateKey);
    final parts = template.split('{count}');

    if (parts.length < 2) {
      return Text(
        template,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey400,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: parts.first,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey400,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(
            text: '$count',
            style: AppTextStyles.caption.copyWith(
              color: count > 0 ? AppColors.grey800 : AppColors.grey400,
              fontSize: 12,
              fontWeight: count > 0 ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          TextSpan(
            text: parts.sublist(1).join('{count}'),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey400,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

void _showSaveDraftHintModal(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  AppModal.show(
    context,
    title: l10n.translate('moments_hint'),
    description: l10n.translate('moments_whether_to_save_the_edited_content'),
    confirmText: l10n.translate('moments_save_drafts'),
    cancelText: l10n.translate('moments_dont_save'),
    confirmWidth: 161,
    cancelWidth: 161,
    cancelBorder: const BorderSide(color: AppColors.grey300),
    icon: Image.asset(
      'assets/images/wallet/bell-icon.png',
      width: 120,
      height: 120,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          color: AppColors.grey100,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.notifications_active_outlined,
          size: 64,
          color: AppColors.warning,
        ),
      ),
    ),
    onConfirm: () {
      Navigator.pop(context);
    },
  );
}

class _ImagePreview extends StatelessWidget {
  final String imagePath;

  const _ImagePreview({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        imagePath,
        width: 61,
        height: 61,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/moments/upload.png',
      width: 61,
      height: 61,
      fit: BoxFit.contain,
    );
  }
}

class _RetweetPreviewCard extends StatelessWidget {
  final VoidCallback? onLongPress;

  const _RetweetPreviewCard({this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/images/chat/avatar.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adila',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.grey900,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'What kind of photos can a novice take after learning by himself for half a What kind of photos can a novice take after learning by himself for half',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.grey400,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
