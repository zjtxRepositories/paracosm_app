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

    ImSendQueue.instance.stream.listen((event) {
      if (event.message.messageId == rcMsg.messageId) {
        onResult?.call(event.success);
      }
    });

    ImSendQueue.instance.enqueue(task);

    return true;
  }
}