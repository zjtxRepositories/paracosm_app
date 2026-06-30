import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/scan/scan_result_parser.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

import 'invite_service.dart';

class InviteClipboardService {
  InviteClipboardService._();

  static final InviteClipboardService instance = InviteClipboardService._();

  static final RegExp _codePattern = RegExp(r'^(?=.*\d)[A-Za-z0-9_-]{6,32}$');

  final InviteService _inviteService = InviteService();
  String? _lastPromptedCode;
  bool _isChecking = false;

  Future<void> checkOnStartup(BuildContext context) async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!context.mounted) return;

      final existing = await _inviteService.getPendingInvite();
      if (existing != null && existing.inviteCode.trim().isNotEmpty) {
        return;
      }

      final code = await _readInviteCodeFromClipboard();
      if (code == null || code == _lastPromptedCode) return;

      if (AccountManager().isLogin &&
          await _shouldIgnoreClipboardInviteCode(code)) {
        _lastPromptedCode = code;
        return;
      }

      if (!context.mounted) return;
      _lastPromptedCode = code;
      await _promptUseInviteCode(context, code);
    } catch (_) {
      // Clipboard access is best-effort and must never block app startup.
    } finally {
      _isChecking = false;
    }
  }

  Future<String?> _readInviteCodeFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    return extractInviteCode(text);
  }

  static String? extractInviteCode(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;

    final scanResult = ScanResultParser.parse(value);
    if (scanResult.type == ScanResultType.invite) {
      final code = scanResult.inviteCode?.trim() ?? '';
      return code.isEmpty ? null : code;
    }

    return _codePattern.hasMatch(value) ? value : null;
  }

  Future<void> _promptUseInviteCode(BuildContext context, String code) async {
    await AppModal.show(
      context,
      title: AppLocalizations.currentText('invite_clipboard_title'),
      subtitle: code,
      description: AppLocalizations.currentText('invite_clipboard_desc'),
      confirmText: AppLocalizations.currentText('invite_clipboard_use'),
      cancelText: AppLocalizations.currentText('common_cancel'),
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: () async {
        Navigator.of(context).pop();
        await _useInviteCode(context, code);
      },
    );
  }

  Future<void> _useInviteCode(BuildContext context, String code) async {
    final isLogin = AccountManager().isLogin;
    if (isLogin && await _stopIfInviteShouldBeSkipped(code)) {
      return;
    }

    final resolved = await _inviteService.captureInviteCode(code);
    if (resolved != null && !resolved.isValid) {
      AppToast.show(AppLocalizations.currentText('invite_code_invalid'));
      return;
    }

    if (isLogin) {
      final didBind = await _inviteService.tryBindPendingInviteIfNeeded();
      AppToast.show(
        AppLocalizations.currentText(
          didBind ? 'invite_bind_success' : 'invite_code_saved',
        ),
      );
    } else {
      AppToast.show(AppLocalizations.currentText('invite_code_saved'));
      if (context.mounted) {
        context.push('/wallet-start');
      }
    }
  }

  Future<bool> _stopIfInviteShouldBeSkipped(String code) async {
    try {
      final reason = await _inviteService.getInviteSkipReason(code);
      if (reason != InviteSkipReason.none) {
        await _inviteService.clearPendingInvite();
        AppToast.show(_inviteSkipMessage(reason));
        return true;
      }
      return false;
    } catch (_) {
      AppToast.show(AppLocalizations.currentText('invite_load_failed'));
      return true;
    }
  }

  String _inviteSkipMessage(InviteSkipReason reason) {
    return AppLocalizations.currentText(switch (reason) {
      InviteSkipReason.alreadyHasParent => 'invite_already_has_parent',
      InviteSkipReason.selfInviteCode => 'invite_self_code_not_allowed',
      InviteSkipReason.none => 'invite_code_invalid',
    });
  }

  Future<bool> _shouldIgnoreClipboardInviteCode(String code) async {
    try {
      final reason = await _inviteService.getInviteSkipReason(code);
      if (reason != InviteSkipReason.none) {
        await _inviteService.clearPendingInvite();
        return true;
      }
      return false;
    } catch (_) {
      return true;
    }
  }
}
