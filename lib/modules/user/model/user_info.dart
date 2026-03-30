class UserInfo {

  final String userId;
  final String nickname;
  final String avatar;
  final String token;

  UserInfo({
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.token,
  });


  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json["userId"]?.toString() ?? "",
      nickname: json["nickname"] ?? "",
      avatar: json["avatar"] ?? "",
      token: json["access_token"] ?? "",
    );
  }
}