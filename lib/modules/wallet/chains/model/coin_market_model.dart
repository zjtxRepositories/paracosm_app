
class CoinMarketModel {
  static const String table = 'coins';
  static const String columnSymbol = 'symbol';
  static const String columnHigh24h= 'high';
  static const String columnLow24h= 'low';
  static const String columnClose= 'close';
  static const String columnChg = 'chg';
  static const String columnChange= 'change';
  static const String columnVolume= 'volume';
  static const String columnTurnover= 'turnover';
  static const String columnImage = 'coinImg';

  CoinMarketModel({required this.symbol, required this.high,
    required this.low, required this.close, required this.chg,
    required this.change,required this.volume,required this.turnover,
    required this.coinImg});

  final String symbol;
  final String coinImg;
  final double high;
  final double low;
  final double close;
  final double chg;
  final double change;
  final double volume;
  final double turnover;

  String get shortName => symbol.split('/').first;

  factory CoinMarketModel.fromJson(Map<String, dynamic> json) {
    return CoinMarketModel(
      symbol: json["symbol"],
      coinImg: json["coinImg"],
      high: double.parse('${json["high"]}'),
      low: double.parse('${json["low"]}'),
      close: double.parse('${json["close"]}'),
      chg: json["chg"],
      change: json["change"],
      volume: double.parse('${json["volume"]}'),
      turnover: double.parse('${json["turnover"]}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "symbol": symbol,
      "coinImg": coinImg,
      "high": high,
      "low": low,
      "close": close,
      "chg": chg,
      "change": change,
      "volume": volume,
      "turnover": turnover,
    };
  }
}