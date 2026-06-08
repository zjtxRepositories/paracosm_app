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
    final evmChain = chains.firstWhere((e) => e.chainType == ChainType.evm);

    final walletId = evmChain.address;

    /// 4. 保存钱包（加密🔥）
    await WalletSecurity.saveWallet(
      walletId: walletId,
      mnemonic: mnemonic,
      privateKey: "", // 助记词钱包可不存 pk
      password: password,
    );

    /// 5. 返回模型，重复导入同一钱包时保留原名称和序号
    final oldWallet = await WalletDao().getWalletById(walletId);
    final accounts = oldWallet == null
        ? await AccountDao().getAccounts()
        : null;
    final currentChainId =
        oldWallet != null &&
            chains.any((chain) => chain.chainId == oldWallet.currentChainId)
        ? oldWallet.currentChainId
        : 56;
    return WalletModel(
      id: walletId,
      name: oldWallet?.name,
      aIndex: oldWallet?.aIndex ?? accounts!.length,
      currentChainId: currentChainId,
      chains: chains,
      type: WalletType.mnemonic,
    );
  }

  /// =========================
  /// 核心：私钥构建
  /// =========================
  static Future<WalletModel> _buildWalletByPrivateKey({
    required String privateKey,
    required String password,
    ChainType chainType = ChainType.evm,
  }) async {
    final configs = await ChainConfigService.loadConfigs();
    final relatedConfigs = configs
        .where((config) => chainTypeFromString(config.chainType) == chainType)
        .toList();

    final chains = await ChainConfigService.buildChainsFromPrivateKey(
      relatedConfigs,
      privateKey,
      chainType: chainType,
    );

    final primaryChain = chains.firstWhere((e) => e.chainType == chainType);

    final walletId = primaryChain.address;

    /// 2. 保存
    await WalletSecurity.saveWallet(
      walletId: walletId,
      mnemonic: "",
      privateKey: privateKey,
      password: password,
    );
    final oldWallet = await WalletDao().getWalletById(walletId);
    final accounts = oldWallet == null
        ? await AccountDao().getAccounts()
        : null;
    final currentChainId =
        oldWallet != null &&
            chains.any((chain) => chain.chainId == oldWallet.currentChainId)
        ? oldWallet.currentChainId
        : chains.any((chain) => chain.chainId == 56)
        ? 56
        : primaryChain.chainId;
    return WalletModel(
      id: walletId,
      name: oldWallet?.name,
      chains: chains,
      aIndex: oldWallet?.aIndex ?? accounts!.length,
      currentChainId: currentChainId,
      type: WalletType.privateKey,
    );
  }

  /// =========================
  /// 核心：私钥构建
  /// =========================
  static Future<WalletModel> importPrivateKeyByChainType({
    required String privateKey,
    required String password,
    required String walletId,
    ChainType chainType = ChainType.evm,
  }) async {
    final configs = await ChainConfigService.loadConfigs();
    final config = configs.where((e) {
      return chainTypeFromString(e.chainType) == chainType;
    }).toList();
    final chains = await ChainConfigService.buildChainsFromPrivateKey(
      config,
      privateKey,
      chainType: chainType,
    );
    final wallet = await WalletDao().getWalletById(walletId);
    if (wallet == null) {
      throw Exception('Wallet not found');
    }
    final securityData = await WalletSecurity.getWallet(
      walletId: walletId,
      password: password,
    );
    await WalletSecurity.saveWallet(
      walletId: walletId,
      mnemonic: securityData?['mnemonic'] ?? '',
      privateKey: privateKey,
      password: password,
    );
    final oldChains = wallet.chains;
    final filteredOldChains = oldChains
        .where((c) => c.chainType != chainType)
        .toList();
    wallet.chains = [...filteredOldChains, ...chains];
    if (!wallet.chains.any((chain) => chain.chainId == wallet.currentChainId)) {
      wallet.currentChainId = chains.first.chainId;
    }
    return wallet;
  }
}
