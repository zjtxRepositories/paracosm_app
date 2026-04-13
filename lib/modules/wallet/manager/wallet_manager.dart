
import 'package:paracosm/core/db/dao/wallet_dao.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/account/service/account_service.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/service/wallet_service.dart';
import '../chains/btc/bitcoin_service.dart';
import '../chains/evm/evm_service.dart';
import '../chains/sol/solana_service.dart';
import '../model/wallet_model.dart';
import '../security/wallet_security.dart';

class WalletManager {

  static final WalletManager _instance =
  WalletManager._();

  factory WalletManager() => _instance;

  WalletManager._();


  /// 创建账号（自动生成钱包）
  static Future<WalletModel> createWallet(
      {String? mnemonic, String? privateKey,required String password}) async {

    final wallet = mnemonic == null && privateKey == null ?
    await WalletService.createWallet(password) : mnemonic != null ?
    await WalletService.importWalletByMnemonic(mnemonic,password)  :
    await WalletService.importWalletByPrivateKey(privateKey!,password) ;
    return wallet;
  }

  /// 导入私钥
  static Future<WalletModel> importWalletByPrivateKey({
    required String walletId,
    required ChainType chainType,
    required String privateKey,
    required String password}) async {
    final wallet = await WalletService.importPrivateKeyByChainType(
        privateKey: privateKey, password: password, walletId: walletId,chainType: chainType);
    await WalletDao().updateWallet(wallet);
    await AccountManager().init();
    return wallet;
  }

  static bool _initialized = false;

  static Future<void> unlock({
    required String walletId,
  }) async {
    final mnemonic = await WalletSecurity.tryAutoUnlock(walletId);
    if (mnemonic == null) return;

    print('恢复----${mnemonic}');
    /// 2. 恢复三条链
    /// EVM
    EvmService.createWalletFromMnemonic(mnemonic);

    /// SOL
    await SolanaService.createWalletFromMnemonic(mnemonic);

    /// BTC
    await BitcoinService.getOrCreateWallet(mnemonic);

    /// 3. BTC 同步（重要）
    await BitcoinService.sync(mnemonic);

    _initialized = true;
  }

  static bool get isUnlocked => _initialized;

  /// 生成私钥（多链支持）
  static Future<String?> generatePrivateKey(
      ChainAccount chain
      ) async {

    switch (chain.chainType) {
      case ChainType.evm:
        return EvmService.getPrivateKeyByAddress(chain.address);

      case ChainType.solana:
        return await SolanaService.getPrivateKeyByAddress(chain.address);

      case ChainType.bitcoin:
        return BitcoinService.getPrivateKeyByAddress(chain.address);

      }
  }

  /// 修改钱包名
  static Future<void> changeWalletName(String walletId,String name)async {
    final wallet = await WalletDao().getWalletById(walletId);
    if (wallet == null) return;
    wallet.name = name;
    await WalletDao().updateWallet(wallet);
    await AccountManager().refreshWallet();
  }

  /// 修改钱包名
  static Future<void> switchChain(String walletId,int chainId)async {
    final wallet = await WalletDao().getWalletById(walletId);
    if (wallet == null) return;
    wallet.currentChainId = chainId;
    await WalletDao().updateWallet(wallet);
    await AccountManager().refreshWallet();
  }
}

