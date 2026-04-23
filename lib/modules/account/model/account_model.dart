import 'package:paracosm/core/db/dao/wallet_dao.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';
import 'package:solana/solana.dart';

class AccountModel {
  String id;
  String userId;
  String nickname;
  String avatar;
  String token;

  String get accountId => id.toLowerCase();

  String get name => nickname.isNotEmpty ? nickname
      : (accountId.length > 8 ? accountId.substring(accountId.length - 8) : accountId);

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

  Future<WalletModel?> get wallet async {
    final model = await WalletDao().getWalletById(id);
    return model;
  }
}