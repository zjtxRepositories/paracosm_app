
import '../../../modules/wallet/model/wallet_model.dart';
import 'base_dao.dart';

class WalletDao extends BaseDao {
  static const String tableName = 'wallet';

  /// ========================
  /// 建表 SQL（在 DBManager 调用）
  /// ========================
  static const String createTableSql = '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id TEXT PRIMARY KEY,
    name TEXT,
    type TEXT,
    aIndex INTEGER,
    currentChainId INTEGER,
    chains TEXT
  )
  ''';

  /// ========================
  /// 插入钱包
  /// ========================
  Future<void> insertWallet(WalletModel model) async {
    await insert(
      tableName,
      model.toJson(),
    );
  }

  /// ========================
  /// 获取所有钱包
  /// ========================
  Future<List<WalletModel>> getWallets() async {
    final result = await query(tableName);

    return result.map((e) => WalletModel.fromJson(e)).toList();
  }

  /// ========================
  /// 获取单个钱包
  /// ========================
  Future<WalletModel?> getWalletById(String id) async {
    final result = await queryOne(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result == null) return null;

    return WalletModel.fromJson(result);
  }

  /// ========================
  /// 更新钱包
  /// ========================
  Future<void> updateWallet(WalletModel model) async {
    await update(
      tableName,
      model.toJson(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  /// ========================
  /// 删除钱包
  /// ========================
  Future<void> deleteWallet(String id) async {
    await delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// ========================
  /// 清空钱包（当前用户）
  /// ========================
  Future<void> clearWallets() async {
    await delete(tableName);
  }

  /// ========================
  /// 判断是否存在钱包
  /// ========================
  Future<bool> hasWallet() async {
    final result = await query(
      tableName,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// ========================
  /// 替换钱包（🔥常用）
  /// ========================
  Future<void> replaceWallet(WalletModel model) async {
    await transaction((txn) async {
      await txn.delete(tableName);
      await txn.insert(tableName, model.toJson());
    });
  }
}