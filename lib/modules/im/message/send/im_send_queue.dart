import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../manager/im_connection_manager.dart';
import '../../manager/im_message_manager.dart';
import '../../manager/im_send_manager.dart';

/// =========================
/// 发送任务
/// =========================
class SendTask {
  final RCIMIWMessage message;
  final String taskId;
  final void Function(int progress)? onProgress;
  final bool pushSavedMessage;

  /// 重试次数
  int retryCount = 0;

  /// 最大重试次数
  final int maxRetry;

  SendTask(
    this.message, {
    String? taskId,
    this.onProgress,
    this.pushSavedMessage = true,
    this.maxRetry = 3,
  }) : taskId =
           taskId ??
           'send-${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(message)}';
}

/// =========================
/// 队列事件（给 UI / Manager 用）
/// =========================
class SendQueueEvent {
  final String taskId;
  final RCIMIWMessage message;
  final bool success;

  SendQueueEvent(this.taskId, this.message, this.success);
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
  SendTask? _currentTask;

  StreamSubscription<String>? _connectionSubscription;

  /// 事件流（UI监听）
  final StreamController<SendQueueEvent> _controller =
      StreamController.broadcast();

  Stream<SendQueueEvent> get stream => _controller.stream;

  /// =========================
  /// 入队
  /// =========================
  void enqueue(SendTask task) {
    _listenConnection();
    _queue.add(task);
    _trySend();
  }

  void _listenConnection() {
    _connectionSubscription ??= ImConnectionManager().eventStream.listen((
      event,
    ) {
      if (event == ImEvent.connected) {
        _setWaitingStatus(false);
        _trySend();
      } else if (event == ImEvent.disconnected) {
        _setWaitingStatus(true);
      }
    });
  }

  void _setWaitingStatus(bool waiting) {
    final tasks = <SendTask>[..._queue];
    final currentTask = _currentTask;
    if (currentTask != null) {
      tasks.add(currentTask);
    }

    for (final task in tasks) {
      final nextStatus = waiting ? RCIMIWSentStatus.sending : null;
      if (task.message.sentStatus == nextStatus) continue;
      task.message.sentStatus = nextStatus;
      ImMessageManager().updateLocalMessage(task.message);
    }
  }

  /// =========================
  /// 尝试发送
  /// =========================
  void _trySend() {
    if (_isSending) return;
    if (_queue.isEmpty) return;
    if (!ImConnectionManager().isConnected) return;

    _consume();
  }

  /// =========================
  /// 消费队列
  /// =========================
  Future<void> _consume() async {
    if (_queue.isEmpty) return;

    _isSending = true;

    final task = _queue.removeFirst();
    _currentTask = task;
    final success = await ImSendManager.instance.sendMessage(
      task.message,
      onProgress: task.onProgress,
      pushSavedMessage: task.pushSavedMessage,
    );

    if (!success && !ImConnectionManager().isConnected) {
      task.message.sentStatus = RCIMIWSentStatus.sending;
      ImMessageManager().updateLocalMessage(task.message);
      _queue.addFirst(task);
      _currentTask = null;
      _isSending = false;
      return;
    }

    if (!success && task.retryCount < task.maxRetry) {
      await _handleRetry(task);
      _currentTask = null;
      _isSending = false;
      _trySend();
      return;
    }

    if (!success) {
      task.message.sentStatus = RCIMIWSentStatus.failed;
      ImMessageManager().updateLocalMessage(task.message);
    }

    /// 通知外部
    _controller.add(SendQueueEvent(task.taskId, task.message, success));

    _currentTask = null;
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
