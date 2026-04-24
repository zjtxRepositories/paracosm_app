import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bdk_flutter/bdk_flutter.dart';

import 'electrum_node_manager.dart';

class BitcoinService {
  /// =========================
  /// 网络
  /// =========================
  static const Network _network = Network.bitcoin;
  Network get network => _network;

  /// =========================
  /// 多钱包存储（安全）
  /// =========================
  static final Map<String, Wallet> _wallets = {};       // walletId -> wallet
  static final Map<String, String> _mnemonics = {};     // walletId -> mnemonic
  static final Map<String, String> _privateKeys = {};   // walletId -> wif
  static final Map<String, String> _descriptors = {};   // walletId -> descriptor

  /// =========================
  /// Blockchain（全局单例）
  /// =========================
  static Blockchain? _blockchain;
  static String? _currentNode;
  Blockchain? get blockchain => _blockchain;

  /// =========================
  /// 地址缓存（核心）
  /// =========================
  static final Map<String, String> _addressIndex = {};      // address -> walletId
  static final Map<String, int> _addressPathIndex = {};     // address -> index
  static final Map<String, int> _addressAccountIndex = {};  // address -> account
  static final Map<String, int> _addressChangeIndex = {};   // address -> change

  /// =========================
  /// 工具
  /// =========================
  static String _hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// =========================
  /// Descriptor（BIP84）
  /// =========================
  static String _buildDescriptor(String mnemonic, {int account = 0}) {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);

    final child = root.derivePath("m/84'/0'/$account'");
    final xprv = child.toBase58();

    return "wpkh($xprv/0/*)";
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
      databaseConfig: const DatabaseConfig.memory(), // 👉 生产建议换 sqlite
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
    final walletId = _hash(descriptor);

    if (_wallets.containsKey(walletId)) {
      return _wallets[walletId]!;
    }

    final wallet = await _createWallet(descriptor);

    _wallets[walletId] = wallet;
    _mnemonics[walletId] = mnemonic;
    _descriptors[walletId] = descriptor;

    return wallet;
  }

  /// =========================
  /// Blockchain 初始化
  /// =========================
  static Future<void> _initBlockchain() async {
    final node = await ElectrumNodeManager().getNode(testnet: false);

    // 👉 自动补协议（关键）
    final url = node.startsWith("ssl://") || node.startsWith("tcp://")
        ? node
        : "ssl://$node";

    _currentNode = url;

    print("Electrum URL => $url"); // 一定要打日志！

    _blockchain = await Blockchain.create(
      config: BlockchainConfig.electrum(
        config: ElectrumConfig(
          url: url,
          retry: 3,
          timeout: 30,
          stopGap: BigInt.from(50),
          validateDomain: false,
        ),
      ),
    );
  }

  static Future<Blockchain> _getBlockchain() async {
    if (_blockchain != null) return _blockchain!;
    await _initBlockchain()
        .timeout(const Duration(seconds: 10)); // ✅ 防卡死
    return _blockchain!;
  }

  /// =========================
  /// 同步（descriptor）
  /// =========================
  static Future<void> syncByDescriptor(String descriptor) async {
    final walletId = _hash(descriptor);
    final wallet = _wallets[walletId];
    if (wallet == null) throw Exception("Wallet not found");

    final blockchain = await _getBlockchain();

    try {
      await wallet.sync(blockchain: blockchain);
    } catch (e) {
      if (_currentNode != null) {
        ElectrumNodeManager().markFailed(_currentNode!);
      }
      await _initBlockchain();
      await wallet.sync(blockchain: _blockchain!);
    }
  }

  /// =========================
  /// 同步（助记词）
  /// =========================
  static Future<void> sync(String mnemonic, {int account = 0}) async {
    final wallet = await getOrCreateWallet(mnemonic, account: account);
    final blockchain = await _getBlockchain();

    try {
      await wallet.sync(blockchain: blockchain);
    } catch (e) {
      if (_currentNode != null) {
        ElectrumNodeManager().markFailed(_currentNode!);
      }
      await _initBlockchain();
      await wallet.sync(blockchain: _blockchain!);
    }
  }

  /// =========================
  /// 地址缓存
  /// =========================
  static void _cacheAddress(
      String address,
      String walletId,
      int index,
      int account, {
        int change = 0,
      }) {
    _addressIndex[address] = walletId;
    _addressPathIndex[address] = index;
    _addressAccountIndex[address] = account;
    _addressChangeIndex[address] = change;
  }

  /// =========================
  /// 获取未使用地址
  /// =========================
  static Future<String> deriveAddress(String mnemonic, {int account = 0}) async {
    final descriptor = _buildDescriptor(mnemonic, account: account);
    final walletId = _hash(descriptor);

    final wallet = await getOrCreateWallet(mnemonic, account: account);

    final addressInfo = wallet.getAddress(
      addressIndex: AddressIndex.lastUnused(),
    );

    final address = addressInfo.address.toString();
    final index = addressInfo.index;

    _cacheAddress(address, walletId, index, account, change: 0);

    return address;
  }

  /// =========================
  /// 私钥导入
  /// =========================
  static Future<String> privateKeyToAddress(String wif) async {
    final descriptorStr = "wpkh($wif)";
    final walletId = _hash(descriptorStr);

    if (_wallets.containsKey(walletId)) {
      final wallet = _wallets[walletId]!;
      final addr = wallet.getAddress(addressIndex: AddressIndex.lastUnused());
      return addr.address.toString();
    }

    final descriptor = await Descriptor.create(
      descriptor: descriptorStr,
      network: _network,
    );

    final wallet = await Wallet.create(
      descriptor: descriptor,
      network: _network,
      databaseConfig: const DatabaseConfig.memory(),
    );

    _wallets[walletId] = wallet;
    _privateKeys[walletId] = wif;
    _descriptors[walletId] = descriptorStr;

    final addressInfo = wallet.getAddress(
      addressIndex: AddressIndex.lastUnused(),
    );

    final address = addressInfo.address.toString();

    _cacheAddress(address, walletId, 0, 0, change: 0);

    return address;
  }

  /// =========================
  /// 新地址
  /// =========================
  static Future<String> getNewAddress(String mnemonic, {int account = 0}) async {
    final descriptor = _buildDescriptor(mnemonic, account: account);
    final walletId = _hash(descriptor);

    final wallet = await getOrCreateWallet(mnemonic, account: account);

    final addressInfo = wallet.getAddress(
      addressIndex: AddressIndex.increase(),
    );

    final address = addressInfo.address.toString();
    final index = addressInfo.index;

    _cacheAddress(address, walletId, index, account, change: 0);

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
    final walletId = _hash(descriptor);

    final wallet = await getOrCreateWallet(mnemonic, account: account);

    final addressInfo = wallet.getAddress(
      addressIndex: AddressIndex.peek(index: index),
    );

    final address = addressInfo.address.toString();

    _cacheAddress(address, walletId, index, account, change: 0);

    return address;
  }

  /// =========================
  /// 地址 → descriptor
  /// =========================
  static String? getDescriptorByAddress(String address) {
    final walletId = _addressIndex[address];
    if (walletId == null) return null;
    return _descriptors[walletId];
  }

  /// =========================
  /// 地址 → 私钥
  /// =========================
  static String? getPrivateKeyByAddress(String address) {
    final walletId = _addressIndex[address];
    if (walletId == null) return null;

    final wif = _privateKeys[walletId];
    if (wif != null) return wif;

    final index = _addressPathIndex[address];
    final account = _addressAccountIndex[address];
    final change = _addressChangeIndex[address] ?? 0;
    final mnemonic = _mnemonics[walletId];

    if (index == null || account == null || mnemonic == null) return null;

    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);

    final child = root.derivePath(
      "m/84'/0'/$account'/$change/$index",
    );

    return child.toWIF();
  }

  /// =========================
  /// 地址 → Wallet
  /// =========================
  static Wallet? getWalletByAddress(String address) {
    final walletId = _addressIndex[address];
    if (walletId == null) return null;
    return _wallets[walletId];
  }

  /// =========================
  /// 删除钱包
  /// =========================
  static void removeWallet(String mnemonic, {int account = 0}) {
    final descriptor = _buildDescriptor(mnemonic, account: account);
    final walletId = _hash(descriptor);

    _wallets.remove(walletId);
    _mnemonics.remove(walletId);
    _privateKeys.remove(walletId);
    _descriptors.remove(walletId);

    final addresses = _addressIndex.entries
        .where((e) => e.value == walletId)
        .map((e) => e.key)
        .toList();

    for (final addr in addresses) {
      _addressIndex.remove(addr);
      _addressPathIndex.remove(addr);
      _addressAccountIndex.remove(addr);
      _addressChangeIndex.remove(addr);
    }
  }

  /// =========================
  /// 清空所有钱包
  /// =========================
  static void clearAllWallets() {
    _wallets.clear();
    _mnemonics.clear();
    _privateKeys.clear();
    _descriptors.clear();
    _addressIndex.clear();
    _addressPathIndex.clear();
    _addressAccountIndex.clear();
    _addressChangeIndex.clear();
    _blockchain = null;
    _currentNode = null;
  }

  /// =========================
  /// 获取所有钱包
  /// =========================
  static List<String> getAllDescriptors() {
    return _descriptors.values.toList();
  }
}