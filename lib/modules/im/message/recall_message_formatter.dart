import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/modules/im/manager/im_engine_manager.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class RecallMessageFormatter {
  RecallMessageFormatter._();

  static Future<String> format(RCIMIWMessage message) async {
    final userId = _recallUserId(message);
    if (userId.isEmpty) {
      return AppLocalizations.currentText('chat_recalled_message');
    }

    if (userId == IMEngineManager().currentUserId) {
      return AppLocalizations.currentText('chat_detail_withdrew_message');
    }

    if (_conversationType(message) == RCIMIWConversationType.private) {
      return AppLocalizations.currentText('chat_recalled_message_by_other');
    }

    final name = await _displayName(userId);
    return AppLocalizations.currentText('chat_recalled_message_with_user', {
      'user': name,
    });
  }

  static String _recallUserId(RCIMIWMessage message) {
    final originalSender = message is RCIMIWRecallNotificationMessage
        ? message.originalMessage?.senderUserId?.trim()
        : null;
    if (originalSender != null && originalSender.isNotEmpty) {
      return originalSender;
    }

    final sender = message.senderUserId?.trim();
    if (sender != null && sender.isNotEmpty) {
      return sender;
    }

    final operatorId = message is RCIMIWRecallNotificationMessage
        ? message.operatorId?.trim()
        : null;
    return operatorId ?? '';
  }

  static RCIMIWConversationType? _conversationType(RCIMIWMessage message) {
    final originalType = message is RCIMIWRecallNotificationMessage
        ? message.originalMessage?.conversationType
        : null;
    return originalType ?? message.conversationType;
  }

  static Future<String> _displayName(String userId) async {
    try {
      final center = UserDisplayStateCenter();
      final cached = center.getCached(userId);
      if (cached != null) {
        final name = cached.name.trim();
        if (name.isNotEmpty) return name;
      }

      if (IMEngineManager().engine == null) {
        return _fallbackName(userId);
      }

      final user = await center.getUser(userId);
      final name = user?.name.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    } catch (_) {}

    return _fallbackName(userId);
  }

  static String _fallbackName(String userId) {
    if (userId.length <= 8) return userId;
    return userId.substring(userId.length - 8);
  }
}
