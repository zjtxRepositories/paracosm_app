import 'dart:async';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bdk_flutter/bdk_flutter.dart';

import 'electrum_node_manager.dart';

class BitcoinService {
  /// =========================
  /// 网络
  /// =========================
  static const Network _network = Network.bitcoin;

  /// =========================
  /// 多钱包存储
  /// =========================
  static final Map<String, Wallet> _wallets = {};           // descriptor -> wallet
  static final Map<String, String> _mnemonics = {};         // descriptor -> mnemonic
  static final Map<String, Blockchain> _blockchains = {};   // descriptor -> blockchain

  /// ✅ 地址索引缓存（核心）
  static final Map<String, String> _addressIndex = {};      // address -> descriptor

  /// =========================
  /// 构建 Descriptor（BIP84）
  /// =========================
  static String _buildDescriptor(String mnemonic, {int account = 0}) {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final xprv = root.toBase58();

    return "wpkh($xprv/84'/0'/$account')";
  }

  /// =========================
  /// 创建 Wallet
  /// =========================
  static Future<Wallet> _createWallet(String descriptorStr) async {
    final descriptor = await Descriptor.create(
      descriptor: descriptorStr,
      network: _network,
    );

    return await Wallet.create(
      descriptor: descriptor,
      network: _network,
      databaseConfig: DatabaseConfig.memory(),
    );
  }

  /// =========================
  /// 获取或创建钱包
  /// =========================
  static Future<Wallet> getOrCreateWallet(String mnemonic, {int account = 0}) async {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception("Invalid mnemonic");
    }

    final descriptor = _buildDescriptor(mnemonic, account: account);

    if (_wallets.containsKey(descriptor)) {
      return _wallets[descriptor]!;
    }

    final wallet = await _createWallet(descriptor);
    _wallets[descriptor] = wallet;
    _mnemonics[descriptor] = mnemonic;

    return wallet;
  }

  /// =========================
  /// Blockchain
  /// =========================
  static Future<Blockchain> _initBlockchain() async {
    final node = await ElectrumNodeManager().getNode(testnet: false);

    return await Blockchain.create(
      config: BlockchainConfig.electrum(
        config: ElectrumConfig(
          url: node,
          retry: 3,
          timeout: 30,
          stopGap: BigInt.from(20),
          validateDomain: false,
        ),
      ),
    );
  }

  static Future<Blockchain> _getBlockchain(String descriptor) async {
    if (_blockchains.containsKey(descriptor)) {
      return _blockchains[descriptor]!;
    }

    final blockchain = await _initBlockchain();
    _blockchains[descriptor] = blockchain;

    return blockchain;
  }

  static Future<void> syncByDescriptor(String descriptor) async {
    final wallet = _wallets[descriptor];
    if (wallet == null) {
      throw Exception("Wallet not found");
    }

    var blockchain = await _getBlockchain(descriptor);

    try {
      await wallet.sync(blockchain: blockchain);
    } catch (e) {
      ElectrumNodeManager().markFailed(blockchain.toString());
      blockchain = await _initBlockchain();
      _blockchains[descriptor] = blockchain;
      await wallet.sync(blockchain: blockchain);
    }
  }

  /// =========================
  /// 同步
  /// =========================
  static Future<void> sync(String mnemonic, {int account = 0}) async {
    final descriptor = _buildDescriptor(mnemonic, account: account);
    final wallet = await getOrCreateWallet(mnemonic, account: account);
    var blockchain = await _getBlockchain(descriptor);

    try {
      await wallet.sync(blockchain: blockchain);
    } catch (e) {
      ElectrumNodeManager().markFailed(blockchain.toString());
      blockchain = await _initBlockchain();
      _blockchains[descriptor] = blockchain;
      await wallet.sync(blockchain: blockchain);
    }
  }

  /// =========================
  /// 地址缓存
  /// =========================
  static void _cacheAddress(String address, String descriptor) {
    _addressIndex[address] = descriptor;
  }

  /// =========================
  /// deriveAddress（lastUnused）
  /// =========================
  static Future<String> deriveAddress(String mnemonic, {int account = 0}) async {
    final descriptor = _buildDescriptor(mnemonic, account: account);
    final wallet = await getOrCreateWallet(mnemonic, account: account);

    final addressInfo = wallet.getAddress(
      addressIndex: AddressIndex.lastUnused(),
    );

    final address = addressInfo.address.toString();
    _cacheAddress(address, descriptor);

    return address;
  }

  /// =========================
  /// 新地址
  /// =========================
  static Future<String> getNewAddress(String mnemonic, {int account = 0}) async {
    final descriptor = _buildDescriptor(mnemonic, account: account);
    final wallet = await getOrCreateWallet(mnemonic, account: account);

    final addressInfo = wallet.getAddress(
      addressIndex: AddressIndex.increase(),
    );

    final address = addressInfo.address.toString();
    _cacheAddress(address, descriptor);

    return address;
  }

  /// =========================
  /// 指定 index 地址
  /// =========================
  static Future<String> getAddressByIndex(
      String mnemonic, {
        int account = 0,
        int index = 0,
      }) async {
    final descriptor = _buildDescriptor(mnemonic, account: account);
    final wallet = await getOrCreateWallet(mnemonic, account: account);

    final addressInfo = wallet.getAddress(
      addressIndex: AddressIndex.peek(index: index),
    );

    final address = addressInfo.address.toString();
    _cacheAddress(address, descriptor);

    return address;
  }

  /// =========================
  /// 通过地址获取钱包（核心）
  /// =========================
  static Wallet? getWalletByAddress(String address) {
    final descriptor = _addressIndex[address];
    if (descriptor == null) return null;

    return _wallets[descriptor];
  }

  /// =========================
  /// 获取 descriptor
  /// =========================
  static String? getDescriptorByAddress(String address) {
    return _addressIndex[address];
  }

  /// =========================
  /// 删除钱包
  /// =========================
  static void removeWallet(String mnemonic, {int account = 0}) {
    final descriptor = _buildDescriptor(mnemonic, account: account);

    _wallets.remove(descriptor);
    _mnemonics.remove(descriptor);
    _blockchains.remove(descriptor);

    /// 清理地址索引
    _addressIndex.removeWhere((key, value) => value == descriptor);
  }

  /// =========================
  /// 清空所有钱包
  /// =========================
  static void clearAllWallets() {
    _wallets.clear();
    _mnemonics.clear();
    _blockchains.clear();
    _addressIndex.clear();
  }

  /// =========================
  /// 获取所有钱包
  /// =========================
  static List<String> getAllDescriptors() {
    return _wallets.keys.toList();
  }
}