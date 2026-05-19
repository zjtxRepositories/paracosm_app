import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImBurnAfterReadingManager {
  static final ImBurnAfterReadingManager _instance =
      ImBurnAfterReadingManager._internal();

  factory ImBurnAfterReadingManager() => _instance;

  ImBurnAfterReadingManager._internal();

  static const List<int> durationOptions = [0, 10, 60, 300, 600, 1800];

  static const String _durationKeyPrefix = 'im_burn_after_reading_seconds';

  static const String _messageExpireKeyPrefix =
      'im_burn_after_reading_message_expire';

  int durationForIndex(int index) {
    final safeIndex = index.clamp(0, durationOptions.length - 1);
    return durationOptions[safeIndex];
  }

  int indexForDuration(int seconds) {
    final index = durationOptions.indexOf(seconds);
    return index < 0 ? 0 : index;
  }

  Future<int> getDurationSeconds({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
  }) async {
    if (type != RCIMIWConversationType.private || targetId.isEmpty) {
      return 0;
    }

    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt(_cacheKey(type, targetId, channelId)) ?? 0;
    return durationOptions.contains(seconds) ? seconds : 0;
  }

  Future<bool> setDurationSeconds({
    required RCIMIWConversationType type,
    required String targetId,
    String? channelId,
    required int seconds,
  }) async {
    if (type != RCIMIWConversationType.private || targetId.isEmpty) {
      return false;
    }

    final safeSeconds = durationOptions.contains(seconds) ? seconds : 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_cacheKey(type, targetId, channelId), safeSeconds);
  }

  Future<int?> getMessageExpireTime(String messageKey) async {
    final safeKey = messageKey.trim();
    if (safeKey.isEmpty) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final expireTime = prefs.getInt(_messageExpireCacheKey(safeKey));
    return expireTime != null && expireTime > 0 ? expireTime : null;
  }

  Future<bool> saveMessageExpireTime(String messageKey, int expireTime) async {
    final safeKey = messageKey.trim();
    if (safeKey.isEmpty || expireTime <= 0) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_messageExpireCacheKey(safeKey), expireTime);
  }

  Future<bool> clearMessageExpireTime(String messageKey) async {
    final safeKey = messageKey.trim();
    if (safeKey.isEmpty) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_messageExpireCacheKey(safeKey));
  }

  Future<int?> ensureMessageExpireTime({
    required String messageKey,
    required int startTime,
    required int durationSeconds,
  }) async {
    final existingExpireTime = await getMessageExpireTime(messageKey);
    if (existingExpireTime != null) {
      return existingExpireTime;
    }

    if (startTime <= 0 || durationSeconds <= 0) {
      return null;
    }

    final expireTime = startTime + durationSeconds * 1000;
    final saved = await saveMessageExpireTime(messageKey, expireTime);
    return saved ? expireTime : null;
  }

  String _cacheKey(
    RCIMIWConversationType type,
    String targetId,
    String? channelId,
  ) {
    return [
      _durationKeyPrefix,
      type.index,
      targetId,
      channelId ?? '',
    ].join('_');
  }

  String _messageExpireCacheKey(String messageKey) {
    return [_messageExpireKeyPrefix, messageKey].join('_');
  }
}
