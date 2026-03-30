import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/web3dart.dart' hide Wallet;
import 'package:web3dart/crypto.dart';
import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:bip39/bip39.dart' as bip39;

class BitcoinService {

  /// 网络（主网 / 测试网）
  static const Network _network = Network.bitcoin;

  /// 地址类型（推荐 bc1）
  static const AddressIndex _addressIndex = AddressIndex.lastUnused();

  /// 生成 Descriptor（核心）
  static String _buildDescriptor(String mnemonic, {int account = 0}) {
    /// BIP84：Native SegWit（bc1）
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final xprv = root.toBase58();
    return "wpkh($xprv/84'/0'/$account'/0/*)";
  }
  
  /// 创建钱包实例
  static Future<Wallet> _createWallet(
      String mnemonic, {
        int account = 0,
      }) async {
    final descriptorStr = _buildDescriptor(mnemonic);

    final descriptor = await Descriptor.create(
      descriptor: descriptorStr,
      network: Network.bitcoin,
    );

    final wallet = await Wallet.create(
      descriptor: descriptor,
      network: Network.bitcoin,
      databaseConfig: DatabaseConfig.memory(),
    );

    return wallet;
  }

  /// ✅ 生成地址（主方法）
  static Future<String> deriveAddress(
      String mnemonic, {
        int account = 0,
      }) async {

    final wallet = await _createWallet(
      mnemonic,
      account: account,
    );

    final addressInfo = wallet.getAddress(
      addressIndex: _addressIndex,
    );

    // print('tbc------${addressInfo.address.toString()}');
    return addressInfo.address.toString();
  }

  /// ✅ 获取指定 index 地址（用于多地址）
  static Future<Address> getAddressByIndex(
      String mnemonic, {
        int account = 0,
        int index = 0,
      }) async {

    final wallet = await _createWallet(
      mnemonic,
      account: account,
    );

    final addressInfo = wallet.getAddress(
      addressIndex: AddressIndex.peek(index: index),
    );

    return addressInfo.address;
  }

  /// ✅ 获取余额（需要 Electrum/Esplora 后端）
  static Future<BigInt> getBalance(
      String mnemonic,
      ) async {

    final wallet = await _createWallet(mnemonic);

    final balance = await wallet.getBalance();

    return balance.total;
  }

  // /// ✅ 构建交易（不广播）
  // static Future<TransactionDetails> buildTx({
  //   required String mnemonic,
  //   required String toAddress,
  //   required int amount, // satoshi
  //   int feeRate = 2,     // sat/vB
  // }) async {
  //
  //   final wallet = await _createWallet(mnemonic);
  //
  //   final txBuilder = TxBuilder();
  //
  //   txBuilder.addRecipient(
  //     address: toAddress,
  //     amount: amount,
  //   );
  //
  //   txBuilder.feeRate = feeRate.toDouble();
  //
  //   final result = await wallet.buildTx(txBuilder: txBuilder);
  //
  //   return result;
  // }
  //
  // /// ✅ 签名交易
  // static Future<String> signTx({
  //   required String mnemonic,
  //   required TransactionDetails tx,
  // }) async {
  //
  //   final wallet = await _createWallet(mnemonic);
  //
  //   final signed = await wallet.sign(psbt: tx.psbt);
  //
  //   return signed.psbt;
  // }

}