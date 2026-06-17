import 'package:paracosm/modules/wallet/model/nft_asset_model.dart';
import 'package:paracosm/modules/wallet/model/nft_sync_state_model.dart';
import 'package:sqflite/sqflite.dart';

import 'base_dao.dart';

class NftAssetDao extends BaseDao {
  static const String tableName = 'nft_assets';

  static const String createTableSql =
      '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id TEXT PRIMARY KEY,
    walletId TEXT NOT NULL,
    chainId INTEGER NOT NULL,
    ownerAddress TEXT NOT NULL,
    contractAddress TEXT NOT NULL,
    tokenId TEXT NOT NULL,
    tokenType TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    imageUrl TEXT,
    animationUrl TEXT,
    metadataUri TEXT,
    collectionName TEXT,
    collectionImageUrl TEXT,
    balance TEXT NOT NULL,
    isSpam INTEGER NOT NULL DEFAULT 0,
    isHidden INTEGER NOT NULL DEFAULT 0,
    lastSyncedAt TEXT NOT NULL,
    rawJson TEXT NOT NULL
  )
  ''';

  Future<List<NftAssetModel>> getWalletAssets(String walletId) async {
    final rows = await query(
      tableName,
      where: 'walletId = ?',
      whereArgs: [walletId],
      orderBy: 'chainId ASC, collectionName COLLATE NOCASE ASC, tokenId ASC',
    );
    return rows.map(NftAssetModel.fromJson).toList();
  }

  Future<List<NftAssetModel>> getWalletChainAssets(
    String walletId,
    int chainId,
  ) async {
    final rows = await query(
      tableName,
      where: 'walletId = ? AND chainId = ?',
      whereArgs: [walletId, chainId],
      orderBy: 'collectionName COLLATE NOCASE ASC, tokenId ASC',
    );
    return rows.map(NftAssetModel.fromJson).toList();
  }

  Future<void> replaceWalletChainAssets(
    String walletId,
    int chainId,
    List<NftAssetModel> assets,
  ) async {
    await transaction((txn) async {
      await txn.delete(
        tableName,
        where: 'walletId = ? AND chainId = ?',
        whereArgs: [walletId, chainId],
      );
      if (assets.isEmpty) return;
      for (final asset in assets) {
        await txn.insert(
          tableName,
          asset.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}

class NftSyncStateDao extends BaseDao {
  static const String tableName = 'nft_sync_state';

  static const String createTableSql =
      '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id TEXT PRIMARY KEY,
    walletId TEXT NOT NULL,
    chainId INTEGER NOT NULL,
    ownerAddress TEXT NOT NULL,
    status TEXT NOT NULL,
    pageKey TEXT,
    lastSyncedAt TEXT NOT NULL,
    errorMessage TEXT
  )
  ''';

  Future<NftSyncStateModel?> getState(String walletId, int chainId) async {
    final row = await queryOne(
      tableName,
      where: 'walletId = ? AND chainId = ?',
      whereArgs: [walletId, chainId],
    );
    if (row == null) return null;
    return NftSyncStateModel.fromJson(row);
  }

  Future<void> upsertState(NftSyncStateModel state) async {
    await insert(tableName, state.toJson());
  }
}
