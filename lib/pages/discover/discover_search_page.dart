import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_network_image.dart';
import 'package:paracosm/widgets/common/app_search_input.dart';

import '../../core/models/dApp_hive.dart';
import 'discover_search_utils.dart';

class DiscoverSearchPage extends StatefulWidget {
  final List<DAppHive> dapps;

  const DiscoverSearchPage({super.key, required this.dapps});

  @override
  State<DiscoverSearchPage> createState() => _DiscoverSearchPageState();
}

class _DiscoverSearchPageState extends State<DiscoverSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<DAppHive> _results = [];
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    setState(() {
      _query = value;
      _results = DiscoverSearchUtils.fuzzySearch(widget.dapps, value);
    });
  }

  void _openDApp(DAppHive dapp) {
    context.push('/dapp', extra: dapp);
  }

  void _openInput(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      return;
    }

    final normalizedUrl = DiscoverSearchUtils.normalizeUrl(query);
    if (normalizedUrl != null) {
      _openDApp(
        DAppHive(name: Uri.parse(normalizedUrl).host, url: normalizedUrl),
      );
      return;
    }

    if (_results.isEmpty) {
      final searchUrl = DiscoverSearchUtils.webSearchUrl(query);
      _openDApp(DAppHive(name: query, url: searchUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: true,
      isCustomHeader: true,
      renderCustomHeader: _buildHeader(context),
      child: _buildBody(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppSearchInput(
              controller: _controller,
              autofocus: true,
              hintText: l10n.discoverSearchHint,
              onChanged: _handleChanged,
              onSubmitted: _openInput,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.pop(),
            child: Text(
              l10n.chatSearchCancel,
              style: AppTextStyles.body.copyWith(
                color: AppColors.primaryLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_query.trim().isEmpty) {
      return AppEmptyView(
        text: AppLocalizations.of(context)!.discoverSearchEmptyHint,
      );
    }

    final normalizedUrl = DiscoverSearchUtils.normalizeUrl(_query);
    if (normalizedUrl != null) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [_buildOpenUrlItem(normalizedUrl)],
      );
    }

    if (_results.isEmpty) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [_buildWebSearchItem(_query.trim())],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _results.length + 1,
      itemBuilder: (context, index) {
        if (index == _results.length) {
          return _buildWebSearchItem(_query.trim());
        }
        return _buildDAppItem(_results[index]);
      },
    );
  }

  Widget _buildOpenUrlItem(String url) {
    return _SearchActionItem(
      icon: Icons.language,
      title: url,
      subtitle: AppLocalizations.of(context)!.discoverSearchOpenUrl,
      onTap: () => _openInput(url),
    );
  }

  Widget _buildWebSearchItem(String query) {
    return _SearchActionItem(
      icon: Icons.search,
      title: query,
      subtitle: AppLocalizations.of(context)!.discoverSearchWeb,
      onTap: () {
        final searchUrl = DiscoverSearchUtils.webSearchUrl(query);
        _openDApp(DAppHive(name: query, url: searchUrl));
      },
    );
  }

  Widget _buildDAppItem(DAppHive item) {
    return GestureDetector(
      onTap: () => _openDApp(item),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppNetworkImage(
                  url: item.headUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.grey100, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.grey900,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.des?.isNotEmpty == true ? item.des! : item.url,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey400,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SearchActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.white,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.grey900),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.grey100, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.grey900,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
