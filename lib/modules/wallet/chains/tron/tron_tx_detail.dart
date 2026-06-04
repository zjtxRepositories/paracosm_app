class TronTxDetail {
  final String txid;
  final String from;
  final String to;
  final BigInt value;
  final BigInt? fee;
  final bool? success;
  final DateTime? time;

  TronTxDetail({
    required this.txid,
    required this.from,
    required this.to,
    required this.value,
    this.fee,
    this.success,
    this.time,
  });
}
