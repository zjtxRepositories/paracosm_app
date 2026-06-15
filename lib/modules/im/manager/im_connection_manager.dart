import 'dart:async';

import 'package:flutter/foundation.dart';
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
  static final ImConnectionManager _instance = ImConnectionManager._internal();

  factory ImConnectionManager() => _instance;

  final StreamController<String> _eventController =
      StreamController<String>.broadcast();

  Stream<String> get eventStream => _eventController.stream;

  bool _connected = false;

  int _retryCount = 0;

  bool _isReconnecting = false;
  Timer? _reconnectTimer;

  void initListener() {
    IMEngineManager().engine?.onConnectionStatusChanged =
        (RCIMIWConnectionStatus? status) {
          onConnectionStatusChanged(status);
        };
  }

  void onConnectionStatusChanged(RCIMIWConnectionStatus? status) {
    switch (status) {
      case RCIMIWConnectionStatus.connected:
        _connected = true;
        _retryCount = 0;
        _isReconnecting = false;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;

        _eventController.add(ImEvent.connected);
        final accountId = IMEngineManager().currentUserId;
        if (accountId != null) {
          unawaited(
            ImService.asyncSelfInfo(accountId: accountId).catchError((error) {
              debugPrint('asyncSelfInfo failed: $error');
            }),
          );
        }
        debugPrint('IM 已连接');
        break;

      case RCIMIWConnectionStatus.timeout:
      case RCIMIWConnectionStatus.unconnected:
      case RCIMIWConnectionStatus.networkUnavailable:
        _connected = false;
        _eventController.add(ImEvent.disconnected);
        _tryReconnect();
        debugPrint('IM 已断开');
        break;

      case RCIMIWConnectionStatus.tokenIncorrect:
        _connected = false;
        _eventController.add(ImEvent.tokenExpired);
        ImService.refreshToken();
        break;
      case RCIMIWConnectionStatus.connecting:
        debugPrint('连接中');
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
    if (_connected || _isReconnecting || _reconnectTimer?.isActive == true) {
      return;
    }

    final delaySeconds = (2 * (_retryCount + 1)).clamp(2, 10).toInt();
    _retryCount++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _reconnectTimer = null;
      unawaited(_reconnect());
    });
  }

  Future<void> _reconnect() async {
    if (_connected || _isReconnecting) return;

    _isReconnecting = true;

    try {
      await ImService.reconnect();
    } catch (e) {
      debugPrint('IM 重连失败: $e');
    } finally {
      _isReconnecting = false;
      if (!_connected) {
        unawaited(_tryReconnect());
      }
    }
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await IMEngineManager().disconnect();
    _connected = false;
    _eventController.add(ImEvent.disconnected);
  }

  bool get isConnected => _connected;
}
