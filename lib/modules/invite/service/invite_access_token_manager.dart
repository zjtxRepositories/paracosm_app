import 'package:paracosm/core/network/api/invite_token_api.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InviteAccessTokenManager {
  InviteAccessTokenManager._();

  static const _ttlSeconds = 7 * 24 * 60 * 60;
  static SharedPreferences? _prefs;
  static InviteAccessTokenFetcher? _fetcherForTesting;
  static int Function()? _nowSecondsProviderForTesting;

  static String _tokenKey(String userId) => 'invite_access_token_$userId';
  static String _expiresKey(String userId) =>
      'invite_access_token_expires_$userId';

  static Future<String> ensureAccessToken({bool forceRefresh = false}) async {
    final account = AccountManager().currentAccount;
    final userId = account?.accountId ?? '';
    if (userId.isEmpty) {
      throw Exception('invite_login_required');
    }

    _prefs ??= await SharedPreferences.getInstance();
    final now = _nowSeconds();
    final cached = _prefs!.getString(_tokenKey(userId)) ?? '';
    final expiresAt = _prefs!.getInt(_expiresKey(userId)) ?? 0;
    if (!forceRefresh && cached.isNotEmpty && expiresAt > now) {
      return cached;
    }

    final fetcher = _fetcherForTesting ?? _fetchAccessToken;
    final token = await fetcher(
      userId: userId,
      name: account?.name ?? userId,
      portraitUri: account?.avatar,
    );
    if (token.trim().isEmpty) {
      throw Exception('invite_login_required');
    }

    await _prefs!.setString(_tokenKey(userId), token);
    await _prefs!.setInt(_expiresKey(userId), now + _ttlSeconds);
    return token;
  }

  static Future<String> _fetchAccessToken({
    required String userId,
    required String name,
    String? portraitUri,
  }) async {
    final result = await InviteTokenApi.getToken(
      userId: userId,
      name: name,
      portraitUri: portraitUri,
    );
    final token = result?.accessToken ?? '';
    if (token.isEmpty) {
      throw Exception('missing invite accessToken');
    }
    return token;
  }

  static int _nowSeconds() {
    final provider = _nowSecondsProviderForTesting;
    if (provider != null) return provider();
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  static void configureForTesting({
    InviteAccessTokenFetcher? fetcher,
    int Function()? nowSecondsProvider,
  }) {
    _fetcherForTesting = fetcher;
    _nowSecondsProviderForTesting = nowSecondsProvider;
  }

  static void resetForTesting() {
    _prefs = null;
    _fetcherForTesting = null;
    _nowSecondsProviderForTesting = null;
  }
}

typedef InviteAccessTokenFetcher =
    Future<String> Function({
      required String userId,
      required String name,
      String? portraitUri,
    });
