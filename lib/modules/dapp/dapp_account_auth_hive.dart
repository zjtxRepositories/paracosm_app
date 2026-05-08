import 'package:hive/hive.dart';

class DAppAccountAuthHive {
  static const boxName = 'wallet.dApp.account.auth';
  static const String accountAuthKey = 'addressAuth';

  static final Box _box = Hive.box(boxName);

  // =========================
  // 统一 Host 规范化
  // =========================
  static String normalizeHost(String host) {
    return host
        .toLowerCase()
        .replaceAll(RegExp(r'^https?:\/\/'), '')
        .replaceAll('www.', '')
        .split('/')[0]
        .split('?')[0]
        .trim();
  }

  static String _key(String host, String wallet, String chainId) {
    return '${normalizeHost(host)}|$wallet|$chainId';
  }

  // =========================
  // 安全获取全部授权
  // =========================
  static Map<String, bool> get allAuth {
    final data = _box.get(accountAuthKey);

    if (data is Map) {
      return Map<String, bool>.from(data);
    }

    return {};
  }

  // =========================
  // 检查授权
  // =========================
  static bool checkAuth(String host, String wallet, String chainId) {
    final key = _key(host, wallet, chainId);
    return allAuth[key] == true;
  }

  // =========================
  // 添加授权（安全写入）
  // =========================
  static Future<void> add(
      String host,
      String wallet,
      String chainId,
      ) async {
    final key = _key(host, wallet, chainId);

    final data = {
      ...allAuth,
      key: true,
    };

    await _box.put(accountAuthKey, data);
  }

  // =========================
  // 删除单个授权
  // =========================
  static Future<void> delete(
      String host,
      String wallet,
      String chainId,
      ) async {
    final key = _key(host, wallet, chainId);

    final data = {...allAuth};
    data.remove(key);

    await _box.put(accountAuthKey, data);
  }

  // =========================
  // 删除某个 host 的所有授权
  // =========================
  static Future<void> deleteHost(String host) async {
    final data = {...allAuth};
    final prefix = '${normalizeHost(host)}|';

    data.removeWhere((key, _) => key.startsWith(prefix));

    await _box.put(accountAuthKey, data);
  }

  // =========================
  // 清空全部授权
  // =========================
  static Future<void> clear() async {
    await _box.delete(accountAuthKey);
  }
}