import 'package:hive/hive.dart';

import '../../account/manager/account_manager.dart';
import '../manager/im_engine_manager.dart';

class RedPacketClaimStore {
  static const String boxName = 'im.red_packet.claims';

  static Box get _box => Hive.box(boxName);

  static String? _resolveUserId(String? userId, {bool preferAccount = true}) {
    final accountId = AccountManager().currentUserId.trim();
    final value = userId ??
        (preferAccount && accountId.isNotEmpty
            ? accountId
            : IMEngineManager().currentUserId);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim().toLowerCase();
  }

  static String _key(String userId, String redPacketId) {
    return '$userId|$redPacketId';
  }

  static bool isClaimed(String redPacketId, {String? userId}) {
    final resolvedUserId = _resolveUserId(userId);
    final packetId = redPacketId.trim();
    if (resolvedUserId == null || packetId.isEmpty) {
      return false;
    }

    return _box.get(_key(resolvedUserId, packetId)) == true;
  }

  static int? claimedAt(String redPacketId, {String? userId}) {
    final resolvedUserId = _resolveUserId(userId);
    final packetId = redPacketId.trim();
    if (resolvedUserId == null || packetId.isEmpty) {
      return null;
    }

    final value = _box.get(_timeKey(resolvedUserId, packetId));
    if (value is int && value > 0) {
      return value;
    }
    if (value is num && value > 0) {
      return value.toInt();
    }
    return null;
  }

  static Future<void> markClaimed(
    String redPacketId, {
    String? userId,
    int? claimedAt,
  }) async {
    final resolvedUserId = _resolveUserId(userId);
    final packetId = redPacketId.trim();
    if (resolvedUserId == null || packetId.isEmpty) {
      return;
    }

    await _box.put(_key(resolvedUserId, packetId), true);
    await _box.put(
      _timeKey(resolvedUserId, packetId),
      claimedAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  static String _timeKey(String userId, String redPacketId) {
    return '${_key(userId, redPacketId)}|claimedAt';
  }
}
