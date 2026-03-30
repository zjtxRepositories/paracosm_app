import 'base_dao.dart';

class AppConfigDao extends BaseDao {
  static const table = 'app_config';

  static const String createTableSql = '''
  CREATE TABLE IF NOT EXISTS $table (
  key TEXT PRIMARY KEY,
          value TEXT
  )
  ''';


  Future<void> setCurrentUser(String userId) async {
    await insert(
      table,
      {'key': 'currentUserId', 'value': userId},
      useUserDB: false,
    );
  }

  Future<String?> getCurrentUser() async {
    final result = await queryOne(
      table,
      where: 'key = ?',
      whereArgs: ['currentUserId'],
      useUserDB: false,
    );

    return result?['value'];
  }
}