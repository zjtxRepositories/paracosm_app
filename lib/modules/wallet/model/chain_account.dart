import 'package:paracosm/modules/wallet/model/token_model.dart';
enum ChainType { evm, solana, bitcoin }

/// 字符串转 ChainType
ChainType chainTypeFromString(String? type) {
  if (type == null) return ChainType.evm;

  switch (type.toLowerCase()) {
    case 'evm':
      return ChainType.evm;
    case 'solana':
      return ChainType.solana;
    case 'bitcoin':
    case 'btc':
      return ChainType.bitcoin;
    default:
      return ChainType.evm;
  }
}
class ChainAccount {
  String name;
  String address;
  int chainId;
  String logo;
  String symbol;
  List<TokenModel> tokens;
  ChainType chainType;
  List<String> nodes;
  String? txApiUrl;
  String? apiKey;

  ChainAccount({
    required this.name,
    required this.address,
    required this.chainId,
    required this.logo,
    required this.symbol,
    this.tokens = const [],
    required this.chainType,
    required this.nodes,
    this.txApiUrl,
    this.apiKey,
  });

  factory ChainAccount.fromJson(Map<String, dynamic> json) {
    return ChainAccount(
      name: json["name"] ?? "",
      address: json["address"] ?? "",
      chainId: json["chainId"] ?? 0,
      logo: json["logo"] ?? "",
      symbol: json["symbol"] ?? "",
      tokens: (json["tokens"] as List? ?? [])
          .map((e) => TokenModel.fromJson(e))
          .toList(),
      chainType: chainTypeFromString(json["chainType"]), // ✅
      nodes: (json["nodes"] as List? ?? [])
          .map((e) => e.toString())
          .toList(), // ✅
      txApiUrl: json["txApiUrl"] ?? "",
      apiKey: json["apiKey"] ?? "",
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
      "chainType": chainType.name, // ✅
      "nodes": nodes,
      "txApiUrl": txApiUrl,
      "apiKey": apiKey,
    };
  }
}