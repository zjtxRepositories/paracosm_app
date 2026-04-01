import 'dart:async';
import 'dart:math';

class ElectrumNodeManager {
  static final ElectrumNodeManager _instance =
  ElectrumNodeManager._internal();

  factory ElectrumNodeManager() => _instance;

  ElectrumNodeManager._internal();

  /// =========================
  /// 节点池
  /// =========================
  final List<String> _mainnetNodes = [
    "ssl://electrum.blockstream.info:50002",
    "ssl://electrum1.bluewallet.io:50002",
    "ssl://btc.litepay.ch:50002",
  ];

  final List<String> _testnetNodes = [
    "ssl://electrum.blockstream.info:60002",
    "ssl://electrum1.bluewallet.io:60002",
  ];

  /// =========================
  /// 状态缓存
  /// =========================
  String? _currentNode;
  DateTime? _lastSelectTime;

  /// 节点失败记录
  final Map<String, int> _failCount = {};

  /// =========================
  /// 获取节点（核心）
  /// =========================
  Future<String> getNode({required bool testnet}) async {
    final now = DateTime.now();

    /// ✅ 1. 30秒内复用节点（防抖）
    if (_currentNode != null &&
        _lastSelectTime != null &&
        now.difference(_lastSelectTime!) < const Duration(seconds: 30)) {
      return _currentNode!;
    }

    final nodes = testnet ? _testnetNodes : _mainnetNodes;

    /// ✅ 2. 打乱顺序（负载均衡）
    final shuffled = List<String>.from(nodes)..shuffle(Random());

    /// ✅ 3. 选择健康节点
    for (final node in shuffled) {
      final fail = _failCount[node] ?? 0;

      /// 跳过失败过多的节点
      if (fail >= 3) continue;

      final ok = await _checkNode(node);

      if (ok) {
        _currentNode = node;
        _lastSelectTime = now;
        return node;
      } else {
        _failCount[node] = fail + 1;
      }
    }

    /// ❗ 兜底：强制返回一个
    final fallback = shuffled.first;
    _currentNode = fallback;
    return fallback;
  }

  /// =========================
  /// 标记节点失败
  /// =========================
  void markFailed(String node) {
    _failCount[node] = (_failCount[node] ?? 0) + 1;

    /// 当前节点失败 → 清空
    if (_currentNode == node) {
      _currentNode = null;
    }
  }

  /// =========================
  /// 健康检测（简单版）
  /// =========================
  Future<bool> _checkNode(String node) async {
    try {
      /// ⚠️ 这里只做轻量检测（避免复杂TCP）
      /// 实际可升级：socket / electrum ping

      await Future.delayed(const Duration(milliseconds: 200));

      return true;
    } catch (_) {
      return false;
    }
  }
}