class SocialWalletAddress {
  static final RegExp _evmAddressPattern = RegExp(r'^0x[0-9a-fA-F]{40}$');

  static String normalize(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (_evmAddressPattern.hasMatch(normalized)) return normalized;
    return '';
  }
}
