import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:paracosm/modules/wallet/chains/evm/evm_service.dart';
import '../../model/chain_account.dart';
import '../../model/token_model.dart';
import '../btc/bitcoin_service.dart';
import '../model/chain_config_model.dart';
import '../sol/solana_service.dart';

class ChainConfigService {

  static Future<List<ChainConfigModel>> loadConfigs() async {
    final jsonStr = await rootBundle.loadString("assets/chains.json");
    final List list = json.decode(jsonStr);

    return list.map((e) => ChainConfigModel.fromJson(e)).toList();
  }

  static Future<List<ChainAccount>> buildChainsFromConfig(
      List<ChainConfigModel> configs,
      String mnemonic,
      ) async{
    return await Future.wait( configs.map((config) async {

      /// 1. 生成地址（根据链类型）
      final address = await _generateAddress(
        mnemonic,
        config.chainType,
        config.coinIndex,
      );
      /// 2. 转 Token
      final tokens = config.tokens.map((t) {
        return TokenModel(
          symbol: t.symbol,
          name: t.name,
          address: t.address,
          decimals: t.decimals,
          balance: BigInt.zero,
          logo: t.icon,
          coinId: t.coinId, chainId: config.chainId,
        );
      }).toList();

      return ChainAccount(
        name: config.name,
        address: address,
        chainId: config.chainId,
        tokens: tokens,
        logo: config.icon,
        chainType:chainTypeFromString(config.chainType),
        symbol: config.symbol,
        nodes: config.nodes,
      );

    }).toList());
  }

  static Future<List<ChainAccount>> buildChainsFromPrivateKey(
      List<ChainConfigModel> configs,
      String privateKey,
      ) async {

    return await Future.wait(
      configs.map((config) async {

        String address = "";

        /// =========================
        /// 1️⃣ 只支持 EVM
        /// =========================
        if (config.chainType == 'evm') {
          address = EvmService.privateKeyToAddress(privateKey);
        } else {
          /// 非 EVM 不支持
          throw Exception("私钥导入暂不支持 ${config.chainType}");
        }

        /// =========================
        /// 2️⃣ Token 列表
        /// =========================
        final tokens = config.tokens.map((t) {
          return TokenModel(
            symbol: t.symbol,
            name: t.name,
            address: t.address,
            decimals: t.decimals,
            balance: BigInt.zero,
            logo: t.icon,
            coinId: t.coinId,
            chainId: config.chainId,
          );
        }).toList();

        /// =========================
        /// 3️⃣ 构建 ChainAccount
        /// =========================
        return ChainAccount(
          name: config.name,
          address: address,
          chainId: config.chainId,
          tokens: tokens,
          logo: config.icon,
          chainType: chainTypeFromString(config.chainType),
          symbol: config.symbol, nodes: config.nodes,
        );

      }).toList(),
    );
  }

  /// 生成地址（多链支持）
  static Future<String> _generateAddress(
      String mnemonic,
      String chainType,
      int coinIndex,
      ) async {

    switch (chainType) {

      case "evm":
        return EvmService.deriveAddress(mnemonic);

      case "solana":
        return SolanaService.deriveAddress(mnemonic);

      case "bitcoin":
        return await BitcoinService.deriveAddress(mnemonic);

      default:
        return '';
    }
  }
}