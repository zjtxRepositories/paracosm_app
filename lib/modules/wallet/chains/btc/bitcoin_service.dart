import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/digests/ripemd160.dart';
import 'package:web3dart/crypto.dart' as web3_crypto;
// ignore: implementation_imports
import 'package:bdk_flutter/src/generated/frb_generated.dart' as bdk_generated;
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'electrum_node_manager.dart';

class BitcoinService {
  static Future<void>? _initialization;

  static Future<void> _ensureInitialized() =>
      _initialization ??= _initializeBdk();

  static Future<void> _initializeBdk() async {
    if (!_isAppleDesktopOrMobile) {
      await bdk_generated.core.init();
      return;
    }

    final executablePath = Platform.resolvedExecutable;
    if (executablePath.isNotEmpty) {
      try {
        await bdk_generated.core.init(
          externalLibrary: ExternalLibrary.open(
            executablePath,
            debugInfo: ' from Platform.resolvedExecutable',
          ),
        );
        return;
      } on ArgumentError {
        // Some iOS builds reject dlopen on the app executable; fall back to
        // RTLD_DEFAULT for those environments.
      }
    }

    await bdk_generated.core.init(
      externalLibrary: ExternalLibrary.process(
        iKnowHowToUseIt: true,
        debugInfo: ' fallback after executable open failed',
      ),
    );
  }

  static bool get _isAppleDesktopOrMobile =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// =========================
  /// 网络
  /// =========================
  static const Network _network = Network.bitcoin;
  static const String _bech32Alphabet = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
  static const String _base58Alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  Network get network => _network;

  /// =========================
  /// 多钱包存储（安全）
  /// =========================
  static final Map<String, Wallet> _wallets = {}; // walletId -> wallet
  static final Map<String, String> _mnemonics = {}; // walletId -> mnemonic
  static final Map<String, String> _privateKeys = {}; // walletId -> wif
  static final Map<String, String> _descriptors = {}; // walletId -> descriptor

  /// =========================
  /// Blockchain（全局单例）
  /// =========================
  static Blockchain? _blockchain;
  static String? _currentNode;
  Blockchain? get blockchain => _blockchain;

  /// =========================
  /// 地址缓存（核心）
  /// =========================
  static final Map<String, String> _addressIndex = {}; // address -> walletId
  static final Map<String, int> _addressPathIndex = {}; // address -> index
  static final Map<String, int> _addressAccountIndex = {}; // address -> account
  static final Map<String, int> _addressChangeIndex = {}; // address -> change

  /// =========================
  /// 工具
  /// =========================
  static String _hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  static List<int> _checksum(List<int> payload) {
    final first = sha256.convert(payload).bytes;
    return sha256.convert(first).bytes.sublist(0, 4);
  }

  static Uint8List _base58Decode(String value) {
    var number = BigInt.zero;
    for (final character in value.codeUnits) {
      final index = _base58Alphabet.indexOf(String.fromCharCode(character));
      if (index < 0) throw const FormatException('Invalid Base58 character');
      number = number * BigInt.from(58) + BigInt.from(index);
    }

    final decoded = <int>[];
    while (number > BigInt.zero) {
      decoded.insert(0, (number & BigInt.from(0xff)).toInt());
      number >>= 8;
    }
    for (final character in value.codeUnits) {
      if (character != 49) break;
      decoded.insert(0, 0);
    }
    return Uint8List.fromList(decoded);
  }

  static Uint8List _base58CheckDecode(String value) {
    final decoded = _base58Decode(value);
    if (decoded.length < 5) {
      throw const FormatException('Invalid Base58Check value');
    }
    final payload = decoded.sublist(0, decoded.length - 4);
    final checksum = decoded.sublist(decoded.length - 4);
    final expected = _checksum(payload);
    for (var i = 0; i < 4; i++) {
      if (checksum[i] != expected[i]) {
        throw const FormatException('Invalid Base58Check checksum');
      }
    }
    return Uint8List.fromList(payload);
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

  static Uint8List _hash160(List<int> input) {
    final sha = sha256.convert(input).bytes;
    final digest = RIPEMD160Digest().process(Uint8List.fromList(sha));
    return Uint8List.fromList(digest);
  }

  static int _bech32Polymod(List<int> values) {
    var chk = 1;
    const generators = [
      0x3b6a57b2,
      0x26508e6d,
      0x1ea119fa,
      0x3d4233dd,
      0x2a1462b3,
    ];
    for (final value in values) {
      final top = chk >> 25;
      chk = ((chk & 0x1ffffff) << 5) ^ value;
      for (var i = 0; i < generators.length; i++) {
        if (((top >> i) & 1) == 1) {
          chk ^= generators[i];
        }
      }
    }
    return chk;
  }

  static List<int> _bech32HrpExpand(String hrp) {
    return [
      ...hrp.codeUnits.map((value) => value >> 5),
      0,
      ...hrp.codeUnits.map((value) => value & 31),
    ];
  }

  static List<int> _bech32CreateChecksum(String hrp, List<int> data) {
    final values = [..._bech32HrpExpand(hrp), ...data, 0, 0, 0, 0, 0, 0];
    var polymod = _bech32Polymod(values) ^ 1;
    return List.generate(6, (index) => (polymod >> (5 * (5 - index))) & 31);
  }

  static String _bech32Encode(String hrp, List<int> data) {
    final combined = [...data, ..._bech32CreateChecksum(hrp, data)];
    return '${hrp}1${combined.map((value) => _bech32Alphabet[value]).join()}';
  }

  static List<int> _convertBits(
    List<int> data,
    int fromBits,
    int toBits, {
    bool pad = true,
  }) {
    var acc = 0;
    var bits = 0;
    final result = <int>[];
    final maxv = (1 << toBits) - 1;
    for (final value in data) {
      if (value < 0 || (value >> fromBits) != 0) {
        throw const FormatException('Invalid bech32 data');
      }
      acc = (acc << fromBits) | value;
      bits += fromBits;
      while (bits >= toBits) {
        bits -= toBits;
        result.add((acc >> bits) & maxv);
      }
    }
    if (pad) {
      if (bits > 0) {
        result.add((acc << (toBits - bits)) & maxv);
      }
    } else if (bits >= fromBits || ((acc << (toBits - bits)) & maxv) != 0) {
      throw const FormatException('Invalid bech32 padding');
    }
    return result;
  }

  static String _p2wpkhAddressFromPublicKey(Uint8List compressedPublicKey) {
    final witnessProgram = _hash160(compressedPublicKey);
    final data = [0, ..._convertBits(witnessProgram, 8, 5)];
    return _bech32Encode('bc', data);
  }

  static Uint8List _compressPublicKey(Uint8List publicKey) {
    if (publicKey.length == 33) return publicKey;
    if (publicKey.length == 65 && publicKey.first == 0x04) {
      final x = publicKey.sublist(1, 33);
      final y = publicKey.sublist(33, 65);
      return Uint8List.fromList([(y.last & 1) == 0 ? 0x02 : 0x03, ...x]);
    }
    if (publicKey.length == 64) {
      final x = publicKey.sublist(0, 32);
      final y = publicKey.sublist(32, 64);
      return Uint8List.fromList([(y.last & 1) == 0 ? 0x02 : 0x03, ...x]);
    }
    throw const FormatException('Invalid secp256k1 public key');
  }

  static Uint8List _publicKeyFromPrivateKey(Uint8List privateKey) {
    final uncompressed = web3_crypto.privateKeyToPublic(
      web3_crypto.bytesToUnsignedInt(privateKey),
    );
    return _compressPublicKey(uncompressed);
  }

  static Uint8List _privateKeyBytesFromWifOrHex(String value) {
    final normalized = value.trim();
    final hex = normalized.startsWith('0x')
        ? normalized.substring(2)
        : normalized;
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(hex)) {
      return Uint8List.fromList(web3_crypto.hexToBytes(hex));
    }

    final payload = _base58CheckDecode(normalized);
    if (payload.length == 34 && payload.first == 0x80 && payload.last == 0x01) {
      return Uint8List.fromList(payload.sublist(1, 33));
    }
    if (payload.length == 33 && payload.first == 0x80) {
      return Uint8List.fromList(payload.sublist(1, 33));
    }
    throw const FormatException('Invalid Bitcoin private key');
  }

  static String _deriveAddressByIndex(
    String mnemonic, {
    int account = 0,
    int index = 0,
  }) {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception("Invalid mnemonic");
    }
    final seed = bip39.mnemonicToSeed(mnemonic);
    final child = bip32.BIP32
        .fromSeed(seed)
        .derivePath("m/84'/0'/$account'/0/$index");
    return _p2wpkhAddressFromPublicKey(child.publicKey);
  }

  /// =========================
  /// 创建 Wallet
  /// =========================
  static Future<Wallet> _createWallet(String descriptorStr) async {
    await _ensureInitialized();

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
  static Future<Wallet> getOrCreateWallet(
    String mnemonic, {
    int account = 0,
  }) async {
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
  static Future<Blockchain?> _initBlockchain() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final node = await ElectrumNodeManager().getNode(testnet: false);
      final url = _normalizeElectrumUrl(node);

      print("🌐 Electrum URL => $url");

      try {
        final blockchain = await Blockchain.create(
          config: BlockchainConfig.electrum(
            config: ElectrumConfig(
              url: url,
              retry: 1,
              timeout: 5,
              stopGap: BigInt.from(50),
              validateDomain: false,
            ),
          ),
        ).timeout(const Duration(seconds: 10));

        _blockchain = blockchain;
        _currentNode = url;

        return blockchain;
      } catch (e) {
        ElectrumNodeManager().markFailed(url);
        print("❌ blockchain init failed: $url, $e");
      }
    }

    _blockchain = null;
    _currentNode = null;
    return null;
  }

  static String _normalizeElectrumUrl(String node) {
    final trimmed = node.trim();
    if (trimmed.startsWith("ssl://") || trimmed.startsWith("tcp://")) {
      return trimmed;
    }
    return "ssl://$trimmed";
  }

  static Future<Blockchain?> _getBlockchain() async {
    if (_blockchain != null) return _blockchain!;
    await _initBlockchain().timeout(const Duration(seconds: 45)); // ✅ 防卡死
    print('_blockchain--$_blockchain');
    return _blockchain;
  }

  static Future<Blockchain> requireBlockchain() async {
    final blockchain = await _getBlockchain();
    if (blockchain == null) {
      throw Exception("blockchain error: no available Electrum node");
    }
    return blockchain;
  }

  /// =========================
  /// 同步（descriptor）
  /// =========================
  static Future<void> syncByDescriptor(String descriptor) async {
    final walletId = _hash(descriptor);
    final wallet = _wallets[walletId];
    if (wallet == null) throw Exception("Wallet not found");

    final blockchain = await requireBlockchain();

    try {
      await wallet.sync(blockchain: blockchain);
    } catch (e) {
      if (_currentNode != null) {
        ElectrumNodeManager().markFailed(_currentNode!);
      }
      await _initBlockchain();
      if (_blockchain != null) {
        await wallet.sync(blockchain: _blockchain!);
        return;
      }
      throw Exception("blockchain error: no available Electrum node");
    }
  }

  /// =========================
  /// 同步（助记词）
  /// =========================
  static Future<void> sync(String mnemonic, {int account = 0}) async {
    final wallet = await getOrCreateWallet(mnemonic, account: account);
    final blockchain = await requireBlockchain();

    try {
      await wallet.sync(blockchain: blockchain);
    } catch (e) {
      if (_currentNode != null) {
        ElectrumNodeManager().markFailed(_currentNode!);
      }
      await _initBlockchain();
      if (_blockchain != null) {
        await wallet.sync(blockchain: _blockchain!);
        return;
      }
      throw Exception("blockchain error: no available Electrum node");
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
  static Future<String> deriveAddress(
    String mnemonic, {
    int account = 0,
  }) async {
    final descriptor = _buildDescriptor(mnemonic, account: account);
    final walletId = _hash(descriptor);
    final index = 0;
    final address = _deriveAddressByIndex(
      mnemonic,
      account: account,
      index: index,
    );

    _cacheAddress(address, walletId, index, account, change: 0);
    _mnemonics[walletId] = mnemonic;
    _descriptors[walletId] = descriptor;

    return address;
  }

  /// =========================
  /// 私钥导入
  /// =========================
  static Future<String> privateKeyToAddress(String wif) async {
    final descriptorStr = "wpkh($wif)";
    final walletId = _hash(descriptorStr);

    final privateKey = _privateKeyBytesFromWifOrHex(wif);
    final address = _p2wpkhAddressFromPublicKey(
      _publicKeyFromPrivateKey(privateKey),
    );
    _privateKeys[walletId] = wif;
    _descriptors[walletId] = descriptorStr;

    _cacheAddress(address, walletId, 0, 0, change: 0);

    return address;
  }

  /// =========================
  /// 新地址
  /// =========================
  static Future<String> getNewAddress(
    String mnemonic, {
    int account = 0,
  }) async {
    final descriptor = _buildDescriptor(mnemonic, account: account);
    final walletId = _hash(descriptor);
    final nextIndex = _addressIndex.values.where((id) => id == walletId).length;
    final address = _deriveAddressByIndex(
      mnemonic,
      account: account,
      index: nextIndex,
    );

    _cacheAddress(address, walletId, nextIndex, account, change: 0);
    _mnemonics[walletId] = mnemonic;
    _descriptors[walletId] = descriptor;

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
    final address = _deriveAddressByIndex(
      mnemonic,
      account: account,
      index: index,
    );

    _cacheAddress(address, walletId, index, account, change: 0);
    _mnemonics[walletId] = mnemonic;
    _descriptors[walletId] = descriptor;

    return address;
  }

  /// =========================
  /// 恢复已持久化地址索引
  /// =========================
  static Future<bool> restoreAddressIndex(
    String mnemonic,
    String address, {
    int account = 0,
    int maxIndex = 20,
  }) async {
    final descriptor = _buildDescriptor(mnemonic, account: account);
    final walletId = _hash(descriptor);
    _mnemonics[walletId] = mnemonic;
    _descriptors[walletId] = descriptor;

    for (var index = 0; index <= maxIndex; index++) {
      final candidate = await getAddressByIndex(
        mnemonic,
        account: account,
        index: index,
      );
      if (candidate == address) {
        _cacheAddress(address, walletId, index, account, change: 0);
        return true;
      }
    }

    return false;
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

    final child = root.derivePath("m/84'/0'/$account'/$change/$index");

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
