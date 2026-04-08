class BitcoinTxDetail {
  final String txid;
  final String from;
  final String to;
  final BigInt value;     // satoshi
  final BigInt fee;       // satoshi
  final int confirmations;
  final DateTime? time;

  BitcoinTxDetail({
    required this.txid,
    required this.from,
    required this.to,
    required this.value,
    required this.fee,
    required this.confirmations,
    this.time,
  });
}