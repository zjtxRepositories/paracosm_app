import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:paracosm/core/db/dao/nft_asset_dao.dart';
import 'package:paracosm/core/network/api/alchemy_nft_api.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/nft_asset_model.dart';
import 'package:paracosm/modules/wallet/model/nft_sync_state_model.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';

typedef NftPageFetcher =
    Future<AlchemyNftPage> Function({
      required int chainId,
      required String ownerAddress,
      String? pageKey,
    });
typedef NftMetadataFetcher =
    Future<Map<String, dynamic>?> Function(String metadataUri);

class NftPortfolioService {
  static final NftPortfolioService _instance = NftPortfolioService._internal();
  factory NftPortfolioService() => _instance;

  NftPortfolioService._internal({
    NftPageFetcher? pageFetcher,
    NftMetadataFetcher? metadataFetcher,
    NftAssetDao? assetDao,
    NftSyncStateDao? syncStateDao,
  }) : _pageFetcher = pageFetcher ?? AlchemyNftApi.getNFTsForOwner,
       _metadataFetcher = metadataFetcher ?? AlchemyNftApi.getNftMetadata,
       _assetDao = assetDao ?? NftAssetDao(),
       _syncStateDao = syncStateDao ?? NftSyncStateDao();

  factory NftPortfolioService.forTesting({
    NftPageFetcher? pageFetcher,
    NftMetadataFetcher? metadataFetcher,
    NftAssetDao? assetDao,
    NftSyncStateDao? syncStateDao,
  }) {
    return NftPortfolioService._internal(
      pageFetcher: pageFetcher,
      metadataFetcher: metadataFetcher,
      assetDao: assetDao,
      syncStateDao: syncStateDao,
    );
  }

  final NftPageFetcher _pageFetcher;
  final NftMetadataFetcher _metadataFetcher;
  final NftAssetDao _assetDao;
  final NftSyncStateDao _syncStateDao;

  final StreamController<List<NftAssetModel>> _controller =
      StreamController.broadcast();
  Stream<List<NftAssetModel>> get stream => _controller.stream;

  List<NftAssetModel> _currentAssets = [];
  String? _walletId;
  int _generation = 0;
  Timer? _timer;

  List<NftAssetModel> get currentAssets => List.unmodifiable(_currentAssets);

  Future<void> start(WalletModel wallet, {bool forceRefresh = false}) async {
    final nextWalletId = wallet.id;
    if (nextWalletId.isEmpty) return;

    _generation++;
    final generation = _generation;
    _walletId = nextWalletId;
    _timer?.cancel();

    final cached = await _assetDao.getWalletAssets(nextWalletId);
    if (!_isCurrent(generation, nextWalletId)) return;
    _emit(cached);

    final chains = _supportedChains(wallet);
    if (chains.isEmpty) {
      return;
    }

    for (final chain in chains) {
      if (!_isCurrent(generation, nextWalletId)) return;
      final state = await _syncStateDao.getState(nextWalletId, chain.chainId);
      final shouldRefresh =
          forceRefresh ||
          state == null ||
          state.status != NftSyncStatus.success ||
          DateTime.now().difference(state.lastSyncedAt).inMinutes >= 5;
      if (!shouldRefresh) continue;
      await _syncChainAssets(
        walletId: nextWalletId,
        chain: chain,
        generation: generation,
        forceRefresh: forceRefresh,
      );
    }

    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      refresh(wallet);
    });
  }

  Future<void> refresh(WalletModel wallet) async {
    await start(wallet, forceRefresh: true);
  }

  void clean() {
    _generation++;
    _walletId = null;
    _timer?.cancel();
    _timer = null;
    _emit(const []);
  }

  List<ChainAccount> _supportedChains(WalletModel wallet) {
    return wallet.chains
        .where((chain) => chain.chainType == ChainType.evm)
        .where((chain) => chain.address.isNotEmpty)
        .where((chain) => AlchemyNftApi.supportsChain(chain.chainId))
        .toList();
  }

  bool _isCurrent(int generation, String walletId) {
    return generation == _generation && walletId == _walletId;
  }

  Future<void> _syncChainAssets({
    required String walletId,
    required ChainAccount chain,
    required int generation,
    required bool forceRefresh,
  }) async {
    return;
    final unsupported = !AlchemyNftApi.supportsChain(chain.chainId);
    if (unsupported) {
      await _syncStateDao.upsertState(
        NftSyncStateModel.build(
          walletId: walletId,
          chainId: chain.chainId,
          ownerAddress: chain.address,
          status: NftSyncStatus.unsupported,
          errorMessage: 'Unsupported chain',
        ),
      );
      return;
    }

    final rows = <NftAssetModel>[];
    String? pageKey;
    try {
      while (true) {
        if (!_isCurrent(generation, walletId)) return;
        final page = await _pageFetcher(
          chainId: chain.chainId,
          ownerAddress: chain.address,
          pageKey: pageKey,
        );
        final syncedAt = DateTime.now();
        for (final raw in page.nfts) {
          final asset = NftAssetModel.fromAlchemyJson(
            json: raw,
            walletId: walletId,
            chainId: chain.chainId,
            ownerAddress: chain.address,
            syncedAt: syncedAt,
          );
          rows.add(await _hydrateMissingImage(asset));
        }
        pageKey = page.pageKey.trim();
        if (pageKey.isEmpty) break;
      }

      await _assetDao.replaceWalletChainAssets(walletId, chain.chainId, rows);
      await _syncStateDao.upsertState(
        NftSyncStateModel.build(
          walletId: walletId,
          chainId: chain.chainId,
          ownerAddress: chain.address,
          status: NftSyncStatus.success,
          pageKey: '',
          lastSyncedAt: DateTime.now(),
        ),
      );
      final cached = await _assetDao.getWalletAssets(walletId);
      if (_isCurrent(generation, walletId)) {
        _emit(cached);
      }
    } catch (error, stackTrace) {
      debugPrint('NFT sync failed chain=${chain.chainId}: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _syncStateDao.upsertState(
        NftSyncStateModel.build(
          walletId: walletId,
          chainId: chain.chainId,
          ownerAddress: chain.address,
          status: NftSyncStatus.failed,
          errorMessage: error.toString(),
          lastSyncedAt: DateTime.now(),
        ),
      );
      if (forceRefresh) {
        final cached = await _assetDao.getWalletAssets(walletId);
        if (_isCurrent(generation, walletId)) {
          _emit(cached);
        }
      }
    }
  }

  Future<NftAssetModel> _hydrateMissingImage(NftAssetModel asset) async {
    if (asset.displayImageUrl.isNotEmpty || asset.metadataUri.isEmpty) {
      return asset;
    }
    final metadata = await _metadataFetcher(asset.metadataUri);
    if (metadata == null || metadata.isEmpty) {
      return asset;
    }
    final hydrated = asset.withMetadataFallback(metadata);
    if (hydrated.displayImageUrl.isNotEmpty) {
      debugPrint('NFT metadata image hydrated token=${asset.id}');
    }
    return hydrated;
  }

  void _emit(List<NftAssetModel> assets) {
    _currentAssets = List<NftAssetModel>.from(assets)
      ..sort((a, b) {
        final collectionCompare = a.collectionName.toLowerCase().compareTo(
          b.collectionName.toLowerCase(),
        );
        if (collectionCompare != 0) return collectionCompare;
        final contractCompare = a.contractAddress.toLowerCase().compareTo(
          b.contractAddress.toLowerCase(),
        );
        if (contractCompare != 0) return contractCompare;
        return a.tokenId.compareTo(b.tokenId);
      });
    _controller.add(List<NftAssetModel>.from(_currentAssets));
  }
}
