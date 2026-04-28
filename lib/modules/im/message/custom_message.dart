
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/custom_message_model.dart';
import '../manager/im_engine_manager.dart';


class CustomMessage {
  static final _engine = IMEngineManager().engine;
  static final _myId = AccountManager().currentAccount?.accountId ?? '';


  static Future<RCIMIWCustomMessage?> createFm({
    required String targetId,
    required CustomMessageType type,
    String? content,
  }) async {
    String messageID = const Uuid().v4().replaceAll("-", "");
    final model = CustomMessageModel(
      type: CustomMessageType.friendAdd,
      fromUserId: _myId,
      toUserId: targetId,
      content: content,
    );
    final msg = await _engine?.createCustomMessage(
        RCIMIWConversationType.private,
        targetId,
        null,
        RCIMIWCustomMessagePolicy.normal,
        messageID,
        model.toJson()
    );
    return msg;
  }


}