import 'package:flutter/foundation.dart';

import 'app_version_model.dart';

bool isAndroidAppUpdateTarget({
  required TargetPlatform platform,
  required bool isWeb,
}) {
  return !isWeb && platform == TargetPlatform.android;
}

bool hasAppUpdateAuthKey(String appAuthKey) {
  return appAuthKey.trim().isNotEmpty;
}

bool shouldShowAppUpdate(AppVersionModel? model) {
  return model?.canUpdate ?? false;
}
