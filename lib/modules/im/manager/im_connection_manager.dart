import 'dart:async';

import 'package:paracosm/modules/im/service/im_service.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import 'im_engine_manager.dart';

class ImEvent {
  static const connected = 'connected';
  static const disconnected = 'disconnected';
  static const tokenExpired = 'tokenExpired';
}

class ImConnectionManager {
  ImConnectionManager._internal();
  static final ImConnectionManager _instance =
  ImConnectionManager._internal();

  factory ImConnectionManager() => _instance;

  final StreamController<String> _eventController =
  StreamController<String>.broadcast();

  Stream<String> get eventStream => _eventController.stream;

  bool _connected = false;

  int _retryCount = 0;
  final int _maxRetry = 5;

  bool _isReconnecting = false;

  void initListener() {
    IMEngineManager().engine?.onConnectionStatusChanged = (RCIMIWConnectionStatus? status) {
      onConnectionStatusChanged(status);
    };
  }

  void onConnectionStatusChanged(RCIMIWConnectionStatus? status) {
    switch (status) {
      case RCIMIWConnectionStatus.connected:
        _connected = true;
        _retryCount = 0;
        _isReconnecting = false;

        _eventController.add(ImEvent.connected);
        IMEngineManager().conversation.initAll();
        print("IM 已连接");
        break;

      case RCIMIWConnectionStatus.timeout:
      case RCIMIWConnectionStatus.unconnected:
      case RCIMIWConnectionStatus.networkUnavailable:
        _connected = false;
        _eventController.add(ImEvent.disconnected);
        _tryReconnect();
        print("IM 已断开");
        break;

      case RCIMIWConnectionStatus.tokenIncorrect:
        _connected = false;
        _eventController.add(ImEvent.tokenExpired);
        ImService.refreshToken();
        break;
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
      case RCIMIWConnectionStatus.unknown:
        // TODO: Handle this case.
        throw UnimplementedError();
      case null:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// 重连核心逻辑
  Future<void> _tryReconnect() async {
    if (_isReconnecting) return;
    if (_retryCount >= _maxRetry) {
      print("❌ 达到最大重试次数");
      return;
    }

    _isReconnecting = true;
    _retryCount++;

    try {
      await Future.delayed(Duration(seconds: 2 * _retryCount));

      await ImService.reconnect();

      _retryCount = 0;
    } catch (e) {
      print("❌ 重连失败: $e");
      await Future.delayed(const Duration(seconds: 1));
      _tryReconnect(); // 👈 受控递归
    } finally {
      _isReconnecting = false;
    }
  }

  Future<void> disconnect() async {
    await IMEngineManager().disconnect();
    _connected = false;
    _eventController.add(ImEvent.disconnected);
  }

  bool get isConnected => _connected;
}