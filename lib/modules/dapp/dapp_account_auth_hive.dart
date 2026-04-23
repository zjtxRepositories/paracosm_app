import 'package:hive/hive.dart';

class DAppAccountAuthHive {
  static const boxName = 'wallet.dApp.account.auth';
  static const String accountAuthKey = 'addressAuth';

  static final Box _box = Hive.box(boxName);

  // =========================
  // host 标准化（非常关键）
  // =========================
  static String _normalize(String host) {
    return host
        .toLowerCase()
        .replaceAll('https://', '')
        .replaceAll('http://', '')
        .replaceAll('www.', '')
        .trim();
  }

  static String normalizeHost(String host) => _normalize(host);

  // =========================
  // 获取全部授权
  // =========================
  static List<String> get allAddressAuth {
    final list = _box.get(accountAuthKey);
    if (list == null) return [];
    return List<String>.from(list);
  }

  // =========================
  // 检查授权
  // =========================
  static bool checkAuth(String host) {
    final key = _normalize(host);
    return allAddressAuth.contains(key);
  }

  // =========================
  // 添加授权
  // =========================
  static void add(String host) {
    final key = _normalize(host);

    final list = List<String>.from(allAddressAuth);

    if (!list.contains(key)) {
      list.add(key);
      _box.put(accountAuthKey, list);
    }
  }

  // =========================
  // 删除授权
  // =========================
  static void delete(String host) {
    final key = _normalize(host);

    final list = List<String>.from(allAddressAuth);

    list.remove(key);

    _box.put(accountAuthKey, list);
  }

  // =========================
  // 清空授权
  // =========================
  static void clear() {
    _box.delete(accountAuthKey);
  }
}
