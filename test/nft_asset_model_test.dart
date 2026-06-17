import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/network/api/alchemy_nft_api.dart';
import 'package:paracosm/modules/wallet/model/nft_asset_model.dart';

void main() {
  group('NftAssetModel', () {
    test('parses Alchemy ERC721 metadata and builds stable id', () {
      final syncedAt = DateTime.utc(2026, 1, 1);
      final asset = NftAssetModel.fromAlchemyJson(
        walletId: 'wallet-1',
        chainId: 1,
        ownerAddress: '0xOwner',
        syncedAt: syncedAt,
        json: {
          'contract': {
            'address': '0xABCDEF',
            'tokenType': 'ERC721',
            'name': 'Collection',
          },
          'tokenId': '123',
          'name': 'Dragon',
          'description': 'Rare',
          'image': {'cachedUrl': 'ipfs://image-hash'},
          'tokenUri': {'raw': 'ipfs://metadata-hash'},
          'collection': {'name': 'Dragons'},
          'isSpam': false,
        },
      );

      expect(asset.id, 'wallet-1:1:0xabcdef:123');
      expect(asset.tokenType, NftTokenType.erc721);
      expect(asset.name, 'Dragon');
      expect(asset.collectionName, 'Dragons');
      expect(asset.imageUrl, 'https://ipfs.io/ipfs/image-hash');
      expect(asset.metadataUri, 'ipfs://metadata-hash');
      expect(asset.balance, BigInt.one);
      expect(asset.lastSyncedAt, syncedAt);
    });

    test('falls back to UNKNOWN token type and metadata name', () {
      final asset = NftAssetModel.fromAlchemyJson(
        walletId: 'wallet-1',
        chainId: 56,
        ownerAddress: '0xOwner',
        json: {
          'contract': {'address': '0xNFT', 'tokenType': 'WEIRD'},
          'id': {'tokenId': '7'},
          'rawMetadata': {
            'name': 'Metadata Name',
            'description': 'From metadata',
            'image': 'https://example.com/nft.png',
          },
          'balance': '3',
          'spam': '1',
        },
      );

      expect(asset.tokenType, NftTokenType.unknown);
      expect(asset.name, 'Metadata Name');
      expect(asset.description, 'From metadata');
      expect(asset.imageUrl, 'https://example.com/nft.png');
      expect(asset.balance, BigInt.from(3));
      expect(asset.isSpam, isTrue);
    });

    test('parses Alchemy media and collection image fallbacks', () {
      final mediaAsset = NftAssetModel.fromAlchemyJson(
        walletId: 'wallet-1',
        chainId: 1,
        ownerAddress: '0xOwner',
        json: {
          'contract': {'address': '0xNFT', 'tokenType': 'ERC721'},
          'tokenId': '10',
          'media': [
            {'gateway': 'ipfs://ipfs/media-hash'},
          ],
        },
      );
      final collectionAsset = NftAssetModel.fromAlchemyJson(
        walletId: 'wallet-1',
        chainId: 1,
        ownerAddress: '0xOwner',
        json: {
          'contract': {'address': '0xNFT2', 'tokenType': 'ERC721'},
          'tokenId': '11',
          'collection': {
            'image': {'cachedUrl': 'https://example.com/collection.png'},
          },
        },
      );

      expect(mediaAsset.imageUrl, 'https://ipfs.io/ipfs/media-hash');
      expect(collectionAsset.imageUrl, 'https://example.com/collection.png');
      expect(collectionAsset.displayImageUrl, collectionAsset.imageUrl);
    });

    test('round trips through json', () {
      final original = NftAssetModel.fromAlchemyJson(
        walletId: 'wallet-1',
        chainId: 1,
        ownerAddress: '0xOwner',
        json: {
          'contract': {'address': '0xNFT', 'tokenType': 'ERC1155'},
          'tokenId': '9',
          'name': 'Item',
        },
      );

      final decoded = NftAssetModel.fromJson(original.toJson());

      expect(decoded.id, original.id);
      expect(decoded.tokenType, NftTokenType.erc1155);
      expect(decoded.balance, original.balance);
      expect(decoded.rawJson, isNotEmpty);
    });
  });

  group('AlchemyNftPage', () {
    test('parses ownedNfts and pageKey', () {
      final page = AlchemyNftPage.fromJson({
        'ownedNfts': [
          {'tokenId': '1'},
          {'tokenId': '2'},
        ],
        'pageKey': 'next-page',
      });

      expect(page.nfts, hasLength(2));
      expect(page.pageKey, 'next-page');
    });

    test('maps supported Alchemy networks', () {
      expect(AlchemyNftApi.resolveNetworkSlug(1), 'eth-mainnet');
      expect(AlchemyNftApi.resolveNetworkSlug(56), 'bnb-mainnet');
      expect(AlchemyNftApi.supportsChain(999999), isFalse);
    });
  });
}
