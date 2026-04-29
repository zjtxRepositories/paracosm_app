import 'package:flutter/cupertino.dart';

class ScrollEngine {
  ScrollEngine({
    required this.getId,
    required this.onUpdate,
  });

  final List<String> _order = [];
  final Map<String, dynamic> _map = {};

  final ScrollController scrollController = ScrollController();

  final String Function(dynamic item) getId;
  final VoidCallback onUpdate;

  bool isAtBottom = true;

  List<dynamic> get list =>
      _order.map((e) => _map[e]!).toList();

  /// =========================
  /// init
  /// =========================
  void init() {
    scrollController.addListener(_onScroll);
  }

  void dispose() {
    scrollController.dispose();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final pos = scrollController.position;
    isAtBottom = pos.pixels >= pos.maxScrollExtent - 100;
  }

  /// =========================
  /// merge（首屏）
  /// =========================
  void merge(List<dynamic> incoming) {
    for (final item in incoming) {
      final id = getId(item);

      _map[id] = item;

      if (!_order.contains(id)) {
        _order.add(id);
      }
    }

    onUpdate();
  }

  /// =========================
  /// 首屏滚到底（不闪）
  /// =========================
  void onFirstLoaded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      scrollController.jumpTo(
        scrollController.position.maxScrollExtent,
      );
    });
  }

  /// =========================
  /// 新消息
  /// =========================
  void append(dynamic item) {
    final id = getId(item);

    _map[id] = item;

    if (!_order.contains(id)) {
      _order.add(id);
    }

    final shouldScroll = isAtBottom;

    onUpdate();

    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;

        scrollController.jumpTo(
          scrollController.position.maxScrollExtent,
        );
      });
    }
  }

  /// =========================
  /// 加载更多（防跳核心）
  /// =========================
  void prepend(List<dynamic> incoming) {
    if (!scrollController.hasClients) return;

    final oldOffset = scrollController.offset;
    final oldMax = scrollController.position.maxScrollExtent;

    for (final item in incoming.reversed) {
      final id = getId(item);

      _map[id] = item;

      if (!_order.contains(id)) {
        _order.insert(0, id);
      }
    }

    onUpdate();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      final newMax = scrollController.position.maxScrollExtent;
      final diff = newMax - oldMax;

      scrollController.jumpTo(oldOffset + diff);
    });
  }

  /// =========================
  /// 滚到底（手动）
  /// =========================
  void scrollToBottom() {
    if (!scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      scrollController.jumpTo(
        scrollController.position.maxScrollExtent,
      );
    });
  }
}