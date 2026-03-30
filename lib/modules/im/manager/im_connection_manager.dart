import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import 'im_engine_manager.dart';

class ImConnectionManager {
  bool _connected = false;

  void initListener() {
    IMEngineManager().engine?.onConnectionStatusChanged = (RCIMIWConnectionStatus? status) {
      onConnectionStatusChanged(status);
    };
  }

  void onConnectionStatusChanged(RCIMIWConnectionStatus? status) {
    switch (status) {
      case RCIMIWConnectionStatus.connected:
        _connected = true;
        print("IM 已连接");
        break;

      case RCIMIWConnectionStatus.unconnected:
        _connected = false;
        print("IM 已断开");
        break;

      case RCIMIWConnectionStatus.tokenIncorrect:
        print("Token 失效，需要重新获取");
        _connected = false;
        break;
      case RCIMIWConnectionStatus.networkUnavailable:
        _connected = false;
        throw UnimplementedError();
      case RCIMIWConnectionStatus.connecting:
        print("连接中");
        break;
      case RCIMIWConnectionStatus.kickedOfflineByOtherClient:
        // TODO: Handle this case.
        throw UnimplementedError();
      case RCIMIWConnectionStatus.connUserBlocked:
        // TODO: Handle this case.
        throw UnimplementedError();
      case RCIMIWConnectionStatus.signOut:
        // TODO: Handle this case.
        throw UnimplementedError();
      case RCIMIWConnectionStatus.suspend:
        // TODO: Handle this case.
        throw UnimplementedError();
      case RCIMIWConnectionStatus.timeout:
        print("自动连接超时");
        _connected = false;
        break;
      case RCIMIWConnectionStatus.unknown:
        // TODO: Handle this case.
        throw UnimplementedError();
      case null:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
  Future<void> disconnect() async {
    await IMEngineManager().disconnect();
    _connected = false;
  }

  bool get isConnected => _connected;
}