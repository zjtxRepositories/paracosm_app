import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/db/dao/nft_asset_dao.dart';
import 'package:paracosm/core/network/api/alchemy_nft_api.dart';
import 'package:paracosm/modules/wallet/chains/service/nft_portfolio_service.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/nft_asset_model.dart';
import 'package:paracosm/modules/wallet/model/nft_sync_state_model.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';

void main() {
  group('NftPortfolioService', () {
    test('emits cache first then refreshed remote assets', () async {
      final cached = _asset(walletId: 'wallet-1', tokenId: 'cached');
      final assetDao = _MemoryNftAssetDao({
        'wallet-1': [cached],
      });
      final stateDao = _MemoryNftSyncStateDao();
      final service = NftPortfolioService.forTesting(
        assetDao: assetDao,
        syncStateDao: stateDao,
        pageFetcher:
            ({required chainId, required ownerAddress, String? pageKey}) async {
              return AlchemyNftPage(
                nfts: [
                  {
                    'contract': {'address': '0xNFT', 'tokenType': 'ERC721'},
                    'tokenId': 'remote',
                    'name': 'Remote NFT',
                  },
                ],
                pageKey: '',
              );
            },
      );

      final emissions = <List<NftAssetModel>>[];
      final sub = service.stream.listen(emissions.add);
      await service.start(_wallet('wallet-1'));
      await Future<void>.delayed(Duration.zero);

      expect(emissions.first.map((e) => e.tokenId), ['cached']);
      expect(emissions.last.map((e) => e.tokenId), ['remote']);
      expect(stateDao.states.values.single.status, NftSyncStatus.success);

      await sub.cancel();
    });

    test('follows pageKey pagination', () async {
      final assetDao = _MemoryNftAssetDao({});
      final stateDao = _MemoryNftSyncStateDao();
      final requestedPageKeys = <String?>[];
      final service = NftPortfolioService.forTesting(
        assetDao: assetDao,
        syncStateDao: stateDao,
        pageFetcher:
            ({required chainId, required ownerAddress, String? pageKey}) async {
              requestedPageKeys.add(pageKey);
              if (pageKey == null) {
                return const AlchemyNftPage(
                  nfts: [
                    {
                      'contract': {'address': '0xA', 'tokenType': 'ERC721'},
                      'tokenId': '1',
                    },
                  ],
                  pageKey: 'next',
                );
              }
              return const AlchemyNftPage(
                nfts: [
                  {
                    'contract': {'address': '0xA', 'tokenType': 'ERC721'},
                    'tokenId': '2',
                  },
                ],
                pageKey: '',
              );
            },
      );

      await service.start(_wallet('wallet-1'));

      expect(requestedPageKeys, [null, 'next']);
      expect(assetDao.assetsFor('wallet-1').map((e) => e.tokenId), ['1', '2']);
    });

    test(
      'stale wallet refresh does not overwrite current wallet emission',
      () async {
        final assetDao = _MemoryNftAssetDao({
          'wallet-2': [_asset(walletId: 'wallet-2', tokenId: 'new')],
        });
        final stateDao = _MemoryNftSyncStateDao();
        stateDao.states['wallet-2:1'] = NftSyncStateModel.build(
          walletId: 'wallet-2',
          chainId: 1,
          ownerAddress: '0xOwner',
          status: NftSyncStatus.success,
        );
        final service = NftPortfolioService.forTesting(
          assetDao: assetDao,
          syncStateDao: stateDao,
          pageFetcher:
              ({required chainId, required ownerAddress, String? pageKey}) {
                return Future<AlchemyNftPage>(() async {
                  await Future<void>.delayed(const Duration(milliseconds: 20));
                  return const AlchemyNftPage(nfts: [], pageKey: '');
                });
              },
        );

        final emissions = <List<NftAssetModel>>[];
        final sub = service.stream.listen(emissions.add);
        final firstStart = service.start(_wallet('wallet-1'));
        await service.start(_wallet('wallet-2'));
        await firstStart;

        expect(emissions.last.map((e) => e.walletId), ['wallet-2']);
        await sub.cancel();
      },
    );

    test('hydrates missing image from metadata uri', () async {
      final assetDao = _MemoryNftAssetDao({});
      final stateDao = _MemoryNftSyncStateDao();
      final service = NftPortfolioService.forTesting(
        assetDao: assetDao,
        syncStateDao: stateDao,
        pageFetcher:
            ({required chainId, required ownerAddress, String? pageKey}) async {
              return AlchemyNftPage(
                nfts: [
                  {
                    'contract': {'address': '0xNFT', 'tokenType': 'ERC721'},
                    'tokenId': '100',
                    'tokenUri': {
                      'raw':
                          'ipfs://QmfZWVXaDWFEtgsMRWGGJ7gFU6enjVuHTBWmmhvf6swUcz',
                    },
                    'rawMetadata': {},
                  },
                ],
                pageKey: '',
              );
            },
        metadataFetcher: (metadataUri) async {
          expect(
            metadataUri,
            'ipfs://QmfZWVXaDWFEtgsMRWGGJ7gFU6enjVuHTBWmmhvf6swUcz',
          );
          return {
            'name': 'Hydrated NFT',
            'image': {'gateway': 'https://example.com/hydrated.png'},
          };
        },
      );

      await service.start(_wallet('wallet-1'));

      final assets = assetDao.assetsFor('wallet-1');
      expect(assets, hasLength(1));
      expect(assets.single.displayLabel, 'Hydrated NFT');
      expect(assets.single.imageUrl, 'https://example.com/hydrated.png');
    });
  });
}

WalletModel _wallet(String id) {
  return WalletModel(
    id: id,
    aIndex: 0,
    type: WalletType.mnemonic,
    currentChainId: 1,
    chains: [
      ChainAccount(
        name: 'Ethereum',
        address: '0xOwner',
        chainId: 1,
        logo: '',
        symbol: 'ETH',
        chainType: ChainType.evm,
        nodes: const [],
      ),
    ],
  );
}

NftAssetModel _asset({required String walletId, required String tokenId}) {
  return NftAssetModel.fromAlchemyJson(
    walletId: walletId,
    chainId: 1,
    ownerAddress: '0xOwner',
    json: {
      'contract': {'address': '0xNFT', 'tokenType': 'ERC721'},
      'tokenId': tokenId,
      'name': tokenId,
    },
  );
}

class _MemoryNftAssetDao extends NftAssetDao {
  _MemoryNftAssetDao(Map<String, List<NftAssetModel>> initial)
    : _assets = {
        for (final entry in initial.entries)
          entry.key: List<NftAssetModel>.from(entry.value),
      };

  final Map<String, List<NftAssetModel>> _assets;

  List<NftAssetModel> assetsFor(String walletId) =>
      List<NftAssetModel>.from(_assets[walletId] ?? const []);

  @override
  Future<List<NftAssetModel>> getWalletAssets(String walletId) async {
    return assetsFor(walletId);
  }

  @override
  Future<void> replaceWalletChainAssets(
    String walletId,
    int chainId,
    List<NftAssetModel> assets,
  ) async {
    final others = (_assets[walletId] ?? const <NftAssetModel>[])
        .where((asset) => asset.chainId != chainId)
        .toList();
    _assets[walletId] = [...others, ...assets];
  }
}

class _MemoryNftSyncStateDao extends NftSyncStateDao {
  final Map<String, NftSyncStateModel> states = {};

  @override
  Future<NftSyncStateModel?> getState(String walletId, int chainId) async {
    return states['$walletId:$chainId'];
  }

  @override
  Future<void> upsertState(NftSyncStateModel state) async {
    states[state.id] = state;
  }
}
