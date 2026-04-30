// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:camera_web/camera_web.dart';
import 'package:file_picker/src/platform/web/file_picker_web.dart';
import 'package:flutter_image_compress_web/flutter_image_compress_web.dart';
import 'package:flutter_inappwebview_web/web/main.dart';
import 'package:flutter_native_splash/flutter_native_splash_web.dart';
import 'package:flutter_secure_storage_web/flutter_secure_storage_web.dart';
import 'package:flutter_sound_web/flutter_sound_web.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:mobile_scanner/src/web/mobile_scanner_web.dart';
import 'package:record_web/record_web.dart';
import 'package:sensors_plus/src/sensors_plus_web.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:video_player_web/video_player_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  CameraPlugin.registerWith(registrar);
  FilePickerWeb.registerWith(registrar);
  FlutterImageCompressWeb.registerWith(registrar);
  InAppWebViewFlutterPlugin.registerWith(registrar);
  FlutterNativeSplashWeb.registerWith(registrar);
  FlutterSecureStorageWeb.registerWith(registrar);
  FlutterSoundPlugin.registerWith(registrar);
  ImagePickerPlugin.registerWith(registrar);
  MobileScannerWeb.registerWith(registrar);
  RecordPluginWeb.registerWith(registrar);
  WebSensorsPlugin.registerWith(registrar);
  SharedPreferencesPlugin.registerWith(registrar);
  VideoPlayerPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
