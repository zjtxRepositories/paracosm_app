import 'dart:convert';
import 'dart:typed_data';
import 'package:web3dart/crypto.dart';

class EvmTypedDataSigner {
  /// =========================
  /// 🚀 对外方法（v4）
  /// =========================
  static Future<String> signTypedData({
    required String privateKey,
    required Map<String, dynamic> typedData,
  }) async {
    final pk = hexToBytes(privateKey);

    final data = json.decode(json.encode(typedData));

    final types = Map<String, dynamic>.from(data['types']);
    final primaryType = data['primaryType'];
    final domain = data['domain'];
    final message = data['message'];

    /// 删除 EIP712Domain（规范要求）
    types.remove('EIP712Domain');

    /// domain separator
    final domainSeparator = _hashStruct(
      'EIP712Domain',
      domain,
      data['types'],
    );

    /// message hash
    final messageHash = _hashStruct(
      primaryType,
      message,
      types,
    );

    /// 最终 hash
    final finalHash = Uint8List.fromList([
      0x19,
      0x01,
      ...domainSeparator,
      ...messageHash,
    ]);

    final digest = keccak256(finalHash);

    final sig = sign(Uint8List.fromList(digest), pk);

    final bytes = [
      ..._pad32(_bigIntToBytes(sig.r)),
      ..._pad32(_bigIntToBytes(sig.s)),
      sig.v,
    ];

    return bytesToHex(bytes, include0x: true);
  }

  /// =========================
  /// hashStruct
  /// =========================
  static List<int> _hashStruct(
      String primaryType,
      Map<String, dynamic> data,
      Map<String, dynamic> types,
      ) {
    final encoded = _encodeData(primaryType, data, types);
    return keccak256(Uint8List.fromList(encoded));
  }

  /// =========================
  /// encodeData
  /// =========================
  static List<int> _encodeData(
      String primaryType,
      Map<String, dynamic> data,
      Map<String, dynamic> types,
      ) {
    final fields = types[primaryType] as List;

    List<int> result = [];

    /// typeHash
    result.addAll(
      keccak256(utf8.encode(_encodeType(primaryType, types))),
    );

    for (final field in fields) {
      final name = field['name'];
      final type = field['type'];
      final value = data[name];

      result.addAll(_encodeValue(type, value, types));
    }

    return result;
  }

  /// =========================
  /// encodeType（递归依赖排序）
  /// =========================
  static String _encodeType(
      String primaryType,
      Map<String, dynamic> types,
      ) {
    final deps = _findDependencies(primaryType, types);
    deps.remove(primaryType);
    final sorted = deps.toList()..sort();

    final result = StringBuffer();

    result.write(_typeToString(primaryType, types));

    for (final dep in sorted) {
      result.write(_typeToString(dep, types));
    }

    return result.toString();
  }

  static String _typeToString(
      String type,
      Map<String, dynamic> types,
      ) {
    final fields = types[type] as List;

    return '$type(${fields.map((f) => '${f['type']} ${f['name']}').join(',')})';
  }

  /// =========================
  /// 🚀 encodeValue（完整版）
  /// =========================
  static List<int> _encodeValue(
      String type,
      dynamic value,
      Map<String, dynamic> types,
      ) {
    /// 👉 数组类型（🔥关键）
    if (type.endsWith(']')) {
      final baseType = type.substring(0, type.indexOf('['));

      final List<dynamic> list = value;

      final List<int> encoded = [];

      for (final item in list) {
        encoded.addAll(_encodeValue(baseType, item, types));
      }

      return keccak256(Uint8List.fromList(encoded));
    }

    /// struct
    if (types.containsKey(type)) {
      return _hashStruct(type, value, types);
    }

    /// string
    if (type == 'string') {
      return keccak256(utf8.encode(value));
    }

    /// bytes
    if (type == 'bytes') {
      return keccak256(hexToBytes(value));
    }

    /// address
    if (type == 'address') {
      final clean = value.toString().toLowerCase();
      return _pad32(hexToBytes(clean));
    }

    /// uint / int
    if (type.startsWith('uint') || type.startsWith('int')) {
      final v = BigInt.parse(value.toString());
      return _pad32(_bigIntToBytes(v));
    }

    /// bool
    if (type == 'bool') {
      return _pad32([value ? 1 : 0]);
    }

    throw Exception('Unsupported type: $type');
  }

  /// =========================
  /// utils
  /// =========================
  static List<int> _pad32(List<int> data) {
    return List<int>.filled(32 - data.length, 0) + data;
  }

  static List<int> _bigIntToBytes(BigInt number) {
    final bytes = <int>[];
    var temp = number;

    while (temp > BigInt.zero) {
      bytes.insert(0, (temp & BigInt.from(0xff)).toInt());
      temp >>= 8;
    }

    return bytes.isEmpty ? [0] : bytes;
  }

  static Set<String> _findDependencies(
      String primaryType,
      Map<String, dynamic> types,
      {
        Set<String>? results,
      }
      ) {
    results ??= {};

    if (results.contains(primaryType)) return results;

    results.add(primaryType);

    if (!types.containsKey(primaryType)) return results;

    for (final field in types[primaryType]) {
      final type = field['type'];

      final base = type.replaceAll(RegExp(r'\[.*\]'), '');

      if (types.containsKey(base)) {
        _findDependencies(base, types, results: results);
      }
    }

    return results;
  }
}