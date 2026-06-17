import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AlchemyNftApi {
  static const String apiKey = 'MSMzR2SnLvXcNHhHkuade';
  static const bool enableLog = true;

  static final Map<int, String> _networkSlugs = {
    1: 'eth-mainnet',
    56: 'bnb-mainnet',
    137: 'polygon-mainnet',
    10: 'opt-mainnet',
    42161: 'arb-mainnet',
    8453: 'base-mainnet',
    43114: 'avax-mainnet',
    250: 'fantom-mainnet',
    324: 'zksync-mainnet',
    59144: 'linea-mainnet',
    534352: 'scroll-mainnet',
    5000: 'mantle-mainnet',
    81457: 'blast-mainnet',
  };

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  static String? resolveNetworkSlug(int chainId) {
    return _networkSlugs[chainId];
  }

  static bool supportsChain(int chainId) => _networkSlugs.containsKey(chainId);

  static Future<AlchemyNftPage> getNFTsForOwner({
    required int chainId,
    required String ownerAddress,
    String? pageKey,
    int pageSize = 100,
  }) async {
    final network = resolveNetworkSlug(chainId);
    if (network == null) {
      throw UnsupportedError('Unsupported Alchemy NFT chain: $chainId');
    }
    if (apiKey.isEmpty || apiKey == 'REPLACE_WITH_ALCHEMY_NFT_API_KEY') {
      throw StateError('Alchemy NFT API key is not configured');
    }

    _log(
      'getNFTsForOwner request '
      'chainId=$chainId network=$network '
      'owner=${_maskAddress(ownerAddress)} pageSize=$pageSize '
      'pageKey=${pageKey == null || pageKey.isEmpty ? 'none' : pageKey}',
    );

    try {
      final res = await _dio.get(
        'https://$network.g.alchemy.com/nft/v3/$apiKey/getNFTsForOwner',
        queryParameters: <String, dynamic>{
          'owner': ownerAddress,
          'withMetadata': true,
          'pageSize': pageSize,
          if (pageKey != null && pageKey.isNotEmpty) 'pageKey': pageKey,
        },
      );
      final data = _unwrapData(res.data);
      final page = AlchemyNftPage.fromJson(data);
      _log(
        'getNFTsForOwner response '
        'status=${res.statusCode} chainId=$chainId network=$network '
        'nftCount=${page.nfts.length} '
        'nextPageKey=${page.pageKey.isEmpty ? 'none' : page.pageKey}',
      );
      _log('getNFTsForOwner response raw=${_encodeForLog(res.data)}');
      return page;
    } on DioException catch (error) {
      _log(
        'getNFTsForOwner failed '
        'chainId=$chainId network=$network '
        'status=${error.response?.statusCode} type=${error.type} '
        'message=${error.message} '
        'response=${_encodeForLog(error.response?.data)}',
      );
      rethrow;
    } catch (error) {
      _log(
        'getNFTsForOwner failed '
        'chainId=$chainId network=$network error=$error',
      );
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getNftMetadata(
    String metadataUri,
  ) async {
    final url = _normalizeIpfsUrl(metadataUri);
    if (url.isEmpty || !url.startsWith('http')) {
      return null;
    }

    _log('getNftMetadata request url=$url');

    try {
      final res = await _dio.get(url);
      final data = _decodeMap(res.data);
      _log(
        'getNftMetadata response status=${res.statusCode} '
        'hasMetadata=${data != null}',
      );
      return data;
    } on DioException catch (error) {
      _log(
        'getNftMetadata failed status=${error.response?.statusCode} '
        'type=${error.type} message=${error.message}',
      );
      return null;
    } catch (error) {
      _log('getNftMetadata failed error=$error');
      return null;
    }
  }

  static Map<String, dynamic> _unwrapData(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return data;
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    throw StateError('Unexpected Alchemy NFT response');
  }

  static Map<String, dynamic>? _decodeMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static void _log(String message) {
    if (enableLog) {
      debugPrint('[AlchemyNftApi] $message');
    }
  }

  static String _maskAddress(String address) {
    if (address.length <= 12) {
      return address;
    }
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  static String _encodeForLog(dynamic data) {
    if (data == null) {
      return 'null';
    }
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }

  static String _normalizeIpfsUrl(String value) {
    final url = value.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('ipfs://ipfs/')) {
      return 'https://ipfs.io/ipfs/${url.substring(12)}';
    }
    if (url.startsWith('ipfs://')) {
      return 'https://ipfs.io/ipfs/${url.substring(7)}';
    }
    return url;
  }
}

class AlchemyNftPage {
  final List<Map<String, dynamic>> nfts;
  final String pageKey;

  const AlchemyNftPage({required this.nfts, required this.pageKey});

  factory AlchemyNftPage.fromJson(Map<String, dynamic> json) {
    final list = json['ownedNfts'] ?? json['nfts'] ?? json['items'] ?? [];
    final nfts = <Map<String, dynamic>>[];
    if (list is List) {
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          nfts.add(item);
        } else if (item is Map) {
          nfts.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return AlchemyNftPage(
      nfts: nfts,
      pageKey: json['pageKey']?.toString() ?? '',
    );
  }
}
