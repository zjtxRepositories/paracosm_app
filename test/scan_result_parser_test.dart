import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';
import 'package:paracosm/modules/scan/scan_result_parser.dart';
import 'package:paracosm/pages/profile/token_receive_payload.dart';
import 'package:paracosm/pages/profile/transfer_scan_address.dart';

void main() {
  test('parses web URLs', () {
    final result = ScanResultParser.parse('example.com/path');

    expect(result.type, ScanResultType.webUrl);
    expect(result.url, 'https://example.com/path');
  });

  test('parses friend JSON payloads', () {
    final result = ScanResultParser.parse(
      '{"type":"add_friend","userId":"user_123"}',
    );

    expect(result.type, ScanResultType.friend);
    expect(result.userId, 'user_123');
  });

  test('parses wallet payment JSON payloads', () {
    final result = ScanResultParser.parse(
      '{"type":"payment","address":"0xabc","amount":"1.5","token":"BNB","chain":"bsc"}',
    );

    expect(result.type, ScanResultType.walletPayment);
    expect(result.address, '0xabc');
    expect(result.amount, '1.5');
    expect(result.tokenSymbol, 'BNB');
    expect(result.chain, 'bsc');
  });

  test('parses token receive QR payment payloads without amount', () {
    final payload = buildTokenReceivePaymentPayload(
      address: '0xwallet',
      tokenSymbol: 'USDT',
      chain: 'Binancestry(BSC)',
    );

    final result = ScanResultParser.parse(payload);

    expect(result.type, ScanResultType.walletPayment);
    expect(result.address, '0xwallet');
    expect(result.amount, isNull);
    expect(result.tokenSymbol, 'USDT');
    expect(result.chain, 'Binancestry(BSC)');
  });

  test('parses paracosm friend links', () {
    final result = ScanResultParser.parse('paracosm://friend?userId=user_456');

    expect(result.type, ScanResultType.friend);
    expect(result.userId, 'user_456');
  });

  test('parses invite JSON payloads', () {
    final result = ScanResultParser.parse(
      '{"type":"invite","inviteCode":"ABCD1234"}',
    );

    expect(result.type, ScanResultType.invite);
    expect(result.inviteCode, 'ABCD1234');
  });

  test('parses paracosm invite links', () {
    final result = ScanResultParser.parse('paracosm://invite?code=ABCD1234');

    expect(result.type, ScanResultType.invite);
    expect(result.inviteCode, 'ABCD1234');
  });

  test('parses paracosm path invite links', () {
    final result = ScanResultParser.parse('paracosm:///invite?code=ABCD1234');

    expect(result.type, ScanResultType.invite);
    expect(result.inviteCode, 'ABCD1234');
  });

  test('parses web invite links before generic web URLs', () {
    final result = ScanResultParser.parse(
      'https://invite.zjtxy.top/invite/REPLACE_WITH_DOWNLOAD_PAGE_URL?code=ABCD1234',
    );

    expect(result.type, ScanResultType.invite);
    expect(result.inviteCode, 'ABCD1234');
    expect(
      result.url,
      'https://invite.zjtxy.top/invite/REPLACE_WITH_DOWNLOAD_PAGE_URL?code=ABCD1234',
    );
  });

  test('parses cryptocurrency payment links', () {
    final result = ScanResultParser.parse('bitcoin:bc1abc?amount=0.01');

    expect(result.type, ScanResultType.walletPayment);
    expect(result.address, 'bc1abc');
    expect(result.amount, '0.01');
    expect(result.tokenSymbol, 'BITCOIN');
  });

  group('extracts transfer address from scan result', () {
    test('uses address from wallet payment JSON and ignores amount', () {
      final prefill = extractTransferPrefillFromScan(
        '{"type":"payment","address":"0xabc","amount":"1.5","token":"BNB","chain":"bsc"}',
      );

      expect(prefill?.address, '0xabc');
      expect(prefill?.amount, '1.5');
      expect(prefill?.tokenSymbol, 'BNB');
      expect(prefill?.chain, 'bsc');
      expect(
        extractTransferAddressFromScan(
          '{"type":"payment","address":"0xabc","amount":"1.5","token":"BNB","chain":"bsc"}',
        ),
        '0xabc',
      );
    });

    test('uses address from token receive QR payload', () {
      final payload = buildTokenReceivePaymentPayload(
        address: '0xwallet',
        tokenSymbol: 'USDT',
        chain: 'Binancestry(BSC)',
      );

      final prefill = extractTransferPrefillFromScan(payload);

      expect(prefill?.address, '0xwallet');
      expect(prefill?.amount, isNull);
      expect(prefill?.tokenSymbol, 'USDT');
      expect(prefill?.chain, 'Binancestry(BSC)');
    });

    test('uses raw text for plain address QR codes', () {
      final prefill = extractTransferPrefillFromScan('  0xplain  ');

      expect(prefill?.address, '0xplain');
      expect(prefill?.amount, isNull);
      expect(prefill?.tokenSymbol, isNull);
      expect(prefill?.chain, isNull);
    });

    test('ignores friend and web QR codes', () {
      expect(
        extractTransferAddressFromScan(
          '{"type":"add_friend","userId":"user_123"}',
        ),
        isNull,
      );
      expect(extractTransferAddressFromScan('example.com/path'), isNull);
    });
  });

  group('matches transfer scan chain and token', () {
    final bnb = _token(symbol: 'BNB', address: '', chainId: 56);
    final usdt = _token(symbol: 'USDT', address: '0xusdt', chainId: 56);
    final sol = _token(symbol: 'SOL', address: '', chainId: 501);
    final bsc = _chain(
      name: 'Binancestry(BSC)',
      symbol: 'BNB',
      chainId: 56,
      tokens: [bnb, usdt],
    );
    final solana = _chain(
      name: 'Solana',
      symbol: 'SOL',
      chainId: 501,
      chainType: ChainType.solana,
      tokens: [sol],
    );
    final wallet = WalletModel(
      id: 'wallet',
      aIndex: 0,
      chains: [bsc, solana],
      type: WalletType.mnemonic,
      currentChainId: 56,
    );

    test('matches chain by chainId, name, and symbol', () {
      expect(findTransferScanChain(wallet, '56'), same(bsc));
      expect(findTransferScanChain(wallet, 'Binancestry(BSC)'), same(bsc));
      expect(findTransferScanChain(wallet, 'SOL'), same(solana));
      expect(findTransferScanChain(wallet, 'unknown'), isNull);
    });

    test('matches token by symbol and falls back to native token', () {
      expect(findTransferScanToken(bsc, 'USDT'), same(usdt));
      expect(findTransferScanToken(bsc, 'BNB'), same(bnb));

      final usdtMatch = matchTransferScanAsset(
        wallet,
        const TransferScanPrefill(
          address: '0xabc',
          tokenSymbol: 'USDT',
          chain: '56',
        ),
      );
      expect(usdtMatch.chain, same(bsc));
      expect(usdtMatch.token, same(usdt));

      final fallbackMatch = matchTransferScanAsset(
        wallet,
        const TransferScanPrefill(
          address: '0xabc',
          tokenSymbol: 'UNKNOWN',
          chain: 'unknown',
        ),
      );
      expect(fallbackMatch.chain, same(bsc));
      expect(fallbackMatch.token, same(bnb));
    });
  });
}

ChainAccount _chain({
  required String name,
  required String symbol,
  required int chainId,
  required List<TokenModel> tokens,
  ChainType chainType = ChainType.evm,
}) {
  return ChainAccount(
    name: name,
    address: '0xfrom$chainId',
    chainId: chainId,
    logo: '',
    symbol: symbol,
    tokens: tokens,
    chainType: chainType,
    nodes: const [],
  );
}

TokenModel _token({
  required String symbol,
  required String address,
  required int chainId,
}) {
  return TokenModel(
    symbol: symbol,
    name: symbol,
    address: address,
    balance: BigInt.zero,
    decimals: 18,
    logo: '',
    coinId: '',
    chainId: chainId,
  );
}
