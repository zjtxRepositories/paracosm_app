import 'dart:async';

import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import 'im_result.dart';

class ImCallbackWrapper {

  /// 无返回数据
  static Future<ImResult<void>> wrap(
      Future<int?> Function(IRCIMIWOperationCallback callback) func,
      ) async {

    final completer = Completer<ImResult<void>>();

    final callback = IRCIMIWOperationCallback(
      onSuccess: () {
        completer.complete(ImResult.success());
      },
      onError: (code) {
        completer.complete(ImResult.error(code: code ?? -1));
      },
    );

    final ret = await func(callback);

    /// SDK层失败
    if (ret != null && ret != 0) {
      return ImResult.error(code: ret);
    }

    return completer.future;
  }

  /// 有返回数据
  static Future<ImResult<T>> wrapData<T>(
      Future<void> Function(Function(T data) onSuccess, Function(int code) onError) func,
      ) async {

    final completer = Completer<ImResult<T>>();

    await func(
          (data) => completer.complete(ImResult.success(data: data)),
          (code) => completer.complete(ImResult.error(code: code)),
    );

    return completer.future;
  }

  static Future<ImResult<int>> wrapAddFriend(
      Future<int?> Function(IRCIMIWAddFriendCallback callback) func,
      ) async {

    final completer = Completer<ImResult<int>>();

    final callback = IRCIMIWAddFriendCallback(
      onSuccess: (processCode) {
        completer.complete(
          ImResult.success(data: processCode ?? 0),
        );
      },
      onError: (code) {
        completer.complete(
          ImResult.error(code: code ?? -1),
        );
      },
    );

    final ret = await func(callback);

    if (ret != null && ret != 0) {
      return ImResult.error(code: ret);
    }

    return completer.future;
  }


}