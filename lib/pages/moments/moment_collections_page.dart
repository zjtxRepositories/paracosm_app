import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/moment_post_model.dart';
import 'package:paracosm/core/models/social_Invitation_model.dart';
import 'package:paracosm/core/models/social_media_model.dart';
import 'package:paracosm/core/network/api/social_circle_note_api.dart';
import 'package:paracosm/core/network/api/social_circle_user_api.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/im/listener/im_data_center.dart';
import 'package:paracosm/modules/im/message/moment_post_share_message.dart';
import 'package:paracosm/modules/im/message/send/im_sender.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/chat_forward_target_modal.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/app_media_gallery.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import 'moment_post_card.dart';

class MomentCollectionsPage extends StatefulWidget {
  const MomentCollectionsPage({super.key});

  @override
  State<MomentCollectionsPage> createState() => _MomentCollectionsPageState();
}

class _MomentCollectionsPageState extends State<MomentCollectionsPage> {
  static const int _pageSize = 20;

  final List<MomentPostModel> _items = [];
  List<String> _followIds = [];
  List<String> _blockIds = [];
  int _page = 0;
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _refreshing = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _page = 0;
      _hasMore = true;
      _items.clear();
    });

    try {
      final results = await Future.wait([
        _fetchPage(0),
        SocialCircleUserApi.getSocialCircleUserFollow(),
        SocialCircleUserApi.getSocialCircleUserBlock(),
      ]);
      if (!mounted) return;
      final posts = results[0] as List<MomentPostModel>;
      setState(() {
        _items.addAll(posts);
        _followIds = results[1] as List<String>;
        _blockIds = results[2] as List<String>;
        _hasMore = posts.length >= _pageSize;
        _page = 1;
        _initialLoading = false;
      });
    } catch (e) {
      debugPrint('load collected moments failed: $e');
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;

    setState(() {
      _refreshing = true;
    });

    try {
      final posts = await _fetchPage(0);
      final followIds = await SocialCircleUserApi.getSocialCircleUserFollow();
      final blockIds = await SocialCircleUserApi.getSocialCircleUserBlock();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(posts);
        _followIds = followIds;
        _blockIds = blockIds;
        _hasMore = posts.length >= _pageSize;
        _page = 1;
      });
    } catch (e) {
      debugPrint('refresh collected moments failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final posts = await _fetchPage(_page);
      if (!mounted) return;
      setState(() {
        _items.addAll(posts);
        _hasMore = posts.length >= _pageSize;
        _page += 1;
      });
    } catch (e) {
      debugPrint('load more collected moments failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingMore = false;
        });
      }
    }
  }

  Future<List<MomentPostModel>> _fetchPage(int page) async {
    final list = await SocialCircleNoteApi.getSocialCircleCollectList(
      page: page,
      size: _pageSize,
    );
    final models = list.map((item) => MomentPostModel(item: item)).toList();
    await MomentsResolver().resolve(models);
    return models;
  }

  Future<void> _toggleLike(SocialInvitationModel item) async {
    final nextIsLike = !item.isLike;
    final failureText = AppLocalizations.of(context)!.momentsLikeFailed;
    AppLoading.show();
    final success = await SocialCircleNoteApi.socialCircleNoteLikeToggle(
      item.noteId,
      nextIsLike,
    );
    AppLoading.dismiss();
    if (!success) {
      AppToast.show(failureText);
      return;
    }
    if (!mounted) return;
    setState(() {
      item.isLike = nextIsLike;
      item.likes = _nextCount(item.likes, nextIsLike);
    });
  }

  Future<void> _toggleCollect(MomentPostModel model) async {
    final item = model.item;
    final failureText = AppLocalizations.of(context)!.momentsCollectFailed;
    AppLoading.show();
    final success = await SocialCircleNoteApi.socialCircleNoteCollectToggle(
      item.noteId,
      false,
    );
    AppLoading.dismiss();
    if (!success) {
      AppToast.show(failureText);
      return;
    }
    if (!mounted) return;
    setState(() {
      _items.removeWhere((e) => e.item.noteId == item.noteId);
    });
  }

  Future<void> _toggleShare(SocialInvitationModel item) async {
    final targets = await ChatForwardTargetModal.show(
      context,
      friends: ImDataCenter().friendListSnapshot,
      groups: ImDataCenter().groupListSnapshot,
    );
    if (!mounted || targets == null || targets.isEmpty) return;

    final shareData = MomentPostShareData.fromPost(item);
    if (!shareData.isValid) {
      AppToast.show(AppLocalizations.of(context)!.momentsShareFailed);
      return;
    }

    var successCount = 0;
    AppLoading.show();
    try {
      for (final target in targets) {
        final sent = await ImSender.instance.send(
          message: MomentPostShareMessage(
            conversationType: target.conversationType,
            targetId: target.targetId,
            channelId: target.channelId,
            data: shareData,
          ),
        );
        if (!sent) continue;
        successCount++;
        if (target.conversationType == RCIMIWConversationType.private) {
          unawaited(_recordShare(item, target.targetId));
        }
      }
    } catch (e) {
      debugPrint('share collected moment failed: $e');
    } finally {
      AppLoading.dismiss();
    }

    if (!mounted) return;
    AppToast.show(
      successCount > 0
          ? AppLocalizations.of(context)!.momentsShareSuccess
          : AppLocalizations.of(context)!.momentsShareFailed,
    );
    if (successCount == 0) return;

    setState(() {
      item.shares += successCount;
    });
  }

  Future<void> _recordShare(SocialInvitationModel item, String toUserId) async {
    final fromUserId = AccountManager().currentAccount?.accountId ?? '';
    if (fromUserId.isEmpty || toUserId.isEmpty) return;

    try {
      await SocialCircleNoteApi.socialCircleNoteShare(
        fromUserId,
        toUserId,
        item.noteId,
      );
    } catch (e) {
      debugPrint('record collected moment share failed: $e');
    }
  }

  Future<void> _toggleFollow(SocialInvitationModel item) async {
    final walletAddress = item.walletAddress;
    final failureText = AppLocalizations.of(context)!.momentsFollowFailed;
    if (walletAddress.isEmpty) {
      AppToast.show(failureText);
      return;
    }

    final nextIsFollow = !_followIds.contains(walletAddress);
    AppLoading.show();
    final success = await SocialCircleUserApi.socialCircleUserFollowToggle(
      walletAddress,
      nextIsFollow,
    );
    AppLoading.dismiss();
    if (!success) {
      AppToast.show(failureText);
      return;
    }
    if (!mounted) return;
    setState(() {
      if (nextIsFollow) {
        _followIds.add(walletAddress);
      } else {
        _followIds.remove(walletAddress);
      }
    });
  }

  Future<void> _toggleBlock(SocialInvitationModel item) async {
    final walletAddress = item.walletAddress;
    final failureText = AppLocalizations.of(context)!.momentsBlockFailed;
    if (walletAddress.isEmpty) {
      AppToast.show(failureText);
      return;
    }

    final nextIsBlock = !_blockIds.contains(walletAddress);
    AppLoading.show();
    final success = await SocialCircleUserApi.socialCircleUserBlockToggle(
      walletAddress,
      nextIsBlock,
    );
    AppLoading.dismiss();
    if (!success) {
      AppToast.show(failureText);
      return;
    }
    if (!mounted) return;
    setState(() {
      if (nextIsBlock) {
        _blockIds.add(walletAddress);
      } else {
        _blockIds.remove(walletAddress);
      }
    });
  }

  void _toggleReport(SocialInvitationModel item) {
    context.push('/moment-report');
  }

  void _toggleMedia(List<SocialMediaModel> medias, int initialIndex) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => AppMediaGallery(
          list: medias.map((e) => e.toMediaItem()).toList(),
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  int _nextCount(int count, bool increment) {
    if (increment) return count + 1;
    return count > 0 ? count - 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPage(
      title: l10n.translate('moments_my_collections'),
      backgroundColor: AppColors.white,
      navBackgroundColor: AppColors.white,
      showNavBorder: true,
      child: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: _items.isEmpty
          ? _buildEmptyBody(l10n)
          : NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent - 100 &&
                    !_loadingMore &&
                    !_refreshing) {
                  _loadMore();
                }
                return false;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: _items.length + (_loadingMore ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == _items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final model = _items[index];
                  final item = model.item;
                  return MomentPostCard(
                    model: model,
                    isFollowing: _followIds.contains(item.walletAddress),
                    isBlock: _blockIds.contains(item.walletAddress),
                    onLike: () => _toggleLike(item),
                    onCollect: () => _toggleCollect(model),
                    onShare: () => _toggleShare(item),
                    onFollow: () => _toggleFollow(item),
                    onBlock: () => _toggleBlock(item),
                    onReport: () => _toggleReport(item),
                    onMediaTap: (i) => _toggleMedia(item.media, i),
                    onTap: () => context.push(
                      '/moment-post-detail',
                      extra: {
                        'item': model,
                        'isFollowing': _followIds.contains(item.walletAddress),
                        'isBlock': _blockIds.contains(item.walletAddress),
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyBody(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: AppEmptyView(
                text: l10n.translate('moments_no_collections'),
                bottomOffset: 80,
              ),
            ),
          ],
        );
      },
    );
  }
}
