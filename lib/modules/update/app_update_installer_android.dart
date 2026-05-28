import 'package:flutter_app_update/azhon_app_update.dart';
import 'package:flutter_app_update/update_model.dart';

import 'app_version_model.dart';

Future<bool> installAppUpdate(AppVersionModel model) {
  final updateModel = UpdateModel(
    model.download,
    'paracosm_update.apk',
    'ic_launcher',
    '',
    showNotification: false,
    jumpInstallPage: true,
    showBgdToast: false,
  );
  return AzhonAppUpdate.update(updateModel);
}
