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
    final decimals =
        int.tryParse(json["tokenDecimal"]?.toString() ?? "18") ?? 18;
    final rawValue =
        BigInt.tryParse(json["value"]?.toString() ?? "0") ?? BigInt.zero;
    final amount = rawValue / BigInt.from(10).pow(decimals);

    // 判断方向
    final direction =
        json["from"].toString().toLowerCase() == userAddress.toLowerCase()
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

  factory TradeModel.fromAveTransaction(
    Map<dynamic, dynamic> json, {
    required String tokenAddress,
    required String fallbackSymbol,
  }) {
    final currentTokenAddress = tokenAddress.toLowerCase();
    final fromTokenAddress = json['from_token_address']?.toString() ?? '';
    final toTokenAddress = json['to_token_address']?.toString() ?? '';
    final isBuy = toTokenAddress.toLowerCase() == currentTokenAddress;
    final tokenAmount = isBuy
        ? _toDouble(json['to_token_amount'])
        : _toDouble(json['from_token_amount']);
    final tokenSymbol = isBuy
        ? json['to_token_symbol']?.toString()
        : json['from_token_symbol']?.toString();
    final tokenPrice = isBuy
        ? _toDouble(json['to_token_price_usd'])
        : _toDouble(json['from_token_price_usd']);
    print('fromAveTransaction-----$json');
    return TradeModel(
      symbol: tokenSymbol?.isNotEmpty == true ? tokenSymbol! : fallbackSymbol,
      price: tokenPrice,
      amount: tokenAmount,
      buyTurnover: _toDouble(json['amount_usd']),
      direction: isBuy ? TradeDirection.buy : TradeDirection.sell,
      time: _toInt(json['tx_time']),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      from: json['sender_address']?.toString(),
      to: json['to_address']?.toString(),
      contractAddress: isBuy ? toTokenAddress : fromTokenAddress,
      tokenName: tokenSymbol,
    );
  }

  static List<TradeModel> fromAveTransactions(
    Map<String, dynamic> data, {
    required String tokenAddress,
    required String fallbackSymbol,
  }) {
    final txs = data['txs'];
    if (txs is! List) return [];

    return txs
        .whereType<Map>()
        .map(
          (tx) => TradeModel.fromAveTransaction(
            tx,
            tokenAddress: tokenAddress,
            fallbackSymbol: fallbackSymbol,
          ),
        )
        .toList();
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
