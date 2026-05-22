enum TokenTransactionDirection { receive, send }

class TokenTransactionRecordModel {
  final String blockHash;
  final String tokenSymbol;
  final String tokenName;
  final String contractAddress;
  final String transactionIndex;
  final String confirmations;
  final String nonce;
  final String timeStamp;
  final String input;
  final String gasUsed;
  final String blockNumber;
  final String gas;
  final String tokenDecimal;
  final String cumulativeGasUsed;
  final String from;
  final String to;
  final String value;
  final String hash;
  final String gasPrice;
  final int resultCode;
  final TokenTransactionDirection direction;

  TokenTransactionRecordModel({
    required this.blockHash,
    required this.tokenSymbol,
    required this.tokenName,
    required this.contractAddress,
    required this.transactionIndex,
    required this.confirmations,
    required this.nonce,
    required this.timeStamp,
    required this.input,
    required this.gasUsed,
    required this.blockNumber,
    required this.gas,
    required this.tokenDecimal,
    required this.cumulativeGasUsed,
    required this.from,
    required this.to,
    required this.value,
    required this.hash,
    required this.gasPrice,
    required this.resultCode,
    required this.direction,
  });

  bool get isSend => direction == TokenTransactionDirection.send;

  int get time => int.tryParse(timeStamp) ?? 0;

  int get decimals => int.tryParse(tokenDecimal) ?? 18;

  double get amount {
    final rawValue = BigInt.tryParse(value) ?? BigInt.zero;
    return rawValue / BigInt.from(10).pow(decimals);
  }

  String get displayAddress => isSend ? to : from;

  factory TokenTransactionRecordModel.fromJson(
    Map<String, dynamic> json,
    String userAddress,
  ) {
    final from = json['from']?.toString() ?? '';
    final direction = from.toLowerCase() == userAddress.toLowerCase()
        ? TokenTransactionDirection.send
        : TokenTransactionDirection.receive;

    return TokenTransactionRecordModel(
      blockHash: json['blockHash']?.toString() ?? '',
      tokenSymbol: json['tokenSymbol']?.toString() ?? '',
      tokenName: json['tokenName']?.toString() ?? '',
      contractAddress: json['contractAddress']?.toString() ?? '',
      transactionIndex: json['transactionIndex']?.toString() ?? '',
      confirmations: json['confirmations']?.toString() ?? '',
      nonce: json['nonce']?.toString() ?? '',
      timeStamp: json['timeStamp']?.toString() ?? '',
      input: json['input']?.toString() ?? '',
      gasUsed: json['gasUsed']?.toString() ?? '',
      blockNumber: json['blockNumber']?.toString() ?? '',
      gas: json['gas']?.toString() ?? '',
      tokenDecimal: json['tokenDecimal']?.toString() ?? '18',
      cumulativeGasUsed: json['cumulativeGasUsed']?.toString() ?? '',
      from: from,
      to: json['to']?.toString() ?? '',
      value: json['value']?.toString() ?? '0',
      hash: json['hash']?.toString() ?? '',
      gasPrice: json['gasPrice']?.toString() ?? '',
      resultCode: int.tryParse(json['resultCode']?.toString() ?? '0') ?? 0,
      direction: direction,
    );
  }

  Map<String, dynamic> toJson() => {
    'blockHash': blockHash,
    'tokenSymbol': tokenSymbol,
    'tokenName': tokenName,
    'contractAddress': contractAddress,
    'transactionIndex': transactionIndex,
    'confirmations': confirmations,
    'nonce': nonce,
    'timeStamp': timeStamp,
    'input': input,
    'gasUsed': gasUsed,
    'blockNumber': blockNumber,
    'gas': gas,
    'tokenDecimal': tokenDecimal,
    'cumulativeGasUsed': cumulativeGasUsed,
    'from': from,
    'to': to,
    'value': value,
    'hash': hash,
    'gasPrice': gasPrice,
    'resultCode': resultCode,
  };
}
