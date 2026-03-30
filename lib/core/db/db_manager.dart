import 'package:paracosm/core/db/dao/account_dao.dart';
import 'package:paracosm/core/db/dao/app_config_dao.dart';
import 'package:paracosm/core/db/dao/wallet_dao.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBManager {
  static final DBManager _instance = DBManager._internal();
  factory DBManager() => _instance;

  DBManager._internal();

  final Map<String, Database> _dbCache = {};

  /// ========================
  /// 获取数据库
  /// ========================
  Future<Database> _openDB(String dbName) async {
    if (_dbCache.containsKey(dbName)) {
      return _dbCache[dbName]!;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _onCreate(db, dbName);
      },
      onOpen: (db) async {
        await _onCreate(db, dbName);
      },
    );

    _dbCache[dbName] = db;
    return db;
  }

  /// ========================
  /// 公共库
  /// ========================
  Future<Database> get globalDB async {
    return await _openDB('app_global.db');
  }

  /// ========================
  /// 用户库
  /// ========================
  Future<Database> getUserDB(String userId) async {
    return await _openDB('user_$userId.db');
  }

  /// ========================
  /// 建表
  /// ========================
  Future<void> _onCreate(Database db, String dbName) async {
    if (dbName == 'app_global.db') {
      await db.execute(AccountDao.createTableSql);
      await db.execute(AppConfigDao.createTableSql);
    } else {
      print('2-------');
      await db.execute(WalletDao.createTableSql);
    }
  }
}