import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class TronService {
  static const String _path = "m/44'/195'/0'/0/0";
  static const String _alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  static final Map<String, Map<String, String>> _wallets = {};

  static Map<String, String> createWalletFromMnemonic(String mnemonic) {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception('Invalid mnemonic');
    }

    for (final wallet in _wallets.values) {
      if (wallet['mnemonic'] == mnemonic) return wallet;
    }

    final child = bip32.BIP32
        .fromSeed(bip39.mnemonicToSeed(mnemonic))
        .derivePath(_path);
    final privateKey = child.privateKey;
    if (privateKey == null) {
      throw Exception('Failed to derive Tron private key');
    }

    final privateKeyHex = bytesToHex(privateKey, include0x: true);
    final address = privateKeyToAddress(privateKeyHex);
    final wallet = {
      'address': address,
      'privateKey': privateKeyHex,
      'mnemonic': mnemonic,
    };
    _wallets[address] = wallet;
    return wallet;
  }

  static String deriveAddress(String mnemonic) {
    return createWalletFromMnemonic(mnemonic)['address']!;
  }

  static String privateKeyToAddress(String privateKeyHex) {
    final ethAddress = EthPrivateKey.fromHex(privateKeyHex).address.hex;
    final payload = Uint8List.fromList([
      0x41,
      ...hexToBytes(ethAddress.replaceFirst('0x', '')),
    ]);
    final address = _base58CheckEncode(payload);
    _wallets.putIfAbsent(
      address,
      () => {'address': address, 'privateKey': privateKeyHex},
    );
    return address;
  }

  static String? getPrivateKeyByAddress(String address) {
    return _wallets[address]?['privateKey'];
  }

  static bool isValidAddress(String address) {
    try {
      final decoded = _base58Decode(address);
      if (decoded.length != 25 || decoded.first != 0x41) return false;
      final payload = decoded.sublist(0, 21);
      final checksum = decoded.sublist(21);
      return _bytesEqual(checksum, _checksum(payload));
    } catch (_) {
      return false;
    }
  }

  static String addressToHex(String address) {
    if (!isValidAddress(address)) {
      throw const FormatException('Invalid Tron address');
    }
    return bytesToHex(_base58Decode(address).sublist(0, 21));
  }

  static String hexToAddress(String hexAddress) {
    final normalized = hexAddress.replaceFirst('0x', '');
    final bytes = hexToBytes(normalized);
    final payload = bytes.length == 20
        ? Uint8List.fromList([0x41, ...bytes])
        : Uint8List.fromList(bytes);
    if (payload.length != 21 || payload.first != 0x41) {
      throw const FormatException('Invalid Tron hex address');
    }
    return _base58CheckEncode(payload);
  }

  static String signTransactionId(String txId, String privateKeyHex) {
    final signature = sign(
      Uint8List.fromList(hexToBytes(txId)),
      Uint8List.fromList(hexToBytes(privateKeyHex.replaceFirst('0x', ''))),
    );
    final r = padUint8ListTo32(unsignedIntToBytes(signature.r));
    final s = padUint8ListTo32(unsignedIntToBytes(signature.s));
    return bytesToHex(Uint8List.fromList([...r, ...s, signature.v - 27]));
  }

  static String _base58CheckEncode(Uint8List payload) {
    return _base58Encode(
      Uint8List.fromList([...payload, ..._checksum(payload)]),
    );
  }

  static Uint8List _checksum(List<int> payload) {
    final first = sha256.convert(payload).bytes;
    return Uint8List.fromList(sha256.convert(first).bytes.sublist(0, 4));
  }

  static String _base58Encode(Uint8List bytes) {
    var value = BigInt.zero;
    for (final byte in bytes) {
      value = (value << 8) | BigInt.from(byte);
    }

    var result = '';
    while (value > BigInt.zero) {
      final remainder = (value % BigInt.from(58)).toInt();
      value ~/= BigInt.from(58);
      result = _alphabet[remainder] + result;
    }
    for (final byte in bytes) {
      if (byte != 0) break;
      result = '1$result';
    }
    return result;
  }

  static Uint8List _base58Decode(String value) {
    var number = BigInt.zero;
    for (final character in value.codeUnits) {
      final index = _alphabet.indexOf(String.fromCharCode(character));
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

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
