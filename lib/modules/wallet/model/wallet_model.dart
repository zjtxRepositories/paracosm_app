import 'dart:convert';

import 'chain_account.dart';

class WalletType {
  static const String mnemonic = "mnemonic";
  static const String privateKey = "privateKey";
}
class WalletModel {
  String id;
  String? name;
  int aIndex;
  int currentChainId;

  /// ⭐ 钱包类型（新增）
  String type;

  /// 多链账户
  List<ChainAccount> chains;

  ChainAccount? get currentChain =>
      chains.firstWhere((item) => item.chainId == currentChainId);

  bool get isPrivateKey => type == WalletType.privateKey;
  bool get isMnemonic => type == WalletType.mnemonic;

  ChainAccount? get evmChain =>
      chains.firstWhere((item) => item.chainType == ChainType.evm);

  /// 判断链
  bool hasChain(int chainId) {
    return chains.where((item) => item.chainId == chainId).isNotEmpty;
  }

  WalletModel({
    required this.id,
    required this.aIndex,
    required this.chains,
    required this.type, // ⭐ 必填
    this.currentChainId = 62176,
    this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'aIndex': aIndex,
      'currentChainId': currentChainId,
      'type': type, // ⭐ 存进去
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
      currentChainId: json['currentChainId'] ?? 62176,

      /// ⭐ 兼容老数据（重点！）
      type: json['type'] ?? WalletType.mnemonic,

      chains: (jsonDecode(json['chains']) as List)
          .map((e) => ChainAccount.fromJson(e))
          .toList(),
    );
  }
}