import 'package:flutter_easyloading/flutter_easyloading.dart';

class AppLoading {
  static void show() {
    EasyLoading.show();
  }

  static void success(String msg) {
    EasyLoading.showSuccess(msg);
  }

  static void error(String msg) {
    EasyLoading.showError(msg);
  }

  static void dismiss() {
    EasyLoading.dismiss();
  }
}