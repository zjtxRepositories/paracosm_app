import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/wallet/chains/tron/tron_service.dart';
import 'package:web3dart/crypto.dart';

void main() {
  test('derives and validates a Tron address from a private key', () {
    const privateKey =
        '0000000000000000000000000000000000000000000000000000000000000001';

    final address = TronService.privateKeyToAddress(privateKey);

    expect(address, 'TMVQGm1qAQYVdetCeGRRkTWYYrLXuHK2HC');
    expect(TronService.isValidAddress(address), isTrue);
    expect(TronService.isValidAddress('${address.substring(0, 33)}D'), isFalse);
    expect(
      TronService.addressToHex(address),
      '417e5f4552091a69125d5dfcb7b8c2659029395bdf',
    );
    expect(
      TronService.hexToAddress(TronService.addressToHex(address)),
      address,
    );
  });

  test('signs a Tron transaction id with a recoverable signature', () {
    const privateKey =
        '0000000000000000000000000000000000000000000000000000000000000001';
    const txId =
        '4a1d1a5b729e66e05b3ad8d4b789c46555de3391dbb47f63ed7b9f9b2d62c8df';

    final encoded = hexToBytes(TronService.signTransactionId(txId, privateKey));
    final signature = MsgSignature(
      bytesToUnsignedInt(Uint8List.fromList(encoded.sublist(0, 32))),
      bytesToUnsignedInt(Uint8List.fromList(encoded.sublist(32, 64))),
      encoded[64] + 27,
    );

    expect(encoded.length, 65);
    expect(encoded.last, anyOf(0, 1));
    expect(
      bytesToHex(ecRecover(Uint8List.fromList(hexToBytes(txId)), signature)),
      bytesToHex(
        privateKeyBytesToPublic(Uint8List.fromList(hexToBytes(privateKey))),
      ),
    );
  });
}
