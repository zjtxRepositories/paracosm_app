import 'dart:async';
import 'dart:io';
import 'dart:math';

class ElectrumNodeManager {
  static final ElectrumNodeManager _instance = ElectrumNodeManager._internal();

  factory ElectrumNodeManager() => _instance;

  ElectrumNodeManager._internal();

  /// =========================
  /// 节点池
  /// =========================
  final List<String> _mainnetNodes = [
    // Blockstream
    "ssl://electrum.blockstream.info:50002",

    // BlueWallet
    "ssl://electrum1.bluewallet.io:50002",
    "ssl://electrum2.bluewallet.io:50002",

    // EMZY
    "ssl://electrum.emzy.de:50002",

    // Litecoin / multi service
    "ssl://btc.litepay.ch:50002",

    // Coinext
    "ssl://electrum.coinext.com.br:50002",

    // Bitaroo
    "ssl://electrum.bitaroo.net:50002",

    // 1209k
    "ssl://electrum.1209k.com:50002",

    // Hsmiths
    "ssl://ecdsa.net:50002",

    // Arctic
    "ssl://fortress.qtornado.com:443",

    // Bitcoin.lu
    "ssl://node.xbt.eu:50002",

    // CryptoClub
    "ssl://electrum.crypto.club:50002",

    // 自建推荐备用
    // "ssl://your-node.com:50002",
  ];

  final List<String> _testnetNodes = [
    "ssl://electrum.blockstream.info:60002",
    "ssl://electrum1.bluewallet.io:60002",
    "ssl://testnet.aranguren.org:51002",
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

    /// ❗ 兜底：强制返回一个，后续 Blockchain.create 仍会做真实连接校验
    final fallback = shuffled.first;
    _currentNode = fallback;
    _lastSelectTime = now;
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
    Socket? socket;
    try {
      final uri = _parseNode(node);
      if (uri.host.isEmpty || !uri.hasPort) return false;

      socket = await Socket.connect(
        uri.host,
        uri.port,
        timeout: const Duration(milliseconds: 1500),
      );
      return socket.remoteAddress.address.isNotEmpty;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy();
    }
  }

  Uri _parseNode(String node) {
    final normalized = node.contains('://')
        ? node.trim()
        : 'ssl://${node.trim()}';
    return Uri.parse(normalized);
  }
}
