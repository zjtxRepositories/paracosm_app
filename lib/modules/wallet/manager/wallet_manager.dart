
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
}