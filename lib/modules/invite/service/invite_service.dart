import 'package:flutter/foundation.dart';
import 'package:paracosm/core/network/api/invite_api.dart';
import 'package:paracosm/modules/invite/model/invite_models.dart';

import 'pending_invite_store.dart';

enum InviteSkipReason { none, alreadyHasParent, selfInviteCode }

class InviteService {
  InviteService({InviteApi? api, PendingInviteStore? pendingStore})
    : _api = api ?? InviteApi(),
      _pendingStore = pendingStore ?? PendingInviteStore();

  final InviteApi _api;
  final PendingInviteStore _pendingStore;

  Future<InviteProfile> getProfile() => _api.getProfile();

  Future<InviteChildrenPage> getChildren({int page = 1, int pageSize = 20}) {
    return _api.getChildren(page: page, pageSize: pageSize);
  }

  Future<InviteResolveResult> resolve(String code) {
    return _api.resolve(code);
  }

  Future<bool> hasBoundParent() async {
    final profile = await getProfile();
    return profile.parent != null;
  }

  Future<InviteSkipReason> getInviteSkipReason(String code) async {
    final profile = await getProfile();
    if (profile.parent != null) {
      return InviteSkipReason.alreadyHasParent;
    }
    if (_sameInviteCode(profile.inviteCode, code)) {
      return InviteSkipReason.selfInviteCode;
    }
    return InviteSkipReason.none;
  }

  Future<InviteResolveResult?> captureInviteCode(String code) async {
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) return null;

    try {
      final result = await resolve(normalizedCode);
      if (!result.isValid) {
        await _pendingStore.clear();
        return result;
      }

      await _pendingStore.save(
        PendingInvite(
          inviteCode: result.inviteCode.isNotEmpty
              ? result.inviteCode
              : normalizedCode,
          inviterUserId: result.inviterUserId,
          inviterName: result.inviterName,
          inviterAvatar: result.inviterAvatar,
        ),
      );
      return result;
    } catch (error) {
      debugPrint('Invite resolve failed: $error');
      await _pendingStore.save(PendingInvite(inviteCode: normalizedCode));
      return null;
    }
  }

  Future<void> bindPendingInviteIfNeeded() async {
    await tryBindPendingInviteIfNeeded();
  }

  Future<bool> tryBindPendingInviteIfNeeded() async {
    final pending = await _pendingStore.get();
    if (pending == null || pending.inviteCode.trim().isEmpty) return false;

    try {
      final skipReason = await getInviteSkipReason(pending.inviteCode);
      if (skipReason != InviteSkipReason.none) {
        await _pendingStore.clear();
        return false;
      }

      await _api.bind(pending.inviteCode);
      await _pendingStore.clear();
      return true;
    } catch (error) {
      debugPrint('Invite bind failed: $error');
      return false;
    }
  }

  Future<PendingInvite?> getPendingInvite() => _pendingStore.get();

  Future<void> clearPendingInvite() => _pendingStore.clear();

  bool _sameInviteCode(String left, String right) {
    final normalizedLeft = left.trim().toUpperCase();
    final normalizedRight = right.trim().toUpperCase();
    return normalizedLeft.isNotEmpty && normalizedLeft == normalizedRight;
  }
}
