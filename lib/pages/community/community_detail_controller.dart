import 'package:flutter/material.dart';
import 'package:paracosm/core/models/community_model.dart';
import 'package:paracosm/core/models/group_member_model.dart';
import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/core/network/api/community_dynamics_api.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../core/models/custom_message_model.dart';
import '../../modules/im/manager/im_engine_manager.dart';
import '../../modules/im/message/base/im_message.dart';
import '../../modules/im/message/send/im_sender.dart';
import '../../widgets/base/app_localizations.dart';
import '../../core/models/social_media_model.dart';
import '../../widgets/common/app_media_gallery.dart';
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
    final result = await ImGroupManager().joinGroupWithResult(
      groupInfo.info.groupId ?? '',
      groupInfo: groupInfo.info,
    );

    switch (result.status) {
      case JoinGroupStatus.waitingManagerApproval:
        AppToast.show(
          AppLocalizations.currentText('chat_group_join_waiting_approval'),
        );
        return;
      case JoinGroupStatus.failed:
        AppToast.show(AppLocalizations.currentText('community_join_failed'));
        return;
      case JoinGroupStatus.joined:
        break;
    }

    final currentUserId = IMEngineManager().currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      return;
    }
    AppToast.show(AppLocalizations.currentText('community_join_success'));
    group!.info.role = RCIMIWGroupMemberRole.normal;
    notifyListeners();
    final message = CustomMessage(
      targetId: groupInfo.info.groupId ?? '',
      customMessageType: CustomMessageType.groupJoined,
      conversationType: RCIMIWConversationType.group,
      userIds: [currentUserId],
    );
    await ImSender.instance.send(message: message);
  }

  void toggleMedia(
    List<SocialMediaModel> medias,
    int initialIndex,
    BuildContext context,
  ) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => AppMediaGallery(
          list: medias.map((e) => e.toMediaItem()).toList(),
          initialIndex: initialIndex,
        ),
      ),
    );
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
