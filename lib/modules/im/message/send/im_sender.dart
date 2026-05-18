import 'dart:async';

import '../base/im_message.dart';
import 'im_send_queue.dart';

class ImSender {
  static final ImSender instance = ImSender._();

  ImSender._();

  Future<bool> send({
    required ImMessage message,
    void Function(bool success)? onResult,
  }) async {
    final rcMsg = await message.toRCMessage();
    if (rcMsg == null) return false;

    final task = SendTask(rcMsg);

    StreamSubscription<SendQueueEvent>? sub;
    sub = ImSendQueue.instance.stream.listen((event) {
      if (event.taskId == task.taskId) {
        onResult?.call(event.success);
        sub?.cancel();
      }
    });

    ImSendQueue.instance.enqueue(task);

    return true;
  }

  Future<bool> sendAndWait({
    required ImMessage message,
    void Function(int progress)? onProgress,
    bool pushSavedMessage = true,
  }) async {
    final rcMsg = await message.toRCMessage();
    if (rcMsg == null) return false;

    final task = SendTask(
      rcMsg,
      onProgress: onProgress,
      pushSavedMessage: pushSavedMessage,
    );
    final completer = Completer<bool>();

    StreamSubscription<SendQueueEvent>? sub;
    sub = ImSendQueue.instance.stream.listen((event) {
      if (event.taskId != task.taskId) {
        return;
      }

      if (!completer.isCompleted) {
        completer.complete(event.success);
      }
      sub?.cancel();
    });

    ImSendQueue.instance.enqueue(task);

    return completer.future.whenComplete(() => sub?.cancel());
  }
}
