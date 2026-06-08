import 'package:flutter/foundation.dart';
import 'package:paracosm/core/db/dao/wallet_dao.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import 'package:paracosm/modules/wallet/service/wallet_service.dart';
import '../chains/btc/bitcoin_service.dart';
import '../chains/evm/evm_service.dart';
import '../chains/service/chain_config_service.dart';
import '../chains/sol/solana_service.dart';
import '../chains/tron/tron_service.dart';
import '../model/wallet_model.dart';
import '../security/wallet_security.dart';

class WalletManager {
  static final WalletManager _instance = WalletManager._();

  factory WalletManager() => _instance;

  WalletManager._();

  static final Set<String> _unlockedWalletIds = {};

  /// 创建账号（自动生成钱包）
  static Future<WalletModel> createWallet({
    String? mnemonic,
    String? privateKey,
    required String password,
  }) async {
    final wallet = mnemonic == null && privateKey == null
        ? await WalletService.createWallet(password)
        : mnemonic != null
        ? await WalletService.importWalletByMnemonic(mnemonic, password)
        : await WalletService.importWalletByPrivateKey(privateKey!, password);
    return wallet;
  }

  /// 导入私钥
  static Future<WalletModel> importWalletByPrivateKey({
    required String walletId,
    required ChainType chainType,
    required String privateKey,
    required String password,
  }) async {
    final wallet = await WalletService.importPrivateKeyByChainType(
      privateKey: privateKey,
      password: password,
      walletId: walletId,
      chainType: chainType,
    );
    await WalletDao().updateWallet(wallet);
    await AccountManager().refreshWallet(wallet: wallet);
    return wallet;
  }

  static bool _initialized = false;

  static Future<void> unlock({required String walletId}) async {
    if (_unlockedWalletIds.contains(walletId)) return;

    final mnemonic = await WalletSecurity.tryAutoUnlock(walletId);
    if (mnemonic == null) return;
    final wallet = await WalletDao().getWalletById(walletId);

    print('恢复----$mnemonic');

    /// 2. 恢复三条链
    /// EVM
    EvmService.createWalletFromMnemonic(mnemonic);

    /// SOL
    await SolanaService.createWalletFromMnemonic(mnemonic);

    TronService.createWalletFromMnemonic(mnemonic);
    if (wallet != null) {
      var shouldUpdateWallet = false;
      for (final chain in wallet.chains) {
        if (chain.chainType == ChainType.bitcoin && chain.address.isNotEmpty) {
          await BitcoinService.restoreAddressIndex(mnemonic, chain.address);
        }
      }
      if (!wallet.chains.any((chain) => chain.chainType == ChainType.tron)) {
        final configs = await ChainConfigService.loadConfigs();
        final tronConfigs = configs
            .where(
              (config) =>
                  chainTypeFromString(config.chainType) == ChainType.tron,
            )
            .toList();
        wallet.chains.addAll(
          await ChainConfigService.buildChainsFromConfig(tronConfigs, mnemonic),
        );
        shouldUpdateWallet = true;
      }
      if (shouldUpdateWallet) {
        await WalletDao().updateWallet(wallet);
      }
    }

    /// 3. BTC 同步
    BitcoinService.sync(mnemonic).catchError((error) {
      debugPrint('BTC sync failed: $error');
    });

    _unlockedWalletIds.add(walletId);
    _initialized = true;
  }

  static bool get isUnlocked => _initialized;

  /// 生成私钥（多链支持）
  static Future<String?> generatePrivateKey(ChainAccount chain) async {
    switch (chain.chainType) {
      case ChainType.evm:
        return EvmService.getPrivateKeyByAddress(chain.address);

      case ChainType.solana:
        return await SolanaService.getPrivateKeyByAddress(chain.address);

      case ChainType.bitcoin:
        return BitcoinService.getPrivateKeyByAddress(chain.address);
      case ChainType.tron:
        return TronService.getPrivateKeyByAddress(chain.address);
    }
  }

  /// 修改钱包名
  static Future<void> changeWalletName(String walletId, String name) async {
    final wallet = await WalletDao().getWalletById(walletId);
    if (wallet == null) return;
    wallet.name = name;
    await WalletDao().updateWallet(wallet);
    await AccountManager().refreshWallet();
  }

  /// 切链
  static Future<void> switchChain(
    String walletId,
    int chainId, {
    bool isSilent = false,
  }) async {
    final wallet = await WalletDao().getWalletById(walletId);
    if (wallet == null) return;
    if (!wallet.hasChain(chainId)) return;
    if (wallet.currentChainId == chainId) return;
    wallet.currentChainId = chainId;
    await WalletDao().updateWallet(wallet);
    await AccountManager().refreshWallet(isNotify: !isSilent);
  }

  static Future<void> switchChainSilent(String walletId, int chainId) async {
    await switchChain(walletId, chainId, isSilent: true);
  }

  /// 添加链
  static Future<void> addChain(String walletId, ChainAccount chain) async {
    final wallet = await WalletDao().getWalletById(walletId);
    if (wallet == null) return;
    wallet.chains.add(chain);
    await WalletDao().updateWallet(wallet);
    await AccountManager().refreshWallet();
  }

  /// 更新token
  static Future<void> updateToken(String walletId, TokenModel token) async {
    final wallet = await WalletDao().getWalletById(walletId);
    if (wallet == null) return;
    final chainIndex = wallet.chains.indexWhere(
      (item) => item.chainId == token.chainId,
    );
    if (chainIndex == -1) return;
    ChainAccount chain = wallet.chains[chainIndex];
    final tokenIndex = chain.tokens.indexWhere(
      (item) => item.symbol == token.symbol,
    );
    if (tokenIndex == -1) return;
    chain.tokens[tokenIndex] = token;
    wallet.chains[chainIndex] = chain;
    await WalletDao().updateWallet(wallet);
    await AccountManager().refreshWallet();
  }

  /// 添加token
  static Future<void> addToken(String walletId, TokenModel token) async {
    final wallet = await WalletDao().getWalletById(walletId);
    if (wallet == null) return;
    final chainIndex = wallet.chains.indexWhere(
      (item) => item.chainId == token.chainId,
    );
    if (chainIndex == -1) return;
    ChainAccount chain = wallet.chains[chainIndex];
    final tokenAddress = token.address.toLowerCase();
    final tokenIndex = chain.tokens.indexWhere((item) {
      if (chain.chainType == ChainType.evm && tokenAddress.isNotEmpty) {
        return item.address.toLowerCase() == tokenAddress;
      }
      return item.symbol == token.symbol;
    });
    if (tokenIndex != -1) {
      if (chain.tokens[tokenIndex].isAdded == true) return;
      chain.tokens[tokenIndex].isAdded = true;
    } else {
      chain.tokens.add(token);
    }
    wallet.chains[chainIndex] = chain;
    await WalletDao().updateWallet(wallet);
    await AccountManager().refreshWallet();
  }
}
