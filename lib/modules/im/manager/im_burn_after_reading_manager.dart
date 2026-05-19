import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImBurnAfterReadingManager {
  static final ImBurnAfterReadingManager _instance =
      ImBurnAfterReadingManager._internal();

  factory ImBurnAfterReadingManager() => _instance;

  ImBurnAfterReadingManager._internal();

  static const List<int> durationOptions = [0, 10, 60, 300, 600, 1800];

  static const String _keyPrefix = 'im_burn_after_reading_seconds';

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

  String _cacheKey(
    RCIMIWConversationType type,
    String targetId,
    String? channelId,
  ) {
    return [_keyPrefix, type.index, targetId, channelId ?? ''].join('_');
  }
}
