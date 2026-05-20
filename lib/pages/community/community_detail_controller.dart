import 'package:flutter/material.dart';
import 'package:paracosm/core/models/community_model.dart';
import 'package:paracosm/core/models/group_member_model.dart';
import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/core/network/api/community_dynamics_api.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../widgets/base/app_localizations.dart';
import '../../widgets/common/app_toast.dart';

class CommunityDetailController extends ChangeNotifier {
  CommunityDetailController({required this.communityModel});

  /// 社区数据
  final CommunityModel communityModel;

  /// 群信息
  GroupModel? group;

  /// 群成员
  List<GroupMemberModel> members = [];

  /// 动态列表
  List<CommunityPostModel> dynamics = [];

  /// 当前选中的网络
  String selectedNetwork = 'Ethereum';

  /// 分页
  int pageIndex = 0;
  final int pageSize = 20;

  /// 是否还有更多
  bool hasMore = true;

  /// 加载状态
  bool isLoading = false;

  /// 首次加载
  bool isInitialized = false;

  /// 群 ID
  String? get groupId => communityModel.communityParam?.groupId;

  /// 房间 ID
  String? get roomId => communityModel.id;

  /// 是否已加入群
  bool get isJoined =>
      group != null && group?.info.role != RCIMIWGroupMemberRole.undef;

  /// 初始化
  Future<void> init() async {
    await Future.wait([fetchGroupInfo(), fetchDynamics(refresh: true)]);

    isInitialized = true;
    notifyListeners();
  }

  /// 获取群信息
  Future<void> fetchGroupInfo() async {
    if (groupId == null || groupId!.isEmpty) {
      return;
    }

    final groups = await ImGroupManager().getGroupsInfo([groupId!]);

    if (groups == null || groups.isEmpty) {
      return;
    }

    group = GroupModel(info: groups.first);

    notifyListeners();

    members = await group!.members;

    notifyListeners();
  }

  /// 获取动态列表
  Future<void> fetchDynamics({bool refresh = false}) async {
    if (roomId == null || roomId!.isEmpty) {
      return;
    }

    if (isLoading) {
      return;
    }

    if (!hasMore && !refresh) {
      return;
    }

    isLoading = true;

    if (refresh) {
      pageIndex = 0;
      hasMore = true;
    }

    notifyListeners();

    try {
      final result = await CommunityDynamicsApi.get(
        roomId: roomId!,
        pageIndex: pageIndex,
        pageSize: pageSize,
      );

      final list = result?.pageData ?? [];

      if (refresh) {
        dynamics = list;
      } else {
        dynamics.addAll(list);
      }

      /// 判断是否还有更多
      hasMore = pageIndex < (result?.pageCount ?? 0) - 1;

      /// 下一页
      if (hasMore) {
        pageIndex++;
      }
    } catch (e) {
      debugPrint('CommunityDetailController fetchDynamics error: $e');
    } finally {
      await CommunityResolver().resolve(dynamics);
      isLoading = false;
      notifyListeners();
    }
  }

  /// 下拉刷新
  Future<void> refresh() async {
    await fetchDynamics(refresh: true);
  }

  /// 加载更多
  Future<void> loadMore() async {
    await fetchDynamics();
  }

  Future<void> joined() async {
    final groupInfo = group;
    if (groupInfo == null) return;
    final isJoined = await ImGroupManager().joinGroup(
      groupInfo.info.groupId ?? '',
    );
    if (!isJoined) {
      AppToast.show(AppLocalizations.currentText('community_join_failed'));
      return;
    }
    AppToast.show(AppLocalizations.currentText('community_join_success'));
    group!.info.role = RCIMIWGroupMemberRole.normal;
    notifyListeners();
  }

  /// 销毁
  void disposeController() {
    dynamics.clear();
    members.clear();
  }

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }
}
