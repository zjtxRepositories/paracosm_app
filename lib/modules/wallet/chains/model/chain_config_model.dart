import 'package:paracosm/modules/wallet/chains/model/token_config_model.dart';

class ChainConfigModel {

  String name;
  String chainName;
  int chainId;
  String symbol;
  String coinName;
  int decimals;
  String icon;
  int coinIndex;
  String coinId;
  String chainType;

  List<String> nodes;

  String? explorer;
  String? explorerTxUrl;
  String? explorerAddressUrl;

  List<TokenConfigModel> tokens;

  ChainConfigModel({
    required this.name,
    required this.chainName,
    required this.chainId,
    required this.symbol,
    required this.coinName,
    required this.decimals,
    required this.icon,
    required this.coinIndex,
    required this.coinId,
    required this.chainType,
    required this.nodes,
    required this.tokens,
    this.explorer,
    this.explorerTxUrl,
    this.explorerAddressUrl,
  });

  factory ChainConfigModel.fromJson(Map<String, dynamic> json) {
    return ChainConfigModel(
      name: json["name"],
      chainName: json["chainName"],
      chainId: json["chainId"],
      symbol: json["symbol"],
      coinName: json["coinName"],
      decimals: json["decimals"],
      icon: json["icon"],
      coinIndex: json["coinIndex"] ?? 0,
      coinId: json["coinId"] ?? "",
      chainType: json["chainType"],
      nodes: List<String>.from(json["nodes"] ?? []),
      explorer: json["explorer"],
      explorerTxUrl: json["explorerTxUrl"],
      explorerAddressUrl: json["explorerAddressUrl"],
      tokens: (json["tokens"] as List)
          .map((e) => TokenConfigModel.fromJson(e))
          .toList(),
    );
  }
}