import 'package:flutter/material.dart';
import 'package:paracosm/modules/invite/model/invite_models.dart';
import 'package:paracosm/modules/invite/service/invite_service.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_network_image.dart';

class InviteChildrenPage extends StatefulWidget {
  const InviteChildrenPage({super.key});

  @override
  State<InviteChildrenPage> createState() => _InviteChildrenPageState();
}

class _InviteChildrenPageState extends State<InviteChildrenPage> {
  static const _pageSize = 20;

  final _service = InviteService();
  final _scrollController = ScrollController();

  final List<InviteUser> _children = [];
  int _page = 1;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _refresh();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isInitialLoading) return;
    if (_scrollController.position.extentAfter < 160) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isInitialLoading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
    });

    try {
      final page = await _service.getChildren(page: 1, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        _children
          ..clear()
          ..addAll(page.children);
        _hasMore = page.hasMore;
        _isInitialLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _page + 1;
      final page = await _service.getChildren(
        page: nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _page = nextPage;
        _children.addAll(page.children);
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: true,
      title: AppLocalizations.currentText('invite_children_title'),
      backgroundColor: AppColors.grey100,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          AppLocalizations.currentText('invite_load_failed'),
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    if (_children.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: AppEmptyView(
                text: AppLocalizations.currentText('invite_no_children'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _children.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _children.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _InviteChildItem(user: _children[index]);
        },
      ),
    );
  }
}

class _InviteChildItem extends StatelessWidget {
  const _InviteChildItem({required this.user});

  final InviteUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          AppNetworkImage(
            url: user.avatar,
            width: 44,
            height: 44,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  user.userId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(color: AppColors.grey500),
                ),
                if (user.boundAt.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.boundAt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            user.status.isEmpty ? 'BOUND' : user.status,
            style: AppTextStyles.overline.copyWith(
              color: AppColors.primaryDark,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
