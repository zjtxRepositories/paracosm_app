class CommunityParam {
  final String symbol;
  final int chainId;

  final String? tokenAddress;
  final bool isNative;

  final String? groupId; // ⭐ 可以放，但只是绑定信息

  const CommunityParam({
    required this.symbol,
    required this.chainId,
    this.tokenAddress,
    required this.isNative,
    this.groupId,
  });

  Map<String, dynamic> toJson() => {
    "symbol": symbol,
    "chainId": chainId,
    "tokenAddress": tokenAddress,
    "isNative": isNative,
    "groupId": groupId,
  };

  factory CommunityParam.fromJson(Map<String, dynamic> json) {
    return CommunityParam(
      symbol: json["symbol"] ?? "",
      chainId: json["chainId"] ?? 0,
      tokenAddress: json["tokenAddress"],
      isNative: json["isNative"] ?? false,
      groupId: json["groupId"],
    );
  }
}