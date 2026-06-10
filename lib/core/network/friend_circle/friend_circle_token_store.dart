import 'package:shared_preferences/shared_preferences.dart';

class FriendCircleToken {
  final String token;
  final int expiresAt;

  const FriendCircleToken({required this.token, required this.expiresAt});

  bool isValidAt(int nowSeconds, {int refreshSkewSeconds = 60}) {
    return token.isNotEmpty && expiresAt - refreshSkewSeconds > nowSeconds;
  }
}

class FriendCircleTokenStore {
  static const String _tokenKeyPrefix = 'friend_circle_token';
  static const String _expiresAtKeyPrefix = 'friend_circle_token_expires_at';

  Future<FriendCircleToken?> read(String accountId) async {
    final safeAccountId = _normalizeAccountId(accountId);
    if (safeAccountId.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey(safeAccountId)) ?? '';
    final expiresAt = prefs.getInt(_expiresAtKey(safeAccountId)) ?? 0;
    if (token.isEmpty || expiresAt <= 0) return null;

    return FriendCircleToken(token: token, expiresAt: expiresAt);
  }

  Future<void> save(String accountId, FriendCircleToken token) async {
    final safeAccountId = _normalizeAccountId(accountId);
    if (safeAccountId.isEmpty || token.token.isEmpty || token.expiresAt <= 0) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey(safeAccountId), token.token);
    await prefs.setInt(_expiresAtKey(safeAccountId), token.expiresAt);
  }

  Future<void> clear(String accountId) async {
    final safeAccountId = _normalizeAccountId(accountId);
    if (safeAccountId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey(safeAccountId));
    await prefs.remove(_expiresAtKey(safeAccountId));
  }

  String _tokenKey(String accountId) => '$_tokenKeyPrefix:$accountId';

  String _expiresAtKey(String accountId) => '$_expiresAtKeyPrefix:$accountId';

  String _normalizeAccountId(String accountId) =>
      accountId.trim().toLowerCase();
}
