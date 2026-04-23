import 'package:sqflite/sqflite.dart';

import '../db_manager.dart';
import 'app_config_dao.dart';

const bool kDBLog = true;

abstract class BaseDao {
  /// ========================
  /// 获取公共数据库
  /// ========================
  Future<Database> get globalDB async {
    return await DBManager().globalDB;
  }

  /// ========================
  /// 获取当前用户数据库（🔥核心）
  /// ========================
  Future<Database> get userDB async {
    final userId = await AppConfigDao().getCurrentUser();

    if (userId == null || userId.isEmpty) {
      throw Exception('当前用户未登录');
    }

    return await DBManager().getUserDB(userId);
  }

  /// ========================
  /// 插入
  /// ========================
  Future<int> insert(
      String table,
      Map<String, dynamic> data, {
        bool useUserDB = false,
      }) async {
    final db = useUserDB ? await userDB : await globalDB;
    // print('use-----$useUserDB');
    _log('INSERT INTO $table -> $data');

    return await db.insert(table, data,conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// ========================
  /// 查询
  /// ========================
  Future<List<Map<String, dynamic>>> query(
      String table, {
        String? where,
        List<Object?>? whereArgs,
        String? orderBy,
        int? limit,
        int? offset,
        bool useUserDB = false,
      }) async {
    final db = useUserDB ? await userDB : await globalDB;

    final result = await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    _log('QUERY $table -> ${result.length} 条');

    return result;
  }

  /// ========================
  /// 查询单条
  /// ========================
  Future<Map<String, dynamic>?> queryOne(
      String table, {
        String? where,
        List<Object?>? whereArgs,
        bool useUserDB = false,
      }) async {
    final result = await query(
      table,
      where: where,
      whereArgs: whereArgs,
      limit: 1,
      useUserDB: useUserDB,
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  /// ========================
  /// 更新
  /// ========================
  Future<int> update(
      String table,
      Map<String, dynamic> data, {
        String? where,
        List<Object?>? whereArgs,
        bool useUserDB = false,
      }) async {
    final db = useUserDB ? await userDB : await globalDB;

    _log('UPDATE $table -> $data');

    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// ========================
  /// 删除
  /// ========================
  Future<int> delete(
      String table, {
        String? where,
        List<Object?>? whereArgs,
        bool useUserDB = false,
      }) async {
    final db = useUserDB ? await userDB : await globalDB;

    _log('DELETE FROM $table');

    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// ========================
  /// 事务（🔥钱包/IM必用）
  /// ========================
  Future<T> transaction<T>(
      Future<T> Function(Transaction txn) action, {
        bool useUserDB = false,
      }) async {
    final db = useUserDB ? await userDB : await globalDB;

    _log('BEGIN TRANSACTION');

    return await db.transaction((txn) async {
      return await action(txn);
    });
  }

  /// ========================
  /// 批量操作
  /// ========================
  Future<void> batch(
      void Function(Batch batch) action, {
        bool useUserDB = false,
      }) async {
    final db = useUserDB ? await userDB : await globalDB;

    final batchObj = db.batch();

    action(batchObj);

    _log('BATCH EXECUTE');

    await batchObj.commit(noResult: true);
  }

  /// ========================
  /// 原生 SQL
  /// ========================
  Future<List<Map<String, dynamic>>> rawQuery(
      String sql, [
        List<Object?>? args,
        bool useUserDB = false,
      ]) async {
    final db = useUserDB ? await userDB : await globalDB;

    _log('RAW QUERY: $sql');

    return await db.rawQuery(sql, args);
  }

  /// ========================
  /// 日志
  /// ========================
  void _log(String msg) {
    if (kDBLog) {
      // ignore: avoid_print
      print('[DB] $msg');
    }
  }
}