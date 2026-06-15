import 'package:paracosm/core/models/moment_message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MomentMessageCache {
  static const String _keyPrefix = 'moment_message_seen';

  Future<Set<String>> read(String accountId) async {
    final normalizedAccountId = _normalizeAccountId(accountId);
    if (normalizedAccountId.isEmpty) return const {};

    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(normalizedAccountId)) ?? const <String>[])
        .toSet();
  }

  Future<void> save(String accountId, List<MomentMessageModel> messages) async {
    final normalizedAccountId = _normalizeAccountId(accountId);
    if (normalizedAccountId.isEmpty) return;

    final keys = messages.map((message) => message.cacheKey).toSet().toList()
      ..sort();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(normalizedAccountId), keys);
  }

  Future<bool> hasNewMessages(
    String accountId,
    List<MomentMessageModel> messages,
  ) async {
    if (messages.isEmpty) return false;
    final seenKeys = await read(accountId);
    return messages.any((message) => !seenKeys.contains(message.cacheKey));
  }

  String _key(String accountId) => '$_keyPrefix:$accountId';

  String _normalizeAccountId(String accountId) =>
      accountId.trim().toLowerCase();
}
