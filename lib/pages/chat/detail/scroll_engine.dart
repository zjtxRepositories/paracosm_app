import 'package:flutter/cupertino.dart';

class ScrollEngine<T> {
  ScrollEngine({
    required this.getId,
    required this.onUpdate,
  });

  /// =========================
  /// 数据
  /// =========================
  final List<String> _order = [];

  final Map<String, T> _map = {};

  /// =========================
  /// scroll
  /// =========================
  final ScrollController scrollController =
  ScrollController();

  /// =========================
  /// callback
  /// =========================
  final String Function(T item) getId;

  final VoidCallback? onUpdate;

  /// =========================
  /// 状态
  /// =========================
  bool isAtBottom = true;

  /// =========================
  /// list
  /// =========================
  List<T> get list =>
      _order
          .map((e) => _map[e])
          .whereType<T>()
          .toList();

  int get length => _order.length;

  bool get isEmpty => _order.isEmpty;

  bool get isNotEmpty => _order.isNotEmpty;

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
    if (!scrollController.hasClients) {
      return;
    }

    final pos = scrollController.position;

    isAtBottom =
        pos.pixels >=
            pos.maxScrollExtent - 100;
  }

  /// =========================
  /// contains
  /// =========================
  bool containsId(String id) {
    return _map.containsKey(id);
  }

  /// =========================
  /// 获取
  /// =========================
  T? findById(String id) {
    return _map[id];
  }

  /// =========================
  /// clear
  /// =========================
  void clear() {
    _order.clear();

    _map.clear();

    onUpdate?.call();
  }

  /// =========================
  /// merge（首屏）
  /// =========================
  void merge(List<T> incoming) {
    for (final item in incoming) {
      final id = getId(item);

      _map[id] = item;

      if (!_order.contains(id)) {
        _order.add(id);
      }
    }

    onUpdate?.call();
  }

  /// =========================
  /// append（新消息）
  /// =========================
  void append(T item) {
    final id = getId(item);

    final shouldScroll = isAtBottom;

    /// 更新
    if (_map.containsKey(id)) {
      _map[id] = item;

      onUpdate?.call();

      return;
    }

    /// 新增
    _map[id] = item;

    _order.add(id);

    onUpdate?.call();

    if (shouldScroll) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (!scrollController.hasClients) {
          return;
        }

        scrollController.jumpTo(
          scrollController
              .position
              .maxScrollExtent,
        );
      });
    }
  }

  /// =========================
  /// insertAt（指定位置插入）
  /// =========================
  void insertAt(int index, T item) {
    final id = getId(item);

    final shouldScroll = isAtBottom;

    if (_map.containsKey(id)) {
      _map[id] = item;

      onUpdate?.call();

      return;
    }

    final safeIndex = index < 0
        ? 0
        : (index > _order.length ? _order.length : index);

    _map[id] = item;

    _order.insert(safeIndex, id);

    onUpdate?.call();

    if (shouldScroll && safeIndex == _order.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) {
          return;
        }

        scrollController.jumpTo(
          scrollController.position.maxScrollExtent,
        );
      });
    }
  }

  /// =========================
  /// prepend（加载更多）
  /// =========================
  void prepend(List<T> incoming) {
    if (!scrollController.hasClients) {
      merge(incoming);
      return;
    }

    final oldOffset =
        scrollController.offset;

    final oldMax =
        scrollController
            .position
            .maxScrollExtent;

    for (final item
    in incoming.reversed) {
      final id = getId(item);

      _map[id] = item;

      if (!_order.contains(id)) {
        _order.insert(0, id);
      }
    }

    onUpdate?.call();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }

      final newMax =
          scrollController
              .position
              .maxScrollExtent;

      final diff = newMax - oldMax;

      scrollController.jumpTo(
        oldOffset + diff,
      );
    });
  }

  /// =========================
  /// replace
  /// =========================
  void replace(T item) {
    final id = getId(item);

    if (!_map.containsKey(id)) {
      return;
    }

    _map[id] = item;

    onUpdate?.call();
  }

  /// =========================
  /// replaceWhere
  /// =========================
  void replaceWhere(
      bool Function(T item) test,
      T newItem,
      ) {
    final target = list.where(test);

    if (target.isEmpty) return;

    final old = target.first;

    final id = getId(old);

    _map[id] = newItem;

    onUpdate?.call();
  }

  /// =========================
  /// remove
  /// =========================
  void remove(T item) {
    final id = getId(item);

    _order.remove(id);

    _map.remove(id);

    onUpdate?.call();
  }

  /// =========================
  /// removeById
  /// =========================
  void removeById(String id) {
    _order.remove(id);

    _map.remove(id);

    onUpdate?.call();
  }

  /// =========================
  /// removeWhere
  /// =========================
  void removeWhere(
      bool Function(T item) test,
      ) {
    final removeIds = <String>[];

    for (final id in _order) {
      final item = _map[id];

      if (item == null) continue;

      if (test(item)) {
        removeIds.add(id);
      }
    }

    for (final id in removeIds) {
      _order.remove(id);

      _map.remove(id);
    }

    if (removeIds.isNotEmpty) {
      onUpdate?.call();
    }
  }

  /// =========================
  /// updateWhere
  /// =========================
  void updateWhere(
      bool Function(T item) test,
      T Function(T old) update,
      ) {
    bool changed = false;

    for (final id in _order) {
      final item = _map[id];

      if (item == null) continue;

      if (test(item)) {
        _map[id] = update(item);

        changed = true;
      }
    }

    if (changed) {
      onUpdate?.call();
    }
  }

  /// =========================
  /// first loaded
  /// =========================
  void onFirstLoaded() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }

      scrollController.jumpTo(
        scrollController
            .position
            .maxScrollExtent,
      );
    });
  }

  /// =========================
  /// scroll bottom
  /// =========================
  Future<void> scrollToBottom() async {
    await Future.delayed(
      const Duration(milliseconds: 50),
    );

    if (!scrollController.hasClients) {
      return;
    }

    scrollController.jumpTo(
      scrollController
          .position
          .maxScrollExtent,
    );

    await Future.delayed(
      const Duration(milliseconds: 100),
    );

    if (!scrollController.hasClients) {
      return;
    }

    scrollController.jumpTo(
      scrollController
          .position
          .maxScrollExtent,
    );
  }
}
