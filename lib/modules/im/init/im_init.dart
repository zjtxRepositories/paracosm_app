import 'package:flutter/foundation.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/call/rong_group_call_status_message.dart';
import 'package:paracosm/modules/call/rong_call_invite_update_message.dart';
import 'package:paracosm/modules/call/rong_call_join_request_message.dart';
import 'package:paracosm/modules/call/rong_call_manager.dart';
import 'package:paracosm/modules/call/rong_call_summary_parser.dart';
import 'package:paracosm/modules/im/message/base/im_message.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../manager/im_engine_manager.dart';
import '../manager/im_token_manager.dart';
import '../service/im_service.dart';

class ImInit {
  Future<void> init() async {
    final account = AccountManager().currentAccount;
    if (account != null) {
      await ImTokenManager.restoreAppKey(account.accountId);
    }

    /// 1. 初始化 SDK
    await IMEngineManager().init();
    await _registerNativeMessages();

    /// 2 初始化监听
    IMEngineManager().connection.initListener();
    IMEngineManager().message.initListener();
    IMEngineManager().friend.initListener();
    IMEngineManager().friendApplication.initListener();
    IMEngineManager().groupApplication.initListener();
    IMEngineManager().conversation.initListener();
    IMEngineManager().group.initListener();
    IMEngineManager().subscribe.initListener();
    IMEngineManager().dataCenter.initListener();
    await RongCallManager().init();

    /// 3. 自动登录
    if (account != null) {
      await ImService.loginIm(account.accountId);
    }
  }

  Future<void> _registerNativeMessages() async {
    final engine = IMEngineManager().engine;
    if (engine == null) return;

    final code = await engine.registerNativeCustomMessage(
      RongCallSummaryParser.objectName,
      RCIMIWNativeCustomMessagePersistentFlag.persisted,
    );
    final inviteUpdateCode = await engine.registerNativeCustomMessage(
      RongCallInviteUpdateMessage.objectName,
      RCIMIWNativeCustomMessagePersistentFlag.status,
    );
    final groupCallStatusCode = await engine.registerNativeCustomMessage(
      RongGroupCallStatusMessage.objectName,
      RCIMIWNativeCustomMessagePersistentFlag.status,
    );
    final joinRequestCode = await engine.registerNativeCustomMessage(
      RongCallJoinRequestMessage.objectName,
      RCIMIWNativeCustomMessagePersistentFlag.status,
    );
    final redPacketCode = await engine.registerNativeCustomMessage(
      RedPacketMessage.serverMessageIdentifier,
      RCIMIWNativeCustomMessagePersistentFlag.persisted,
    );

    if (kDebugMode && code != 0) {
      debugPrint('register call summary message failed: $code');
    }
    if (kDebugMode && inviteUpdateCode != 0) {
      debugPrint(
        'register call invite update message failed: $inviteUpdateCode',
      );
    }
    if (kDebugMode && groupCallStatusCode != 0) {
      debugPrint(
        'register group call status message failed: $groupCallStatusCode',
      );
    }
    if (kDebugMode && joinRequestCode != 0) {
      debugPrint('register call join request message failed: $joinRequestCode');
    }
    if (kDebugMode && redPacketCode != 0) {
      debugPrint('register red packet message failed: $redPacketCode');
    }
  }
}
