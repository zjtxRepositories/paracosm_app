import 'package:paracosm/modules/wallet/chains/sol/solana_service.dart';
import 'package:solana/solana.dart';
import 'package:solana/dto.dart';

class SolanaChainService {
  final SolanaService _solService = SolanaService();
  static bool isTestnet = true;

  /// 多 RPC 节点
  final List<String> _rpcUrls = isTestnet
      ? ['https://api.devnet.solana.com']
      : [
    'https://api.mainnet-beta.solana.com',
    'https://solana-api.projectserum.com',
    'https://solana.public-rpc.com',
  ];

  RpcClient? _client;

  /// =========================
  /// 获取可用 RPC（带容灾）
  /// =========================
  Future<RpcClient> _getClient() async {
    if (_client != null) return _client!;

    for (final url in _rpcUrls) {
      final client = RpcClient(url, timeout: const Duration(seconds: 10));
      try {
        await client.getHealth();
        _client = client;
        return client;
      } catch (_) {
        continue;
      }
    }

    throw Exception("所有 RPC 节点不可用");
  }

  /// =========================
  /// SOL 余额
  /// =========================
  Future<BigInt> getBalance() async {
    final client = await _getClient();
    print('address-----${_solService.address}');
    final result = await client.getBalance(_solService.address);

    return BigInt.from(result.value);
  }

  /// =========================
  /// Token 余额（SPL）
  /// =========================
  Future<BigInt> getTokenBalance(String mintAddress) async {
    final client = await _getClient();

    final result = await client.getTokenAccountsByOwner(
      _solService.address,
      TokenAccountsFilter.byMint(mintAddress),
    );

    if (result.value.isEmpty) return BigInt.zero;

    final data = result.value.first.account.data;
    if (data is ParsedAccountData) {
      final parsed = data.parsed as Map<String, dynamic>;
      final info = parsed['info'];
      final tokenAmount = info['tokenAmount'];

      return BigInt.parse(tokenAmount['amount']);
    }

    return BigInt.zero;
  }

  /// =========================
  /// 转 SOL
  /// =========================
  Future<String> sendSol({
    required String toAddress,
    required double amount,
  }) async {
    final client = await _getClient();

    final lamports = (amount * lamportsPerSol).toInt();

    final tx = await client.signAndSendTransaction(
      Message(
        instructions: [
          SystemInstruction.transfer(
            fundingAccount:
            Ed25519HDPublicKey.fromBase58(_solService.address),
            recipientAccount:
            Ed25519HDPublicKey.fromBase58(toAddress),
            lamports: lamports,
          ),
        ],
      ),
      [_solService.keyPair],
    );

    return tx;
  }

  /// =========================
  /// 获取交易记录（简单版）
  /// =========================
  Future<List<String>> getTxs() async {
    final client = await _getClient();

    final result =
    await client.getSignaturesForAddress(_solService.address);

    return result.map((e) => e.signature).toList();
  }

  /// =========================
  /// 地址校验
  /// =========================
  bool isValidAddress(String address) {
    final reg = RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$');
    return reg.hasMatch(address);
  }
}