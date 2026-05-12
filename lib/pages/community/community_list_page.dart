import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/util/string_util.dart';

import '../../core/models/community_model.dart';
import '../../core/network/api/community_list_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/chat/group_avatar_widget.dart';

class CommunityListPage extends StatefulWidget {
  final RoomType type;
  const CommunityListPage({super.key, required this.type});

  @override
  State<CommunityListPage> createState() =>
      _CommunityListPageState();
}

class _CommunityListPageState
    extends State<CommunityListPage>
    with AutomaticKeepAliveClientMixin {

  List<CommunityModel> _list = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final data = await CommunityListApi.get(
      pageIndex: 0,
      roomType: widget.type,
    );

    if (!mounted) return;

    setState(() {
      _list = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_list.isEmpty) {
      return const Center(
        child: Text('No DAO'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _list.length,
      itemBuilder: (context, index) {
        final item = _list[index];

        return _buildCommunityItem(item);
      },
    );
  }

  Widget _buildCommunityItem(CommunityModel item) {
    return GestureDetector(
      onTap: () => context.push('/community-detail',extra: item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧：社区群组头像 (2x2网格)
                  GroupAvatarWidget(
                    groupId: item.communityParam?.groupId ?? '',
                    portraitUri: item.avatarUrl,
                    size: 42,
                  ),
                  const SizedBox(width: 8),
                  // 右侧：核心内容区域
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 第一行：社区名称 + 成员数 + 地址信息
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.h2.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey900,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Image.asset(
                              'assets/images/community/user.png',
                              width: 12,
                              height: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              ' ${item.memberNum}',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 10,
                                color: AppColors.grey400,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Image.asset(
                              'assets/images/community/location.png',
                              width: 12,
                              height: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              ' ${ellipsisMiddle(item.displayAddress,head: 5,tail: 5)}',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 10,
                                color: AppColors.grey400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // 第二行：描述信息/标签列表
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: 70,
                                ),
                                child: item.desc != null
                                    ? Text(
                                  item.desc ?? '',
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 10,
                                    color: AppColors.grey400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                                    : ((item.tags ?? []).isNotEmpty
                                    ? Wrap(
                                  spacing: 4,
                                  children: item.tags!
                                      .map((tag) => _buildTag(tag))
                                      .toList(),
                                )
                                    : const SizedBox.shrink()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // if (trend != null)
            //   Positioned(
            //     right: 0,
            //     bottom: 0,
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 9,
            //         vertical: 3,
            //       ),
            //       decoration: BoxDecoration(
            //         color: AppColors.grey100,
            //         borderRadius: const BorderRadius.only(
            //           topLeft: Radius.circular(12),
            //           bottomRight: Radius.circular(12),
            //         ),
            //       ),
            //       child: Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Icon(
            //             trend.startsWith('+')
            //                 ? Icons.trending_up
            //                 : Icons.trending_down,
            //             size: 12,
            //             color: trend.startsWith('+')
            //                 ? AppColors.primaryDark
            //                 : AppColors.error,
            //           ),
            //           const SizedBox(width: 4),
            //           Text(
            //             trend.substring(1).trim(),
            //             style: AppTextStyles.body.copyWith(
            //               fontSize: 10,
            //               color: trend.startsWith('+')
            //                   ? AppColors.primaryDark
            //                   : AppColors.error,
            //               fontWeight: FontWeight.w500,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  /// 构建小标签组件
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          fontSize: 10,
          color: AppColors.grey400,
        ),
      ),
    );
  }
  /// KeepAlive
  @override
  bool get wantKeepAlive => true;
}