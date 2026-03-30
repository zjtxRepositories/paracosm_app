import 'package:paracosm/modules/wallet/model/token_model.dart';

class ChainAccount {

  String name;         // ETH / BTC / SOL
  String address;
  int chainId;
  String logo;
  String symbol;
  /// ✅ 新增 Token 列表
  List<TokenModel> tokens;
  String chainType;

  ChainAccount({
    required this.name,
    required this.address,
    required this.chainId,
    required this.logo,
    required this.symbol,
    this.tokens = const [],
    required this.chainType,
  });

  /// JSON
  factory ChainAccount.fromJson(Map<String, dynamic> json) {
    return ChainAccount(
      name: json["name"],
      address: json["address"],
      chainId: json["chainId"] ?? 0,
      logo: json["logo"],
      symbol: json["symbol"],
      tokens: (json["tokens"] as List? ?? [])
          .map((e) => TokenModel.fromJson(e))
          .toList(),
      chainType: json["chainType"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "address": address,
      "chainId": chainId,
      "logo": logo,
      "symbol": symbol,
      "tokens": tokens.map((e) => e.toJson()).toList(),
      "chainType": chainType,
    };
  }

}