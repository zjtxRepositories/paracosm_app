import 'dart:convert';

enum NftTokenType { erc721, erc1155, unknown }

NftTokenType nftTokenTypeFromString(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'erc721':
      return NftTokenType.erc721;
    case 'erc1155':
      return NftTokenType.erc1155;
    default:
      return NftTokenType.unknown;
  }
}

String nftTokenTypeToString(NftTokenType value) {
  switch (value) {
    case NftTokenType.erc721:
      return 'ERC721';
    case NftTokenType.erc1155:
      return 'ERC1155';
    case NftTokenType.unknown:
      return 'UNKNOWN';
  }
}

class NftAssetModel {
  final String id;
  final String walletId;
  final int chainId;
  final String ownerAddress;
  final String contractAddress;
  final String tokenId;
  final NftTokenType tokenType;
  final String name;
  final String description;
  final String imageUrl;
  final String animationUrl;
  final String metadataUri;
  final String collectionName;
  final String collectionImageUrl;
  final BigInt balance;
  final bool isSpam;
  final bool isHidden;
  final DateTime lastSyncedAt;
  final String rawJson;

  const NftAssetModel({
    required this.id,
    required this.walletId,
    required this.chainId,
    required this.ownerAddress,
    required this.contractAddress,
    required this.tokenId,
    required this.tokenType,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.animationUrl,
    required this.metadataUri,
    required this.collectionName,
    required this.collectionImageUrl,
    required this.balance,
    required this.isSpam,
    required this.isHidden,
    required this.lastSyncedAt,
    required this.rawJson,
  });

  factory NftAssetModel.fromAlchemyJson({
    required Map<String, dynamic> json,
    required String walletId,
    required int chainId,
    required String ownerAddress,
    DateTime? syncedAt,
  }) {
    final contract = _mapOf(json['contract']);
    final collection = _mapOf(json['collection']);
    final metadata = _extractMetadata(json);
    final tokenId = _tokenId(json);
    final contractAddress = _stringOf(
      contract['address'] ?? json['contractAddress'],
    );
    final tokenType = nftTokenTypeFromString(
      _stringOf(
        json['tokenType'] ?? contract['tokenType'] ?? contract['token_type'],
      ),
    );
    final name = _firstNonEmpty([
      _stringOf(json['name']),
      _stringOf(metadata['name']),
      _stringOf(collection['name']),
      _stringOf(contract['name']),
      tokenId.isNotEmpty ? 'NFT #$tokenId' : 'NFT',
    ]);
    final collectionName = _firstNonEmpty([
      _stringOf(collection['name']),
      _stringOf(contract['name']),
    ]);
    final imageUrl = _normalizeUrl(
      _firstNonEmpty([
        _extractImageUrl(metadata['image']),
        _extractImageUrl(metadata['imageUrl']),
        _extractImageUrl(metadata['thumbnail']),
        _extractImageUrl(metadata['media']),
        _extractImageUrl(json['image']),
        _extractImageUrl(json['imageUrl']),
        _extractImageUrl(json['thumbnail']),
        _extractImageUrl(json['media']),
        _extractImageUrl(collection['image']),
        _extractImageUrl(collection['imageUrl']),
        _extractImageUrl(contract['openSeaMetadata']),
        _extractImageUrl(contract['image']),
      ]),
    );
    final animationUrl = _normalizeUrl(
      _firstNonEmpty([
        _stringOf(metadata['animation_url']),
        _stringOf(metadata['animationUrl']),
        _stringOf(json['animationUrl']),
      ]),
    );
    final metadataUri = _firstNonEmpty([
      _stringOf(_mapOf(json['tokenUri'])['raw']),
      _stringOf(_mapOf(json['tokenUri'])['gateway']),
      _stringOf(json['metadataUri']),
      _stringOf(json['tokenUri']),
    ]);
    final description = _firstNonEmpty([
      _stringOf(metadata['description']),
      _stringOf(json['description']),
    ]);
    final collectionImageUrl = _normalizeUrl(
      _firstNonEmpty([
        _extractImageUrl(collection['image']),
        _extractImageUrl(collection['imageUrl']),
        _extractImageUrl(contract['openSeaMetadata']),
        _extractImageUrl(contract['image']),
      ]),
    );
    final balance = _parseBigInt(json['balance']) ?? BigInt.one;
    final synced = syncedAt ?? DateTime.now();
    final rawJson = jsonEncode(json);

    return NftAssetModel(
      id: buildId(walletId, chainId, contractAddress, tokenId),
      walletId: walletId,
      chainId: chainId,
      ownerAddress: ownerAddress,
      contractAddress: contractAddress,
      tokenId: tokenId,
      tokenType: tokenType,
      name: name,
      description: description,
      imageUrl: imageUrl,
      animationUrl: animationUrl,
      metadataUri: metadataUri,
      collectionName: collectionName,
      collectionImageUrl: collectionImageUrl,
      balance: balance,
      isSpam: _parseBool(
        json['isSpam'] ??
            json['spam'] ??
            contract['isSpam'] ??
            contract['spam'],
      ),
      isHidden: _parseBool(json['isHidden'] ?? json['hidden']),
      lastSyncedAt: synced,
      rawJson: rawJson,
    );
  }

  factory NftAssetModel.fromJson(Map<String, dynamic> json) {
    return NftAssetModel(
      id: _stringOf(json['id']),
      walletId: _stringOf(json['walletId']),
      chainId: json['chainId'] is int
          ? json['chainId'] as int
          : int.tryParse('${json['chainId']}') ?? 0,
      ownerAddress: _stringOf(json['ownerAddress']),
      contractAddress: _stringOf(json['contractAddress']),
      tokenId: _stringOf(json['tokenId']),
      tokenType: nftTokenTypeFromString(_stringOf(json['tokenType'])),
      name: _stringOf(json['name']),
      description: _stringOf(json['description']),
      imageUrl: _stringOf(json['imageUrl']),
      animationUrl: _stringOf(json['animationUrl']),
      metadataUri: _stringOf(json['metadataUri']),
      collectionName: _stringOf(json['collectionName']),
      collectionImageUrl: _stringOf(json['collectionImageUrl']),
      balance: _parseBigInt(json['balance']) ?? BigInt.zero,
      isSpam: _parseBool(json['isSpam']),
      isHidden: _parseBool(json['isHidden']),
      lastSyncedAt:
          DateTime.tryParse(_stringOf(json['lastSyncedAt'])) ?? DateTime.now(),
      rawJson: _stringOf(json['rawJson']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'chainId': chainId,
      'ownerAddress': ownerAddress,
      'contractAddress': contractAddress,
      'tokenId': tokenId,
      'tokenType': nftTokenTypeToString(tokenType),
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'animationUrl': animationUrl,
      'metadataUri': metadataUri,
      'collectionName': collectionName,
      'collectionImageUrl': collectionImageUrl,
      'balance': balance.toString(),
      'isSpam': isSpam,
      'isHidden': isHidden,
      'lastSyncedAt': lastSyncedAt.toIso8601String(),
      'rawJson': rawJson,
    };
  }

  NftAssetModel copyWith({
    String? name,
    String? description,
    String? imageUrl,
    String? animationUrl,
    String? metadataUri,
    String? collectionName,
    String? collectionImageUrl,
    DateTime? lastSyncedAt,
    String? rawJson,
  }) {
    return NftAssetModel(
      id: id,
      walletId: walletId,
      chainId: chainId,
      ownerAddress: ownerAddress,
      contractAddress: contractAddress,
      tokenId: tokenId,
      tokenType: tokenType,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      animationUrl: animationUrl ?? this.animationUrl,
      metadataUri: metadataUri ?? this.metadataUri,
      collectionName: collectionName ?? this.collectionName,
      collectionImageUrl: collectionImageUrl ?? this.collectionImageUrl,
      balance: balance,
      isSpam: isSpam,
      isHidden: isHidden,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  NftAssetModel withMetadataFallback(Map<String, dynamic> metadata) {
    final image = _normalizeUrl(
      _firstNonEmpty([
        _extractImageUrl(metadata['image']),
        _extractImageUrl(metadata['image_url']),
        _extractImageUrl(metadata['imageUrl']),
        _extractImageUrl(metadata['thumbnail']),
        _extractImageUrl(metadata['media']),
      ]),
    );
    final animation = _normalizeUrl(
      _firstNonEmpty([
        _stringOf(metadata['animation_url']),
        _stringOf(metadata['animationUrl']),
      ]),
    );
    final metadataName = _stringOf(metadata['name']);
    return copyWith(
      name: _canUseMetadataName(metadataName) ? metadataName : null,
      description: description.isEmpty
          ? _stringOf(metadata['description'])
          : null,
      imageUrl: imageUrl.isEmpty ? image : null,
      animationUrl: animationUrl.isEmpty ? animation : null,
    );
  }

  bool _canUseMetadataName(String metadataName) {
    if (metadataName.isEmpty) return false;
    return name.isEmpty || name == 'NFT' || name == 'NFT #$tokenId';
  }

  String get displayLabel => name.isNotEmpty ? name : 'NFT #$tokenId';

  String get displayImageUrl =>
      imageUrl.isNotEmpty ? imageUrl : collectionImageUrl;

  String get displaySubLabel {
    if (collectionName.isNotEmpty) {
      return '$collectionName - #$tokenId';
    }
    return '#$tokenId';
  }

  static String buildId(
    String walletId,
    int chainId,
    String contractAddress,
    String tokenId,
  ) {
    return '$walletId:$chainId:${contractAddress.toLowerCase()}:$tokenId';
  }

  static Map<String, dynamic> _extractMetadata(Map<String, dynamic> json) {
    final metadata = _mapOf(json['metadata']);
    if (metadata.isNotEmpty) return metadata;
    final raw = json['rawMetadata'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  static String _tokenId(Map<String, dynamic> json) {
    final id = _mapOf(json['id']);
    final value = id['tokenId'] ?? json['tokenId'] ?? json['token_id'];
    return _stringOf(value);
  }

  static Map<String, dynamic> _mapOf(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final str = _stringOf(value);
      if (str.isNotEmpty) return str;
    }
    return '';
  }

  static String _stringOf(Object? value) {
    if (value == null) return '';
    final text = value.toString().trim();
    return text == 'null' ? '' : text;
  }

  static bool _parseBool(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    final text = value.toString().toLowerCase();
    return text == 'true' || text == '1';
  }

  static BigInt? _parseBigInt(Object? value) {
    if (value == null) return null;
    if (value is BigInt) return value;
    if (value is int) return BigInt.from(value);
    return BigInt.tryParse(value.toString());
  }

  static String _normalizeUrl(String value) {
    if (value.isEmpty) return '';
    if (value.startsWith('ipfs://ipfs/')) {
      return 'https://ipfs.io/ipfs/${value.substring(12)}';
    }
    if (value.startsWith('ipfs://')) {
      return 'https://ipfs.io/ipfs/${value.substring(7)}';
    }
    return value;
  }

  static String _extractImageUrl(Object? value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is List) {
      for (final item in value) {
        final candidate = _extractImageUrl(item);
        if (candidate.isNotEmpty) return candidate;
      }
      return '';
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      const directKeys = [
        'cachedUrl',
        'gateway',
        'thumbnailUrl',
        'thumbnail',
        'pngUrl',
        'url',
        'raw',
        'imageUrl',
        'contentUrl',
        'optimizedUrl',
        'originalUrl',
        'src',
      ];
      for (final key in directKeys) {
        final candidate = _stringOf(map[key]);
        if (candidate.isNotEmpty) return candidate;
      }
      for (final key in ['image', 'media', 'preview', 'poster']) {
        final candidate = _extractImageUrl(map[key]);
        if (candidate.isNotEmpty) return candidate;
      }
    }
    return '';
  }
}
