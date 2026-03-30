import 'dart:convert';

import 'chain_account.dart';

class WalletModel {

  String id;
  String? name;
  int aIndex;
  int currentChainId;

  /// 多链账户
  List<ChainAccount> chains;

  ChainAccount? get currentChain => chains.firstWhere((item) => item.chainId == currentChainId);

  WalletModel({
    required this.id,
    required this.aIndex,
    required this.chains,
    this.currentChainId = 62176,
    this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'aIndex': aIndex,
      'currentChainId': currentChainId,
      /// List → JSON String
      'chains': jsonEncode(
        chains.map((e) => e.toJson()).toList(),
      ),
    };
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'],
      name: json['name'],
      aIndex: json['aIndex'],
      currentChainId: json['currentChainId'],
      /// JSON String → List<ChainAccount>
      chains: (jsonDecode(json['chains']) as List)
          .map((e) => ChainAccount.fromJson(e))
          .toList(),
    );
  }
}

extension WalletExt on WalletModel {

  String get ethAddress =>
      getAddress("ETH") ?? "";

  String get btcAddress =>
      getAddress("BTC") ?? "";

  /// 获取指定链地址
  String? getAddress(String chain) {

    try {
      return chains
          .firstWhere((e) => e.name == chain)
          .address;
    } catch (e) {
      return null;
    }

  }



}