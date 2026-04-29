import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/scan/scan_result_parser.dart';

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

  test('parses paracosm friend links', () {
    final result = ScanResultParser.parse('paracosm://friend?userId=user_456');

    expect(result.type, ScanResultType.friend);
    expect(result.userId, 'user_456');
  });

  test('parses cryptocurrency payment links', () {
    final result = ScanResultParser.parse('bitcoin:bc1abc?amount=0.01');

    expect(result.type, ScanResultType.walletPayment);
    expect(result.address, 'bc1abc');
    expect(result.amount, '0.01');
    expect(result.tokenSymbol, 'BITCOIN');
  });
}
