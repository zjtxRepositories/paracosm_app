import 'package:shared_preferences/shared_preferences.dart';

class PendingInvite {
  final String inviteCode;
  final String inviterUserId;
  final String inviterName;
  final String inviterAvatar;
  final int resolvedAt;

  const PendingInvite({
    required this.inviteCode,
    this.inviterUserId = '',
    this.inviterName = '',
    this.inviterAvatar = '',
    this.resolvedAt = 0,
  });

  bool get hasInviter => inviterUserId.isNotEmpty || inviterName.isNotEmpty;
}

class PendingInviteStore {
  PendingInviteStore({SharedPreferences? preferences})
    : _preferences = preferences;

  static const inviteCodeKey = 'pending_invite_code';
  static const resolvedAtKey = 'pending_invite_resolved_at';
  static const inviterNameKey = 'pending_inviter_name';
  static const inviterAvatarKey = 'pending_inviter_avatar';
  static const inviterUserIdKey = 'pending_inviter_user_id';

  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ?? SharedPreferences.getInstance();
  }

  Future<PendingInvite?> get() async {
    final prefs = await _prefs;
    final code = prefs.getString(inviteCodeKey)?.trim() ?? '';
    if (code.isEmpty) return null;
    return PendingInvite(
      inviteCode: code,
      inviterUserId: prefs.getString(inviterUserIdKey)?.trim() ?? '',
      inviterName: prefs.getString(inviterNameKey)?.trim() ?? '',
      inviterAvatar: prefs.getString(inviterAvatarKey)?.trim() ?? '',
      resolvedAt: prefs.getInt(resolvedAtKey) ?? 0,
    );
  }

  Future<void> save(PendingInvite invite) async {
    final prefs = await _prefs;
    await prefs.setString(inviteCodeKey, invite.inviteCode.trim());
    await prefs.setString(inviterUserIdKey, invite.inviterUserId.trim());
    await prefs.setString(inviterNameKey, invite.inviterName.trim());
    await prefs.setString(inviterAvatarKey, invite.inviterAvatar.trim());
    await prefs.setInt(
      resolvedAtKey,
      invite.resolvedAt > 0
          ? invite.resolvedAt
          : DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(inviteCodeKey);
    await prefs.remove(resolvedAtKey);
    await prefs.remove(inviterNameKey);
    await prefs.remove(inviterAvatarKey);
    await prefs.remove(inviterUserIdKey);
  }
}
