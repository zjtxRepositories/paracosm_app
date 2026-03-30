
import 'package:paracosm/modules/wallet/service/wallet_service.dart';
import '../model/wallet_model.dart';

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

}