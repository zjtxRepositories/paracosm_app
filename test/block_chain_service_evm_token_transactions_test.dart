import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/trade_model.dart';
import 'package:paracosm/modules/wallet/service/block_chain_service.dart';

void main() {
  group('BlockChainService EVM token transactions', () {
    test('uses index API first and parses tokentx result', () async {
      var fallbackCalls = 0;
      final service = BlockChainService(
        dio: _dioWithResponse({
          'status': '1',
          'message': 'OK',
          'result': [
            {
              'tokenSymbol': 'USDT',
              'tokenDecimal': '18',
              'value': '1500000000000000000',
              'from': _walletAddress,
              'to': _receiverAddress,
              'timeStamp': '1710000000',
              'contractAddress': _tokenAddress,
              'tokenName': 'Tether USD',
            },
          ],
        }),
        erc20RpcFallback:
            ({
              required chain,
              required walletAddress,
              required contractAddress,
              int limit = 20,
              int scanBlockCount = 100000,
              int chunkSize = 5000,
            }) async {
              fallbackCalls++;
              return [];
            },
      );

      final trades = await service.getTokenTransactions(
        _bscChain,
        _walletAddress,
        contractAddress: _tokenAddress,
      );

      expect(fallbackCalls, 0);
      expect(trades, hasLength(1));
      expect(trades.first.symbol, 'USDT');
      expect(trades.first.amount, 1.5);
      expect(trades.first.direction, TradeDirection.sell);
      expect(trades.first.time, 1710000000);
      expect(trades.first.contractAddress, _tokenAddress);
      expect(trades.first.tokenName, 'Tether USD');
    });

    test(
      'returns empty list for No transactions found without RPC fallback',
      () async {
        var fallbackCalls = 0;
        final service = BlockChainService(
          dio: _dioWithResponse({
            'status': '0',
            'message': 'No transactions found',
            'result': [],
          }),
          erc20RpcFallback:
              ({
                required chain,
                required walletAddress,
                required contractAddress,
                int limit = 20,
                int scanBlockCount = 100000,
                int chunkSize = 5000,
              }) async {
                fallbackCalls++;
                return [
                  TradeModel(
                    symbol: 'USDT',
                    price: 0,
                    amount: 1,
                    buyTurnover: 0,
                    direction: TradeDirection.buy,
                    time: 0,
                    createdAt: 0,
                  ),
                ];
              },
        );

        final trades = await service.getTokenTransactions(
          _bscChain,
          _walletAddress,
          contractAddress: _tokenAddress,
        );

        expect(trades, isEmpty);
        expect(fallbackCalls, 0);
      },
    );

    test('falls back to small-range RPC scan when index API fails', () async {
      var fallbackCalls = 0;
      var fallbackScanBlockCount = 0;
      var fallbackChunkSize = 0;
      final fallbackTrade = TradeModel(
        symbol: 'USDT',
        price: 0,
        amount: 2,
        buyTurnover: 0,
        direction: TradeDirection.buy,
        time: 1710000001,
        createdAt: 0,
      );
      final service = BlockChainService(
        dio: _dioWithResponse({
          'status': '0',
          'message': 'NOTOK',
          'result': 'Max rate limit reached',
        }),
        erc20RpcFallback:
            ({
              required chain,
              required walletAddress,
              required contractAddress,
              int limit = 20,
              int scanBlockCount = 100000,
              int chunkSize = 5000,
            }) async {
              fallbackCalls++;
              fallbackScanBlockCount = scanBlockCount;
              fallbackChunkSize = chunkSize;
              expect(chain.chainId, 56);
              expect(walletAddress, _walletAddress);
              expect(contractAddress, _tokenAddress);
              return [fallbackTrade];
            },
      );

      final trades = await service.getTokenTransactions(
        _bscChain,
        _walletAddress,
        contractAddress: _tokenAddress,
      );

      expect(fallbackCalls, 1);
      expect(fallbackScanBlockCount, 5000);
      expect(fallbackChunkSize, 500);
      expect(trades, [same(fallbackTrade)]);
    });
  });
}

const _walletAddress = '0x1111111111111111111111111111111111111111';
const _receiverAddress = '0x2222222222222222222222222222222222222222';
const _tokenAddress = '0x3333333333333333333333333333333333333333';

final _bscChain = ChainAccount(
  name: 'BNB Chain',
  address: _walletAddress,
  chainId: 56,
  logo: '',
  symbol: 'BNB',
  chainType: ChainType.evm,
  nodes: const ['https://bsc-dataseed1.binance.org'],
  txApiUrl: 'https://api.bscscan.com/api',
);

Dio _dioWithResponse(Map<String, dynamic> responseData) {
  final dio = Dio();
  dio.httpClientAdapter = _StaticJsonAdapter(responseData);
  return dio;
}

class _StaticJsonAdapter implements HttpClientAdapter {
  _StaticJsonAdapter(this.responseData);

  final Map<String, dynamic> responseData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(responseData),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
