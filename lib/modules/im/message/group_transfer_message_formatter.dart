import 'package:paracosm/core/models/custom_message_model.dart';
import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

class GroupTransferMessageFormatter {
  GroupTransferMessageFormatter._();

  static Future<String> format(CustomMessageModel message) async {
    final operatorId = message.fromUserId.trim();
    final targetId = message.userIds?.firstOrNull?.trim() ?? '';
    final currentUserId = IMEngineManager().currentUserId;

    if (_isSameUser(operatorId, currentUserId)) {
      final target = await _displayName(targetId);
      return AppLocalizations.currentText('chat_group_transferred_by_me', {
        'target': target,
      });
    }

    if (_isSameUser(targetId, currentUserId)) {
      final user = await _displayName(operatorId);
      return AppLocalizations.currentText('chat_group_transferred_to_me', {
        'user': user,
      });
    }

    final user = await _displayName(operatorId);
    final target = await _displayName(targetId);
    return AppLocalizations.currentText('chat_group_transferred_message', {
      'user': user,
      'target': target,
    });
  }

  static Future<String> _displayName(String userId) async {
    if (userId.isEmpty) return '';

    if (_isSameUser(userId, IMEngineManager().currentUserId)) {
      return AppLocalizations.currentText('chat_me');
    }

    try {
      final center = UserDisplayStateCenter();
      final cached =
          center.getCached(userId) ??
          _findCachedUser(center, userId, minSuffixLength: 7);
      final cachedName = cached?.name.trim();
      if (cachedName != null && cachedName.isNotEmpty) {
        return cachedName;
      }

      if (IMEngineManager().engine != null) {
        final user = await center.getUser(userId);
        final name = user?.name.trim();
        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    } catch (_) {}

    return _fallbackName(userId);
  }

  static String _fallbackName(String userId) {
    if (userId.length <= 8) return userId;
    return userId.substring(userId.length - 8);
  }

  static bool _isSameUser(String? a, String? b) {
    return _isSameNormalizedUser(a, b, minSuffixLength: 8);
  }

  static bool _isSameNormalizedUser(
    String? a,
    String? b, {
    required int minSuffixLength,
  }) {
    final left = _normalizeUserId(a);
    final right = _normalizeUserId(b);
    if (left == null || left.isEmpty || right == null || right.isEmpty) {
      return false;
    }
    if (left == right) return true;

    final shorter = left.length <= right.length ? left : right;
    final longer = left.length > right.length ? left : right;
    return shorter.length >= minSuffixLength && longer.endsWith(shorter);
  }

  static String? _normalizeUserId(String? value) {
    final normalized = value?.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  static UserDisplayModel? _findCachedUser(
    UserDisplayStateCenter center,
    String userId,
    {required int minSuffixLength}
  ) {
    for (final user in center.snapshot().values) {
      if (_isSameNormalizedUser(
        user.userId,
        userId,
        minSuffixLength: minSuffixLength,
      )) {
        return user;
      }
    }
    return null;
  }
}
