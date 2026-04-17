import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';

import '../../../../widgets/modals/wallet_protocol_modal.dart';

class BitcoinSearchTokenInfo {
  static const uniSatApiKey = 'b902fe0988b7e8884acd1aea77916ca359c70231d0d0b8367035389119338ba5';

  static Future<List<TokenModel>> searchBTCAsset(ProtocolType protocolType,String keyword) async {
    List<TokenModel> tokens = [];
    try {
      switch (protocolType) {
        case ProtocolType.runes:
          final token = await searchRunesBySymbol(keyword);
          if (token != null){
            tokens.add(token);
          }
          break;
        case ProtocolType.src20:
          final token = await searchSRC20ByTicker(keyword);
          if (token != null){
            tokens.add(token);
          }
          break;
        case ProtocolType.brc20:
          final token  = await searchBRC20ByTick(keyword);
          if (token != null){
            tokens.add(token);
          }
          break;
      }
      return tokens;
    } catch (err) {
      print('err------$err');
      return tokens;
    }

  }
  static Future<TokenModel?> searchSRC20ByTicker(String keyword) async {
    final url = Uri.parse(
      'https://open-api.unisat.io/v1/indexer/token/search?protocol=src-20&keyword=$keyword',
    );
    final dio = Dio();
    final response = await dio.get(
      url.toString(),
      options: Options(
        headers: {
          'Authorization': uniSatApiKey,
          'Accept': 'application/json',
        },
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch runes list');
    }
    final Map<String, dynamic> body = json.decode(response.data);
    final data = body['data'];
    if (data == null) return null;

    return TokenModel(
      name: data['name'] ?? keyword.toUpperCase(),
      symbol: data['ticker'],
      protocol: 'SRC-20',
      balance: BigInt.zero,
      logo: getSRC20Logo(data['ticker']),
      decimals: 0,
      address: '', // SRC-20 无地址
      coinId: '',
      chainId: 0,
    );
  }



  static  String getSRC20Logo(String ticker) {
    return 'https://stamp-icons.pages.dev/$ticker.png'; // 社区常用图标服务
  }

  static Future<TokenModel?> searchBRC20ByTick(String symbol) async {
    final ticker = symbol.toLowerCase();
    final url = Uri.parse('https://open-api.unisat.io/v1/indexer/brc20/$ticker/info');
    final dio = Dio();
    final response = await dio.get(
      url.toString(),
      options: Options(
        headers: {
          'Authorization': uniSatApiKey,
          'Accept': 'application/json',
        },
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch runes list');
    }
    final data = json.decode(response.data)['data'];
    print('search---${data}');
    return TokenModel(
      symbol: data['ticker'],
      address: '',
      name: data['name'] ?? ticker.toUpperCase(),
      logo: 'https://brc20api.github.io/tokens/${data['ticker']}/logo.png',
      decimals: 8,
      protocol: 'BRC-20',
      balance: BigInt.zero,
      coinId: '',
      chainId: 0,
    );
  }
  static Future<TokenModel?> searchRunesBySymbol(String symbol) async {
    symbol = symbol.toUpperCase();
    final tokens = await fetchRunesList(offset: 0, limit: 100);
    try {
      return tokens.firstWhere((t) => t.symbol.toLowerCase() == symbol.toLowerCase());
    } catch (e) {
      return null;
    }
  }
  static const _baseUrl = 'https://open-api.unisat.io/v1';

  /// 查询 Runes 代币列表
  static Future<List<TokenModel>> fetchRunesList({int offset = 0, int limit = 1000}) async {
    final dio = Dio();
    final url = Uri.parse(
      '$_baseUrl/indexer/runes/info-list?offset=$offset&limit=$limit',
    );
    final response = await dio.get(
      url.toString(),
      options: Options(
        headers: {
          'Authorization': uniSatApiKey,
          'Accept': 'application/json',
        },
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch runes list');
    }
    final Map<String, dynamic> body = jsonDecode(response.data);
    final data = body['data'];
    final List details = data['detail'];
    return details.map((item) {
      final symbol = item['symbol'] as String;
      print('search---${symbol}--${details.length}');
      return TokenModel(
        symbol: symbol,
        name: item['name'] ?? symbol,
        logo: 'https://runes-icons.pages.dev/$symbol.png',
        decimals: item['decimals'] ?? 8,
        protocol: 'Runes',
        address: '',
        balance: BigInt.zero, coinId: '',
        chainId: 0,
      );
    }).toList();
  }

}