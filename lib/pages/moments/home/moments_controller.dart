import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/network/models/social_Invitation_model.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import '../../../core/network/api/social_circle_note_api.dart';
import '../../../core/network/api/social_circle_user_api.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/modals/share_modals.dart';

/// ==========================
/// Controller
/// ==========================
class MomentsController extends ChangeNotifier {
  final List<SocialInvitationModel> _items = [];
  List<SocialInvitationModel> get items => _items;
  List<String> _followIds = [];
  List<String> get followIds => _followIds;
  List<String> _blockIds = [];
  List<String> get blockIds => _blockIds;
  final List<StoryData> _stories = [
    const StoryData(
      id: 'add',
      label: '',
      avatar: 'assets/images/moments/add-moment.png',
      insideColor: AppColors.grey200,
      outsideColor: Colors.transparent,
      showPlusIcon: true,
      isMine: true,
    ),
  ];

  List<StoryData> get stories => _stories;

  int _page = 1;
  final int _pageSize = 10;
  bool _loading = false;
  bool _hasMore = true;

  bool get loading => _loading;
  bool get hasMore => _hasMore;

  /// 初始化
  Future<void> init() async {
    _items.clear();
    _page = 1;
    _hasMore = true;
    await fetchMore();
    _getFollowList();
    _getBlockList();
  }

  /// 分页加载
  Future<void> fetchMore() async {
    if (_loading || !_hasMore) return;

    _loading = true;
    notifyListeners();

    /// 👉 TODO: 换成你的真实接口
    final data = await _fetchData();

    if (data.length < _pageSize) {
      _hasMore = false;
    }

    _items.addAll(data);
    _page++;

    _loading = false;
    notifyListeners();
  }

  /// 下拉刷新
  Future<void> refresh() async {
    _items.clear();
    _page = 1;
    _hasMore = true;
    notifyListeners();

    await fetchMore();
  }

  /// 点赞
  Future<void> toggleLike(SocialInvitationModel item) async {
    AppLoading.show();
    item.isLike = !item.isLike;
    final result = await SocialCircleNoteApi.socialCircleNoteLikeToggle(item.noteId, item.isLike);
    AppLoading.dismiss();
    if (!result){
      AppToast.show('点赞失败！');
      return;
    }
    item.likes += item.isLike == true ? 1 : -1;
    notifyListeners();
  }

  /// 收藏
  Future<void> toggleCollect(SocialInvitationModel item) async {
    AppLoading.show();
    item.isCollect = !item.isCollect ;
    final result = await SocialCircleNoteApi.socialCircleNoteCollectToggle(item.noteId, item.isCollect);
    AppLoading.dismiss();
    if (!result){
      AppToast.show('收藏失败！');
      return;
    }
    item.collects += item.isCollect == true ? 1 : -1;
    notifyListeners();
  }

  /// 关注
  Future<void> toggleFollow(SocialInvitationModel item) async {
    AppLoading.show();
    bool isFollow = !_followIds.contains(item.userId);
    final result = await SocialCircleUserApi.socialCircleUserFollowToggle(item.userId, isFollow);
    AppLoading.dismiss();
    if (!result){
      AppToast.show('关注失败！');
      return;
    }
    if (isFollow){
      _followIds.add(item.userId);
    }else{
      _followIds.remove(item.userId);
    }
    notifyListeners();
  }

  /// 发送评论
  Future<SocialInvitationModel> sendComment(SocialInvitationModel item,String content,String rootId,String noteId,String toUserId) async {
    AppLoading.show();
    final result = await SocialCircleNoteApi.socialCircleNoteReview(noteId, toUserId, content, rootId);
    AppLoading.dismiss();
    if (!result){
      AppToast.show('发布失败！');
      throw '发布失败！';
    }
    final note = await SocialCircleNoteApi.getSocialCircleNoteInfo(item.noteId);
    if (note == null) throw '没有获取到';
    item.reviewInfo = note.reviewInfo;
    item.reviews = note.reviews;
    notifyListeners();
    return note;
  }

  /// 分享
  void toggleShare(SocialInvitationModel item,BuildContext context) {
    ShareModals.show(context);
  }

  /// 拉黑
  Future<void> toggleBlock(SocialInvitationModel item) async {
    AppLoading.show();
    bool isBlock = !_blockIds.contains(item.userId);
    final result = await SocialCircleUserApi.socialCircleUserBlockToggle(item.userId, isBlock);
    AppLoading.dismiss();
    if (!result){
      AppToast.show('拉黑失败！');
      return;
    }
    if (isBlock){
      _blockIds.add(item.userId);
    }else{
      _blockIds.remove(item.userId);
    }
    notifyListeners();
  }

  /// 举报
  void toggleReport(SocialInvitationModel item,BuildContext context) {
    context.push('/moment-report');
  }


  /// 数据
  Future<List<SocialInvitationModel>> _fetchData() async {
    return await SocialCircleNoteApi.getSocialCircleNoteList(
      _page.toString(),
      _pageSize.toString(),
    );
  }

  /// 关注列表
  Future<void> _getFollowList() async {
    List<String> list = await SocialCircleUserApi.getSocialCircleUserFollow();
    _followIds = list;
    print('fllowing:$_followIds');
    notifyListeners();
  }

  /// 拉黑列表
  Future<void> _getBlockList() async {
    List<String> list = await SocialCircleUserApi.getSocialCircleUserBlock();
    _blockIds = list;
    print('_blockIds:$_blockIds');
    notifyListeners();
  }
}

class StoryData {
  final String id;
  final String label;
  final String avatar;

  final Color insideColor;
  final Color outsideColor;

  /// UI状态
  final bool showAddBadge;
  final bool showPlusIcon;

  /// 社交状态（新增，不影响UI）
  final bool isViewed;
  final bool isMine;
  final int? storyCount;

  const StoryData({
    this.id = '',
    required this.label,
    required this.avatar,
    required this.insideColor,
    required this.outsideColor,
    this.showAddBadge = false,
    this.showPlusIcon = false,

    /// 新增字段（不影响你当前UI）
    this.isViewed = false,
    this.isMine = false,
    this.storyCount,
  });

  StoryData copyWith({
    String? id,
    String? label,
    String? avatar,
    Color? insideColor,
    Color? outsideColor,
    bool? showAddBadge,
    bool? showPlusIcon,
    bool? isViewed,
    bool? isMine,
    int? storyCount,
  }) {
    return StoryData(
      id: id ?? this.id,
      label: label ?? this.label,
      avatar: avatar ?? this.avatar,
      insideColor: insideColor ?? this.insideColor,
      outsideColor: outsideColor ?? this.outsideColor,
      showAddBadge: showAddBadge ?? this.showAddBadge,
      showPlusIcon: showPlusIcon ?? this.showPlusIcon,
      isViewed: isViewed ?? this.isViewed,
      isMine: isMine ?? this.isMine,
      storyCount: storyCount ?? this.storyCount,
    );
  }
}