enum NftSyncStatus { idle, syncing, success, failed, unsupported }

NftSyncStatus nftSyncStatusFromString(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'syncing':
      return NftSyncStatus.syncing;
    case 'success':
      return NftSyncStatus.success;
    case 'failed':
      return NftSyncStatus.failed;
    case 'unsupported':
      return NftSyncStatus.unsupported;
    default:
      return NftSyncStatus.idle;
  }
}

String nftSyncStatusToString(NftSyncStatus value) {
  return value.name;
}

class NftSyncStateModel {
  final String id;
  final String walletId;
  final int chainId;
  final String ownerAddress;
  final NftSyncStatus status;
  final String pageKey;
  final DateTime lastSyncedAt;
  final String errorMessage;

  const NftSyncStateModel({
    required this.id,
    required this.walletId,
    required this.chainId,
    required this.ownerAddress,
    required this.status,
    required this.pageKey,
    required this.lastSyncedAt,
    required this.errorMessage,
  });

  factory NftSyncStateModel.fromJson(Map<String, dynamic> json) {
    return NftSyncStateModel(
      id: json['id'].toString(),
      walletId: json['walletId'].toString(),
      chainId: json['chainId'] is int
          ? json['chainId'] as int
          : int.tryParse('${json['chainId']}') ?? 0,
      ownerAddress: json['ownerAddress']?.toString() ?? '',
      status: nftSyncStatusFromString(json['status']?.toString()),
      pageKey: json['pageKey']?.toString() ?? '',
      lastSyncedAt:
          DateTime.tryParse(json['lastSyncedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      errorMessage: json['errorMessage']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'chainId': chainId,
      'ownerAddress': ownerAddress,
      'status': nftSyncStatusToString(status),
      'pageKey': pageKey,
      'lastSyncedAt': lastSyncedAt.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory NftSyncStateModel.build({
    required String walletId,
    required int chainId,
    required String ownerAddress,
    required NftSyncStatus status,
    String pageKey = '',
    DateTime? lastSyncedAt,
    String errorMessage = '',
  }) {
    return NftSyncStateModel(
      id: '$walletId:$chainId',
      walletId: walletId,
      chainId: chainId,
      ownerAddress: ownerAddress,
      status: status,
      pageKey: pageKey,
      lastSyncedAt: lastSyncedAt ?? DateTime.now(),
      errorMessage: errorMessage,
    );
  }
}
