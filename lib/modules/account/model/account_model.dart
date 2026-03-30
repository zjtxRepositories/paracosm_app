class AccountModel {
  String id;
  String userId;
  String nickname;
  String avatar;
  String token;

  AccountModel({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.token,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'nickname': nickname,
      'avatar': avatar,
      'token': token,
    };
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'],
      userId: json['userId'],
      nickname: json['nickname'] ?? '',
      avatar: json['avatar'] ?? '',
      token: json['token'] ?? '',
    );
  }
}