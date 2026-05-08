class UserInfo {

  final String userId;
  final String nickname;
  final String avatar;
  final String token;
  final String account;

  UserInfo({
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.token,
    required this.account,
  });


  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json["userId"]?.toString() ?? "",
      nickname: json["nickname"] ?? "",
      avatar: json["avatar"] ?? "",
      token: json["access_token"] ?? "",
      account: json["account"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'avatar': avatar,
      'token': token,
      'account': token,
    };
  }
}