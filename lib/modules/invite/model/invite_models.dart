class InviteUser {
  final String userId;
  final String nickname;
  final String avatar;
  final String boundAt;
  final String status;

  const InviteUser({
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.boundAt,
    this.status = '',
  });

  String get displayName {
    final name = nickname.trim();
    if (name.isNotEmpty) return name;
    if (userId.length > 10) {
      return '${userId.substring(0, 6)}...${userId.substring(userId.length - 4)}';
    }
    return userId;
  }

  factory InviteUser.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return InviteUser(
      userId: _stringValue(data['userId'] ?? data['uid'] ?? data['id']),
      nickname: _stringValue(data['nickname'] ?? data['name']),
      avatar: _stringValue(data['avatar'] ?? data['portraitUri']),
      boundAt: _stringValue(data['boundAt'] ?? data['createdAt']),
      status: _stringValue(data['status']),
    );
  }
}

class InviteProfile {
  final String inviteCode;
  final int childrenCount;
  final InviteUser? parent;

  const InviteProfile({
    required this.inviteCode,
    required this.childrenCount,
    this.parent,
  });

  String get inviteLink => inviteCode.trim().isEmpty
      ? ''
      : 'https://paracosm.app/invite?code=${Uri.encodeQueryComponent(inviteCode.trim())}';

  factory InviteProfile.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    final parentJson = data['parent'];
    return InviteProfile(
      inviteCode: _stringValue(data['inviteCode'] ?? data['code']),
      childrenCount: _intValue(
        data['childrenCount'] ?? data['invitedCount'] ?? data['childCount'],
      ),
      parent: parentJson is Map
          ? InviteUser.fromJson(Map<String, dynamic>.from(parentJson))
          : null,
    );
  }
}

class InvitePagination {
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  const InvitePagination({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory InvitePagination.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return InvitePagination(
      page: _intValue(data['page'], fallback: 1),
      pageSize: _intValue(data['pageSize'], fallback: 20),
      totalItems: _intValue(data['totalItems']),
      totalPages: _intValue(data['totalPages'], fallback: 1),
    );
  }
}

class InviteChildrenPage {
  final List<InviteUser> children;
  final InvitePagination pagination;

  const InviteChildrenPage({required this.children, required this.pagination});

  bool get hasMore => pagination.page < pagination.totalPages;

  factory InviteChildrenPage.fromResponse(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    final rawList = data['data'];
    final paginationJson = data['pagination'];
    return InviteChildrenPage(
      children: rawList is List
          ? rawList
                .whereType<Map>()
                .map(
                  (item) =>
                      InviteUser.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      pagination: InvitePagination.fromJson(
        paginationJson is Map
            ? Map<String, dynamic>.from(paginationJson)
            : null,
      ),
    );
  }
}

class InviteResolveResult {
  final String inviteCode;
  final String inviterUserId;
  final String inviterName;
  final String inviterAvatar;
  final bool isValid;

  const InviteResolveResult({
    required this.inviteCode,
    required this.inviterUserId,
    required this.inviterName,
    required this.inviterAvatar,
    required this.isValid,
  });

  factory InviteResolveResult.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return InviteResolveResult(
      inviteCode: _stringValue(data['inviteCode'] ?? data['code']),
      inviterUserId: _stringValue(data['inviterUserId'] ?? data['userId']),
      inviterName: _stringValue(data['inviterName'] ?? data['nickname']),
      inviterAvatar: _stringValue(data['inviterAvatar'] ?? data['avatar']),
      isValid: _boolValue(data['isValid']),
    );
  }
}

class InviteBindResult {
  final bool bound;
  final bool alreadyBound;
  final String parentUserId;
  final String childUserId;

  const InviteBindResult({
    required this.bound,
    required this.alreadyBound,
    required this.parentUserId,
    required this.childUserId,
  });

  factory InviteBindResult.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return InviteBindResult(
      bound: _boolValue(data['bound']),
      alreadyBound: _boolValue(data['alreadyBound']),
      parentUserId: _stringValue(data['parentUserId']),
      childUserId: _stringValue(data['childUserId']),
    );
  }
}

String _stringValue(Object? value) => value?.toString().trim() ?? '';

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

bool _boolValue(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}
