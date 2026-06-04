import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:paracosm/modules/wallet/chains/tron/tron_service.dart';

import 'tron_tx_detail.dart';

class TronChainService {
  static const String _defaultNode = 'https://api.trongrid.io';
  final Dio _dio = Dio();

  Future<BigInt> getBalance(
    String address, {
    String contractAddress = '',
    String node = _defaultNode,
  }) async {
    final baseUrl = node.replaceFirst(RegExp(r'/$'), '');
    final response = await _dio.get('$baseUrl/v1/accounts/$address');
    final accounts = response.data?['data'];
    if (accounts is! List || accounts.isEmpty) return BigInt.zero;

    final account = accounts.first;
    if (account is! Map) return BigInt.zero;
    if (contractAddress.isEmpty) {
      return BigInt.tryParse(account['balance']?.toString() ?? '') ??
          BigInt.zero;
    }

    final trc20 = account['trc20'];
    if (trc20 is! List) return BigInt.zero;
    for (final balances in trc20) {
      if (balances is Map && balances.containsKey(contractAddress)) {
        return BigInt.tryParse(balances[contractAddress].toString()) ??
            BigInt.zero;
      }
    }
    return BigInt.zero;
  }

  Future<String> send({
    required String fromAddress,
    required String toAddress,
    required BigInt amount,
    required String privateKey,
    String contractAddress = '',
    String node = _defaultNode,
  }) async {
    if (amount <= BigInt.zero) throw Exception('转账金额必须大于 0');
    if (!TronService.isValidAddress(fromAddress) ||
        !TronService.isValidAddress(toAddress)) {
      throw Exception('无效的波场地址');
    }

    final baseUrl = _normalizeNode(node);
    final transaction = contractAddress.isEmpty
        ? await _createTrxTransaction(
            baseUrl: baseUrl,
            fromAddress: fromAddress,
            toAddress: toAddress,
            amount: amount,
          )
        : await _createTrc20Transaction(
            baseUrl: baseUrl,
            fromAddress: fromAddress,
            toAddress: toAddress,
            contractAddress: contractAddress,
            amount: amount,
          );

    _validateTransactionId(transaction);
    final txId = transaction['txID']?.toString() ?? '';
    if (txId.isEmpty) throw Exception('波场节点未返回交易 ID');
    transaction['signature'] = [
      TronService.signTransactionId(txId, privateKey),
    ];

    final response = await _dio.post(
      '$baseUrl/wallet/broadcasttransaction',
      data: transaction,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    final data = response.data;
    if (data is! Map || data['result'] != true) {
      throw Exception(_decodeNodeMessage(data));
    }
    return txId;
  }

  Future<TronTxDetail?> getTransactionDetail(
    String txId, {
    String contractAddress = '',
    String node = _defaultNode,
  }) async {
    final baseUrl = _normalizeNode(node);
    final responses = await Future.wait([
      _dio.post(
        '$baseUrl/wallet/gettransactionbyid',
        data: {'value': txId, 'visible': true},
      ),
      _dio.post(
        '$baseUrl/wallet/gettransactioninfobyid',
        data: {'value': txId},
      ),
    ]);
    final tx = responses[0].data;
    final info = responses[1].data;
    if (tx is! Map || tx.isEmpty) return null;

    final contract = _firstContract(tx);
    final value = contract?['parameter']?['value'];
    if (value is! Map) return null;

    final isTrc20 = contractAddress.isNotEmpty;
    final from = _normalizeAddress(value['owner_address']);
    var to = _normalizeAddress(value['to_address']);
    var amount =
        BigInt.tryParse(value['amount']?.toString() ?? '') ?? BigInt.zero;
    if (isTrc20) {
      final decoded = _decodeTrc20Transfer(value['data']?.toString() ?? '');
      to = decoded?.to ?? '';
      amount = decoded?.amount ?? BigInt.zero;
    }

    final receipt = info is Map ? info['receipt'] : null;
    final result = receipt is Map ? receipt['result']?.toString() : null;
    final blockTime = int.tryParse(
      (info is Map ? info['blockTimeStamp'] : null)?.toString() ?? '',
    );
    return TronTxDetail(
      txid: txId,
      from: from,
      to: to,
      value: amount,
      fee: BigInt.tryParse(
        (info is Map ? info['fee'] : null)?.toString() ?? '',
      ),
      success: result == null ? null : result == 'SUCCESS',
      time: blockTime == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(blockTime),
    );
  }

  Future<List<Map<String, dynamic>>> getTransactions(
    String address, {
    String contractAddress = '',
    String node = _defaultNode,
    int limit = 20,
  }) async {
    final baseUrl = _normalizeNode(node);
    final path = contractAddress.isEmpty
        ? '/v1/accounts/$address/transactions'
        : '/v1/accounts/$address/transactions/trc20';
    final response = await _dio.get(
      '$baseUrl$path',
      queryParameters: {
        'only_confirmed': true,
        'limit': limit,
        'order_by': 'block_timestamp,desc',
        if (contractAddress.isNotEmpty) 'contract_address': contractAddress,
      },
    );
    final data = response.data?['data'];
    if (data is! List) return [];
    return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  Future<Map<String, dynamic>> _createTrxTransaction({
    required String baseUrl,
    required String fromAddress,
    required String toAddress,
    required BigInt amount,
  }) async {
    final response = await _dio.post(
      '$baseUrl/wallet/createtransaction',
      data: {
        'owner_address': fromAddress,
        'to_address': toAddress,
        'amount': amount.toString(),
        'visible': true,
      },
    );
    return _requireTransaction(response.data);
  }

  Future<Map<String, dynamic>> _createTrc20Transaction({
    required String baseUrl,
    required String fromAddress,
    required String toAddress,
    required String contractAddress,
    required BigInt amount,
  }) async {
    final parameter =
        '${TronService.addressToHex(toAddress).padLeft(64, '0')}'
        '${amount.toRadixString(16).padLeft(64, '0')}';
    final response = await _dio.post(
      '$baseUrl/wallet/triggersmartcontract',
      data: {
        'owner_address': fromAddress,
        'contract_address': contractAddress,
        'function_selector': 'transfer(address,uint256)',
        'parameter': parameter,
        'fee_limit': 100000000,
        'call_value': 0,
        'visible': true,
      },
    );
    final data = response.data;
    if (data is! Map || data['result']?['result'] != true) {
      throw Exception(_decodeNodeMessage(data));
    }
    return _requireTransaction(data['transaction']);
  }

  Map<String, dynamic> _requireTransaction(dynamic data) {
    if (data is! Map || data['txID'] == null || data['raw_data_hex'] == null) {
      throw Exception(_decodeNodeMessage(data));
    }
    return Map<String, dynamic>.from(data);
  }

  Map? _firstContract(Map tx) {
    final contracts = tx['raw_data']?['contract'];
    if (contracts is! List || contracts.isEmpty || contracts.first is! Map) {
      return null;
    }
    return contracts.first as Map;
  }

  _Trc20Transfer? _decodeTrc20Transfer(String data) {
    final normalized = data.replaceFirst('0x', '');
    if (normalized.length < 136 || !normalized.startsWith('a9059cbb')) {
      return null;
    }
    final toHex = normalized.substring(30, 72);
    final amountHex = normalized.substring(72, 136);
    return _Trc20Transfer(
      to: TronService.hexToAddress(toHex),
      amount: BigInt.parse(amountHex, radix: 16),
    );
  }

  String _normalizeNode(String node) => node.replaceFirst(RegExp(r'/$'), '');

  String _normalizeAddress(dynamic address) {
    final value = address?.toString() ?? '';
    if (RegExp(r'^41[0-9a-fA-F]{40}$').hasMatch(value)) {
      return TronService.hexToAddress(value);
    }
    return value;
  }

  void _validateTransactionId(Map<String, dynamic> transaction) {
    final rawDataHex = transaction['raw_data_hex']?.toString() ?? '';
    final txId = transaction['txID']?.toString().toLowerCase() ?? '';
    final computedTxId = sha256.convert(_hexToBytes(rawDataHex)).toString();
    if (rawDataHex.isEmpty || txId != computedTxId) {
      throw Exception('波场节点返回的交易数据校验失败');
    }
  }

  String _decodeNodeMessage(dynamic data) {
    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        try {
          return utf8.decode(_hexToBytes(message));
        } catch (_) {
          return message;
        }
      }
      final result = data['result'];
      if (result is Map && result['message'] != null) {
        return result['message'].toString();
      }
    }
    return '波场交易请求失败';
  }

  List<int> _hexToBytes(String hex) {
    final normalized = hex.replaceFirst('0x', '');
    return [
      for (var i = 0; i < normalized.length; i += 2)
        int.parse(normalized.substring(i, i + 2), radix: 16),
    ];
  }
}

class _Trc20Transfer {
  final String to;
  final BigInt amount;

  _Trc20Transfer({required this.to, required this.amount});
}
