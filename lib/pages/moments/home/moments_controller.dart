import 'package:flutter/material.dart';
import 'package:paracosm/core/network/models/social_Invitation_model.dart';
import 'package:path/path.dart';

import '../../../core/network/api/social_circle_note_api.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/modals/share_modals.dart';

/// ==========================
/// Controller
/// ==========================
class MomentsController extends ChangeNotifier {
  final List<SocialInvitationModel> _items = [];
  List<SocialInvitationModel> get items => _items;
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
  }

  /// 分页加载
  Future<void> fetchMore() async {
    if (_loading || !_hasMore) return;

    _loading = true;
    notifyListeners();

    /// 👉 TODO: 换成你的真实接口
    final data = await _mockFetch();

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
  void toggleLike(SocialInvitationModel item) {
    item.isLike = !item.isLike;
    item.likes += item.isLike == true ? 1 : -1;
    notifyListeners();
  }

  /// 收藏
  void toggleCollect(SocialInvitationModel item) {
    item.isCollect = !item.isCollect ;
    item.collects += item.isCollect == true ? 1 : -1;
    notifyListeners();
  }

  /// 分享
  void toggleShare(SocialInvitationModel item,BuildContext context) {
    ShareModals.show(context);
  }

  /// mock 数据（你后面替换接口）
  Future<List<SocialInvitationModel>> _mockFetch() async {
    return await SocialCircleNoteApi.get(
      _page.toString(),
      _pageSize.toString(),
    );
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