import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/wallet/chains/btc/bitcoin_service.dart';

void main() {
  test(
    'derives the first mainnet BIP84 address without initializing BDK',
    () async {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

      final address = await BitcoinService.deriveAddress(mnemonic);

      expect(address, 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu');
    },
  );
}
