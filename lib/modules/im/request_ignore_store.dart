import 'package:shared_preferences/shared_preferences.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import 'manager/im_engine_manager.dart';

class ImRequestIgnoreStore {
  ImRequestIgnoreStore._internal();

  static final ImRequestIgnoreStore _instance =
      ImRequestIgnoreStore._internal();

  factory ImRequestIgnoreStore() => _instance;

  final Map<String, Set<String>> _friendIgnoredByAccount = {};
  final Map<String, Set<String>> _groupIgnoredByAccount = {};

  String? _loadedAccountId;

  Future<void> ensureLoaded() async {
    final accountId = _accountKey();
    if (_loadedAccountId == accountId) return;

    final prefs = await SharedPreferences.getInstance();
    _friendIgnoredByAccount[accountId] = _readKeys(
      prefs,
      _friendIgnoredPrefsKey(accountId),
    );
    _groupIgnoredByAccount[accountId] = _readKeys(
      prefs,
      _groupIgnoredPrefsKey(accountId),
    );
    _loadedAccountId = accountId;
  }

  bool isFriendIgnored(RCIMIWFriendApplicationInfo item) {
    final accountId = _accountKey();
    final keys = _friendIgnoredByAccount[accountId];
    if (keys == null) return false;
    return keys.contains(_friendKey(item));
  }

  bool isGroupIgnored(RCIMIWGroupApplicationInfo item) {
    final accountId = _accountKey();
    final keys = _groupIgnoredByAccount[accountId];
    if (keys == null) return false;
    return keys.contains(_groupKey(item));
  }

  Future<bool> ignoreFriendApplication(RCIMIWFriendApplicationInfo item) async {
    await ensureLoaded();
    final accountId = _accountKey();
    final keys = _friendIgnoredByAccount.putIfAbsent(accountId, () => {});
    final added = keys.add(_friendKey(item));
    if (added) {
      await _persist(
        _friendIgnoredPrefsKey(accountId),
        keys,
      );
    }
    return added;
  }

  Future<bool> ignoreGroupApplication(RCIMIWGroupApplicationInfo item) async {
    await ensureLoaded();
    final accountId = _accountKey();
    final keys = _groupIgnoredByAccount.putIfAbsent(accountId, () => {});
    final added = keys.add(_groupKey(item));
    if (added) {
      await _persist(
        _groupIgnoredPrefsKey(accountId),
        keys,
      );
    }
    return added;
  }

  String _accountKey() {
    final accountId = IMEngineManager().currentUserId?.trim().toLowerCase();
    return accountId == null || accountId.isEmpty ? 'global' : accountId;
  }

  String _friendKey(RCIMIWFriendApplicationInfo item) {
    final userId = item.userId?.trim() ?? '';
    final type = item.applicationType?.name ?? 'unknown';
    final time = item.operationTime;
    return '$type:$userId:$time';
  }

  String _groupKey(RCIMIWGroupApplicationInfo item) {
    final groupId = item.groupId?.trim() ?? '';
    final direction = item.direction?.name ?? 'unknown';
    final applicantId = item.joinMemberInfo?.userId?.trim() ?? '';
    final inviterId = item.inviterInfo?.userId?.trim() ?? '';
    final time = item.operationTime;
    return '$direction:$groupId:$applicantId:$inviterId:$time';
  }

  Set<String> _readKeys(SharedPreferences prefs, String key) {
    return (prefs.getStringList(key) ?? const <String>[]).toSet();
  }

  Future<void> _persist(String key, Set<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, values.toList());
  }

  String _friendIgnoredPrefsKey(String accountId) =>
      'im_friend_request_ignored_$accountId';

  String _groupIgnoredPrefsKey(String accountId) =>
      'im_group_request_ignored_$accountId';
}
