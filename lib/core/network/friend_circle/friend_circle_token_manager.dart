import '../../../modules/account/manager/account_manager.dart';
import 'friend_circle_token_api.dart';
import 'friend_circle_token_store.dart';

typedef _FriendCircleTokenFetcher =
    Future<FriendCircleTokenResult> Function(String accountId);

class FriendCircleTokenManager {
  static const int _refreshSkewSeconds = 60;

  static FriendCircleTokenStore _store = FriendCircleTokenStore();
  static FriendCircleTokenApi _api = FriendCircleTokenApi();
  static String? Function() _accountIdProvider = () =>
      AccountManager().currentAccount?.accountId;
  static int Function() _nowSecondsProvider = () =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000;
  static _FriendCircleTokenFetcher? _tokenFetcherForTesting;

  static Future<String> ensureValidToken({bool forceRefresh = false}) async {
    final accountId = (_accountIdProvider() ?? '').trim().toLowerCase();
    if (accountId.isEmpty) {
      throw Exception('FriendCircle account is not logged in');
    }

    if (!forceRefresh) {
      final cached = await _store.read(accountId);
      if (cached != null &&
          cached.isValidAt(
            _nowSecondsProvider(),
            refreshSkewSeconds: _refreshSkewSeconds,
          )) {
        return cached.token;
      }
    }

    final fetcher =
        _tokenFetcherForTesting ??
        (String userId) => _api.getToken(userId: userId);
    final result = await fetcher(accountId);
    final token = FriendCircleToken(
      token: result.token,
      expiresAt: result.expiresAt,
    );
    await _store.save(accountId, token);
    return token.token;
  }

  static Future<void> prefetchForCurrentAccount() async {
    await ensureValidToken(forceRefresh: true);
  }

  static void configureForTesting({
    FriendCircleTokenStore? store,
    FriendCircleTokenApi? api,
    String? Function()? accountIdProvider,
    int Function()? nowSecondsProvider,
    Future<FriendCircleTokenResult> Function(String accountId)? tokenFetcher,
  }) {
    if (store != null) _store = store;
    if (api != null) _api = api;
    if (accountIdProvider != null) _accountIdProvider = accountIdProvider;
    if (nowSecondsProvider != null) _nowSecondsProvider = nowSecondsProvider;
    _tokenFetcherForTesting = tokenFetcher;
  }

  static void resetForTesting() {
    _store = FriendCircleTokenStore();
    _api = FriendCircleTokenApi();
    _accountIdProvider = () => AccountManager().currentAccount?.accountId;
    _nowSecondsProvider = () => DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _tokenFetcherForTesting = null;
  }
}
