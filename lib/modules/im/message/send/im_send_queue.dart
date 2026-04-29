import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:paracosm/modules/im/manager/im_message_manager.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import '../../manager/im_send_manager.dart';

/// =========================
/// 发送任务
/// =========================
class SendTask {
  final RCIMIWMessage message;

  /// 重试次数
  int retryCount = 0;

  /// 最大重试次数
  final int maxRetry;

  SendTask(
      this.message, {
        this.maxRetry = 3,
      });
}

/// =========================
/// 队列事件（给 UI / Manager 用）
/// =========================
class SendQueueEvent {
  final RCIMIWMessage message;
  final bool success;

  SendQueueEvent(this.message, this.success);
}

/// =========================
/// 发送队列（核心）
/// =========================
class ImSendQueue {
  ImSendQueue._();
  static final ImSendQueue instance = ImSendQueue._();

  /// 队列
  final Queue<SendTask> _queue = Queue();

  /// 是否正在发送
  bool _isSending = false;

  /// 事件流（UI监听）
  final StreamController<SendQueueEvent> _controller =
  StreamController.broadcast();

  Stream<SendQueueEvent> get stream => _controller.stream;

  /// =========================
  /// 入队
  /// =========================
  void enqueue(SendTask task) {
    _queue.add(task);
    _trySend();
  }

  /// =========================
  /// 尝试发送
  /// =========================
  void _trySend() {
    if (_isSending) return;
    if (_queue.isEmpty) return;

    _consume();
  }

  /// =========================
  /// 消费队列
  /// =========================
  Future<void> _consume() async {
    if (_queue.isEmpty) return;

    _isSending = true;

    final task = _queue.removeFirst();
    final success = await ImSendManager.instance.sendMessage(
       task.message,
    );

    /// 通知外部
    _controller.add(SendQueueEvent(task.message, success));

    if (!success) {
      await _handleRetry(task);
    }

    _isSending = false;

    /// 继续发送下一个
    _trySend();
  }

  /// =========================
  /// 重试策略（指数退避）
  /// =========================
  Future<void> _handleRetry(SendTask task) async {
    if (task.retryCount >= task.maxRetry) {
      return;
    }

    task.retryCount++;

    /// 指数退避：1s / 2s / 4s
    final delaySeconds = pow(2, task.retryCount).toInt();

    await Future.delayed(Duration(seconds: delaySeconds));

    /// 放回队列头（优先重试）
    _queue.addFirst(task);
  }

  /// =========================
  /// 清空队列（可选）
  /// =========================
  void clear() {
    _queue.clear();
  }

  /// =========================
  /// 当前队列长度
  /// =========================
  int get length => _queue.length;
}