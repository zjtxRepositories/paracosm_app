
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:uuid/uuid.dart';

import '../manager/im_engine_manager.dart';

class CustomMessage {
  static final _engine = IMEngineManager().engine;
  static final _myId = AccountManager().currentAccount?.accountId ?? '';

  static Future<RCIMIWCustomMessage?> createAddFriendFm({
    required String targetId}) async{
    String messageID = const Uuid().v4().replaceAll("-", "");
    final msg = await _engine?.createCustomMessage(
      RCIMIWConversationType.private,
      targetId,
      null,
      RCIMIWCustomMessagePolicy.normal,
      messageID,
      {
        "fromUserId": _myId,
        "toUserId": targetId,
        "content": '我们已成功添加为好友，现在可以开始聊天啦～',
      },
    );
    return msg;
  }

  static Future<RCIMIWCustomMessage?> createFm({
    required String targetId,
    required String content}) async{
    String messageID = const Uuid().v4().replaceAll("-", "");
    final msg = await _engine?.createCustomMessage(
      RCIMIWConversationType.private,
      targetId,
      null,
      RCIMIWCustomMessagePolicy.normal,
      messageID,
      {
        "fromUserId": _myId,
        "toUserId": targetId,
        "content": content,
      },
    );
    return msg;
  }

}