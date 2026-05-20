class TokenConfigModel {

  String symbol;
  String address;
  int decimals;
  String name;
  String coinId;
  String icon;
  int? native;
  bool? isAdded;

  TokenConfigModel({
    required this.symbol,
    required this.address,
    required this.decimals,
    required this.name,
    required this.coinId,
    required this.icon,
    this.native,
    this.isAdded,
  });

  factory TokenConfigModel.fromJson(Map<String, dynamic> json) {
    return TokenConfigModel(
      symbol: json["symbol"],
      address: json["address"] ?? "",
      decimals: json["decimals"],
      name: json["name"],
      coinId: json["coinId"] ?? "",
      icon: json["icon"] ?? "",
      native: json["native"],
      isAdded: json["isAdded"] == 1 || json["isAdded"] == true,
    );
  }

}
