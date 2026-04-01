import 'package:paracosm/core/db/dao/account_dao.dart';
import 'package:paracosm/core/db/dao/wallet_dao.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';

import '../chains/service/chain_config_service.dart';
import '../model/wallet_model.dart';
import 'mnemonic_service.dart';
import '../security/wallet_security.dart';

class WalletService {

  /// =========================
  /// 创建钱包（助记词）
  /// =========================
  static Future<WalletModel> createWallet(String password) async {
    final mnemonic = MnemonicService.generateMnemonic();

    return await _buildWallet(
      mnemonic: mnemonic,
      password: password,
      importType: "mnemonic",
    );
  }

  /// =========================
  /// 助记词导入
  /// =========================
  static Future<WalletModel> importWalletByMnemonic(
      String mnemonic,
      String password,
      ) async {

    return await _buildWallet(
      mnemonic: mnemonic,
      password: password,
      importType: "mnemonic",
    );
  }

  /// =========================
  /// 私钥导入
  /// =========================
  static Future<WalletModel> importWalletByPrivateKey(
      String privateKey,
      String password,
      ) async {

    /// ⚠️ 私钥转“伪助记词入口”（统一流程）
    return await _buildWalletByPrivateKey(
      privateKey: privateKey,
      password: password,
    );
  }

  /// =========================
  /// 核心：助记词构建
  /// =========================
  static Future<WalletModel> _buildWallet({
    required String mnemonic,
    required String password,
    required String importType,
  }) async {

    /// 1. 加载链配置
    final configs = await ChainConfigService.loadConfigs();

    /// 2. 构建链账户
    final chains = await ChainConfigService.buildChainsFromConfig(
      configs,
      mnemonic,
    );

    /// 3. 用 ETH 地址作为 walletId（行业标准）
    final evmChain = chains.firstWhere(
          (e) => e.chainType == ChainType.evm,
    );

    final walletId = evmChain.address;

    /// 4. 保存钱包（加密🔥）
    await WalletSecurity.saveWallet(
      walletId: walletId,
      mnemonic: mnemonic,
      privateKey: "", // 助记词钱包可不存 pk
      password: password,
    );

    /// 5. 返回模型
    final accounts = await AccountDao().getAccounts();
    return WalletModel(
      id: walletId,
      aIndex: accounts.length,
      chains: chains,
    );
  }

  /// =========================
  /// 核心：私钥构建
  /// =========================
  static Future<WalletModel> _buildWalletByPrivateKey({
    required String privateKey,
    required String password,
  }) async {

    /// 1. 构建链（只支持 EVM）
    final configs = await ChainConfigService.loadConfigs();
    final chains = await ChainConfigService.buildChainsFromPrivateKey(
      configs,
      privateKey,
    );

    final evmChain = chains.firstWhere(
          (e) => e.chainType == 'evm',
    );

    final walletId = evmChain.address;

    /// 2. 保存
    await WalletSecurity.saveWallet(
      walletId: walletId,
      mnemonic: "",
      privateKey: privateKey,
      password: password,
    );
    final accounts = await AccountDao().getAccounts();
    return WalletModel(
      id: walletId,
      chains: chains, aIndex: accounts.length,
    );
  }
}