class TokenModel {

  String symbol;        // ETH / USDT
  String name;          // Ethereum
  String address;       // 合约地址（主链为空）
  String balance;       // 余额（字符串防精度丢失）
  int decimals;         // 精度
  String logo;

  TokenModel({
    required this.symbol,
    required this.name,
    required this.address,
    required this.balance,
    required this.decimals,
    required this.logo,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      symbol: json["symbol"] ?? "",
      name: json["name"] ?? "",
      address: json["address"] ?? "",
      balance: json["balance"] ?? "0",
      decimals: json["decimals"] ?? 18,
      logo: json["logo"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "symbol": symbol,
      "name": name,
      "address": address,
      "balance": balance,
      "decimals": decimals,
      "logo": logo,
    };
  }

}