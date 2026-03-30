import 'package:bip39/bip39.dart' as bip39;

class MnemonicService {

  static String generateMnemonic() {

    return bip39.generateMnemonic();

  }

  static String normalize(String mnemonic) {
    return mnemonic
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// ✅ 验证助记词是否有效
  static bool validateMnemonic(String mnemonic) {
    final normalized = normalize(mnemonic);

    final words = normalized.split(' ');

    if (!(words.length == 12 || words.length == 24)) {
      return false;
    }

    return bip39.validateMnemonic(normalized);
  }
}