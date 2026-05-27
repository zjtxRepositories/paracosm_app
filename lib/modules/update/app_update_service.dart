import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paracosm/router/app_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/common/app_loading.dart';
import 'package:paracosm/widgets/common/app_toast.dart';

import 'app_update_api.dart';
import 'app_update_installer_stub.dart'
    if (dart.library.io) 'app_update_installer_android.dart';
import 'app_update_policy.dart';
import 'app_version_model.dart';

class AppUpdateService {
  AppUpdateService._({AppUpdateApi? api}) : _api = api ?? AppUpdateApi();

  factory AppUpdateService() => instance;

  static final AppUpdateService instance = AppUpdateService._();

  final AppUpdateApi _api;
  bool _isChecking = false;
  bool _isDialogVisible = false;

  Future<void> checkOnStartup() async {
    if (!_isSupportedPlatform) {
      return;
    }

    await Future<void>.delayed(const Duration(seconds: 10));
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }

    await _check(context, isManual: false);
  }

  Future<void> checkManually(BuildContext context) async {
    if (!_isSupportedPlatform) {
      AppToast.show(AppLocalizations.currentText('app_update_latest'));
      return;
    }

    await _check(context, isManual: true);
  }

  bool get _isSupportedPlatform {
    return isAndroidAppUpdateTarget(
      platform: defaultTargetPlatform,
      isWeb: kIsWeb,
    );
  }

  Future<void> _check(BuildContext context, {required bool isManual}) async {
    if (_isChecking || _isDialogVisible) {
      return;
    }

    if (!_api.hasAuthKey) {
      debugPrint(
        'PARACOSM_APP_AUTH_KEY is not configured; skip app update check.',
      );
      if (isManual) {
        AppToast.show(AppLocalizations.currentText('app_update_latest'));
      }
      return;
    }

    _isChecking = true;
    if (isManual) {
      AppLoading.show();
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final model = await _api.checkUpdate(packageInfo.version);

      if (!context.mounted) {
        return;
      }

      if (isManual) {
        AppLoading.dismiss();
      }

      if (model == null) {
        if (isManual) {
          AppToast.show(AppLocalizations.currentText('common_update_failed'));
        }
        return;
      }

      if (!shouldShowAppUpdate(model)) {
        if (isManual) {
          AppToast.show(AppLocalizations.currentText('app_update_latest'));
        }
        return;
      }

      await _showUpdateDialog(context, model);
    } catch (error) {
      debugPrint('App update check failed: ${error.runtimeType}');
      if (isManual) {
        AppLoading.dismiss();
        AppToast.show(AppLocalizations.currentText('common_update_failed'));
      }
    } finally {
      _isChecking = false;
      if (isManual) {
        AppLoading.dismiss();
      }
    }
  }

  Future<void> _showUpdateDialog(
    BuildContext context,
    AppVersionModel model,
  ) async {
    _isDialogVisible = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !model.isForce,
        builder: (dialogContext) {
          final l10n = AppLocalizations.of(dialogContext)!;
          return PopScope(
            canPop: !model.isForce,
            child: AlertDialog(
              backgroundColor: AppColors.white,
              surfaceTintColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                l10n.appUpdateNewVersion(model.version),
                style: AppTextStyles.h2.copyWith(fontSize: 18),
              ),
              content: _UpdateDialogContent(model: model),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              actions: [
                if (!model.isForce)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      l10n.appUpdateLater,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.grey900,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final started = await _startUpdate(model);
                    if (!dialogContext.mounted) {
                      return;
                    }
                    if (started || !model.isForce) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text(l10n.appUpdateUpdateNow),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      _isDialogVisible = false;
    }
  }

  Future<bool> _startUpdate(AppVersionModel model) async {
    try {
      final started = await installAppUpdate(model);
      if (!started) {
        AppToast.show(AppLocalizations.currentText('common_update_failed'));
      }
      return started;
    } catch (error) {
      debugPrint('App update install failed: ${error.runtimeType}');
      AppToast.show(AppLocalizations.currentText('common_update_failed'));
      return false;
    }
  }
}

class _UpdateDialogContent extends StatelessWidget {
  const _UpdateDialogContent({required this.model});

  final AppVersionModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = model.updateContent.isEmpty
        ? l10n.appUpdateDefaultContent
        : model.updateContent;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (model.isForce) ...[
              Text(
                l10n.appUpdateForceHint,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              content,
              style: AppTextStyles.body.copyWith(
                color: AppColors.grey700,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
