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
  /// 单钱包（全局唯一）
  /// =========================
  static Wallet? _wallet;
  static String? _currentMnemonic;
  static String? _currentDescriptor;
  static Blockchain? _blockchain;

  /// =========================
  /// Descriptor（BIP84）
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
  /// 获取或创建 Wallet（核心）
  /// =========================
  static Future<Wallet> getOrCreateWallet(
      String mnemonic, {
        int account = 0,
      }) async {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception("Invalid mnemonic");
    }

    final descriptor = _buildDescriptor(mnemonic, account: account);

    /// ✅ 已存在
    if (_wallet != null) {
      if (_currentMnemonic != mnemonic) {
        throw Exception("钱包已用其他助记词初始化");
      }
      return _wallet!;
    }

    /// ❌ 创建
    _wallet = await _createWallet(descriptor);
    _currentMnemonic = mnemonic;
    _currentDescriptor = descriptor;

    return _wallet!;
  }

  /// =========================
  /// 获取 wallet（安全）
  /// =========================
   Wallet get wallet {
    if (_wallet == null) {
      throw Exception("Bitcoin wallet 未初始化");
    }
    return _wallet!;
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

  static Future<Blockchain> _getBlockchain() async {
    if (_blockchain != null) return _blockchain!;
    _blockchain = await _initBlockchain();
    return _blockchain!;
  }

  /// =========================
  /// 同步
  /// =========================
  static Future<void> sync() async {
    final blockchain = await _getBlockchain();

    try {
      await _wallet?.sync(blockchain: blockchain);
    } catch (e) {
      /// 切节点
      ElectrumNodeManager().markFailed(blockchain.toString());
      _blockchain = await _initBlockchain();
      await _wallet?.sync(blockchain: _blockchain!);
    }
  }

  /// =========================
  /// deriveAddress（统一入口）
  /// =========================
  static Future<String> deriveAddress(
      String mnemonic, {
        int account = 0,
      }) async {
    final wallet = await getOrCreateWallet(mnemonic, account: account);

    final addressInfo = wallet.getAddress(
      addressIndex: AddressIndex.lastUnused(),
    );

    return addressInfo.address.toString();
  }

  /// =========================
  /// 当前地址（已初始化）
  /// =========================
  static String get address {
    if (_wallet == null) return '';
    final addressInfo = _wallet!.getAddress(
      addressIndex: AddressIndex.lastUnused(),
    );
    return addressInfo.address.toString();
  }

  /// =========================
  /// 新地址
  /// =========================
  static Future<String> getNewAddress(String mnemonic) async {
    final wallet = await getOrCreateWallet(mnemonic);

    final addressInfo = wallet.getAddress(
      addressIndex: AddressIndex.increase(),
    );

    return addressInfo.address.toString();
  }

  /// =========================
  /// 指定 index
  /// =========================
  static Future<String> getAddressByIndex(
      String mnemonic, {
        int index = 0,
      }) async {
    final wallet = await getOrCreateWallet(mnemonic);

    final addressInfo = wallet.getAddress(
      addressIndex: AddressIndex.peek(index: index),
    );

    return addressInfo.address.toString();
  }

  /// =========================
  /// 清空（登出）
  /// =========================
  static void clear() {
    _wallet = null;
    _blockchain = null;
    _currentMnemonic = null;
    _currentDescriptor = null;
  }
}