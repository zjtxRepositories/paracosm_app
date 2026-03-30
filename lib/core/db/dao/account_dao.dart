import '../../../modules/account/model/account_model.dart';
import 'app_config_dao.dart';
import 'base_dao.dart';

class AccountDao extends BaseDao {
  static const String tableName = 'account';

  /// ========================
  /// 建表 SQL（全局库）
  /// ========================
  static const String createTableSql = '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id TEXT PRIMARY KEY,
    userId TEXT,
    nickname TEXT,
    avatar TEXT,
    token TEXT
  )
  ''';

  /// ========================
  /// 插入账号
  /// ========================
  Future<void> insertAccount(AccountModel model) async {
    await insert(
      tableName,
      model.toJson(),
      useUserDB: false, // 👈 全局库
    );
  }

  /// ========================
  /// 获取所有账号
  /// ========================
  Future<List<AccountModel>> getAccounts() async {
    final result = await query(
      tableName,
      useUserDB: false,
    );

    return result.map((e) => AccountModel.fromJson(e)).toList();
  }

  /// ========================
  /// 获取账号（根据 id）
  /// ========================
  Future<AccountModel?> getAccountById(String id) async {
    final result = await queryOne(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      useUserDB: false,
    );

    if (result == null) return null;

    return AccountModel.fromJson(result);
  }

  /// ========================
  /// 更新账号
  /// ========================
  Future<void> updateAccount(AccountModel model) async {
    await update(
      tableName,
      model.toJson(),
      where: 'id = ?',
      whereArgs: [model.id],
      useUserDB: false,
    );
  }

  /// ========================
  /// 删除账号
  /// ========================
  Future<void> deleteAccount(String id) async {
    await delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      useUserDB: false,
    );
  }

  /// ========================
  /// 清空账号
  /// ========================
  Future<void> clearAccounts() async {
    await delete(
      tableName,
      useUserDB: false,
    );
  }

  /// ========================
  /// 判断是否有账号
  /// ========================
  Future<bool> hasAccount() async {
    final result = await query(
      tableName,
      limit: 1,
      useUserDB: false,
    );

    return result.isNotEmpty;
  }

  /// ========================
  /// 替换账号（🔥登录时常用）
  /// ========================
  Future<void> replaceAccount(AccountModel model) async {
    await transaction((txn) async {
      await txn.delete(tableName);
      await txn.insert(tableName, model.toJson());
    }, useUserDB: false);
  }

  Future<AccountModel?> getCurrentAccount() async {
    final currentUserId = AppConfigDao().getCurrentUser();
    final result = await queryOne(
      tableName,
      where: 'id = ?',
      whereArgs: [currentUserId],
      useUserDB: false,
    );

    if (result == null) return null;

    return AccountModel.fromJson(result);
  }
}