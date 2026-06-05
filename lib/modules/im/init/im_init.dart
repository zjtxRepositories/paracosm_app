import 'package:flutter/foundation.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/call/rong_call_manager.dart';
import 'package:paracosm/modules/call/rong_call_summary_parser.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../manager/im_engine_manager.dart';
import '../manager/im_token_manager.dart';
import '../manager/im_user_manager.dart';
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
    IMEngineManager().conversation.initListener();
    IMEngineManager().group.initListener();
    IMEngineManager().subscribe.initListener();
    IMEngineManager().dataCenter.initListener();
    await RongCallManager().init();

    /// 3. 自动登录
    if (account != null) {
      await ImService.loginIm(account.accountId);
      getUserInfo();
    }
  }

  Future<void> _registerNativeMessages() async {
    final engine = IMEngineManager().engine;
    if (engine == null) return;

    final code = await engine.registerNativeCustomMessage(
      RongCallSummaryParser.objectName,
      RCIMIWNativeCustomMessagePersistentFlag.persisted,
    );

    if (kDebugMode && code != 0) {
      debugPrint('register call summary message failed: $code');
    }
  }

  Future<void> getUserInfo() async {
    final profile = await ImUserManager().getMyUserProfile();
    if (profile == null) return;
    AccountManager().updateAccountUserInfo(
      profile.name ?? '',
      profile.portraitUri ?? '',
    );
  }
}
