
enum TradeDirection { buy, sell }

class TradeModel {
  String symbol;
  double price;
  double amount;
  double buyTurnover;
  TradeDirection direction;
  int time;
  int createdAt;
  String? from;
  String? to;
  String? contractAddress;
  String? tokenName;

  TradeModel({
    required this.symbol,
    required this.price,
    required this.amount,
    required this.buyTurnover,
    required this.direction,
    required this.time,
    required this.createdAt,
    this.from,
    this.to,
    this.contractAddress,
    this.tokenName,
  });

  Map<String, dynamic> toMap() => {
    "symbol": symbol,
    "price": price,
    "amount": amount,
    "buyTurnover": buyTurnover,
    "direction": direction.toString().split('.').last,
    "time": time,
    "createdAt": createdAt,
    "from": from,
    "to": to,
    "contractAddress": contractAddress,
    "tokenName": tokenName,
  };

  factory TradeModel.fromJson(Map<String, dynamic> json, String userAddress) {
    // 解析数量
    final decimals = int.tryParse(json["tokenDecimal"]?.toString() ?? "18") ?? 18;
    final rawValue = BigInt.tryParse(json["value"]?.toString() ?? "0") ?? BigInt.zero;
    final amount = rawValue / BigInt.from(10).pow(decimals);

    // 判断方向
    final direction = json["from"].toString().toLowerCase() == userAddress.toLowerCase()
        ? TradeDirection.sell
        : TradeDirection.buy;

    return TradeModel(
      symbol: json["tokenSymbol"] ?? "ETH",
      price: 0.0, // 可选：调用行情接口填充
      amount: amount.toDouble(),
      buyTurnover: 0.0, // 可选：price*amount
      direction: direction,
      time: int.tryParse(json["timeStamp"]?.toString() ?? "0") ?? 0,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      from: json["from"],
      to: json["to"],
      contractAddress: json["contractAddress"],
      tokenName: json["tokenName"],
    );
  }

}
