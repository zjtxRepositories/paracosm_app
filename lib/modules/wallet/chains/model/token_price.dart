class TokenPrice {
  final String symbol;
  final double price; // USD
  final int timestamp;

  TokenPrice({
    required this.symbol,
    required this.price,
    required this.timestamp,
  });
}