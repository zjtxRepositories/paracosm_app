import 'package:paracosm/modules/im/manager/im_conversation_manager.dart';
import 'package:paracosm/modules/im/manager/im_group_manager.dart';
import 'package:paracosm/modules/im/manager/im_user_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../service/im_service.dart';
import 'im_connection_manager.dart';
import 'im_friend_applications_manager.dart';
import 'im_friend_manager.dart';
import 'im_message_manager.dart';

class IMEngineManager {
  static final IMEngineManager _instance = IMEngineManager._internal();
  factory IMEngineManager() => _instance;
  IMEngineManager._internal();

  final connection = ImConnectionManager();
  final message = ImMessageManager();
  final friend = ImFriendManager();
  final friendApplication = ImFriendApplicationsManager();
  final user = ImUserManager();
  final conversation = ImConversationManager();
  final group = ImGroupManager();

  RCIMIWEngine? _engine;

  String? _accountId;

  /// 初始化 SDK
  Future<void> init() async {
    if (_engine != null){
      await disconnect();
    }
    RCIMIWEngineOptions options = RCIMIWEngineOptions.create();
    options.areaCode = RCIMIWAreaCode.sg;
    RCIMIWEngine engine = await RCIMIWEngine.create(ImConfig.appKey, options);
    _engine = engine;
  }

  /// 连接 IM
  Future<void> connect(String token, String accountId) async {
    _accountId = accountId;

    RCIMIWConnectCallback? callback = RCIMIWConnectCallback(
        onDatabaseOpened: (int? code) {
//...
        },
        onConnected: (int? code, String? userId) {
//...
        },
        );

     await _engine?.connect(token, 15, callback: callback);

  }

  /// 断开连接
  Future<void> disconnect() async {
     await _engine?.disconnect(true);
    _accountId = null;
  }

  String? get currentUserId => _accountId;
  RCIMIWEngine? get engine => _engine;

}