import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/models/dApp_hive.dart';
import 'package:paracosm/pages/discover/discover_search_utils.dart';

void main() {
  group('DiscoverSearchUtils.normalizeUrl', () {
    test('keeps http and https URLs', () {
      expect(
        DiscoverSearchUtils.normalizeUrl('https://example.com/path'),
        'https://example.com/path',
      );
      expect(
        DiscoverSearchUtils.normalizeUrl('http://example.com'),
        'http://example.com',
      );
    });

    test('adds https to bare domains', () {
      expect(
        DiscoverSearchUtils.normalizeUrl('example.com/path'),
        'https://example.com/path',
      );
      expect(
        DiscoverSearchUtils.normalizeUrl('localhost:3000'),
        'https://localhost:3000',
      );
    });

    test('rejects search keywords', () {
      expect(DiscoverSearchUtils.normalizeUrl('magic eden'), isNull);
    });
  });

  group('DiscoverSearchUtils.fuzzySearch', () {
    final dapps = [
      DAppHive(
        name: 'Magic Eden',
        des: 'NFT marketplace',
        url: 'https://magiceden.io',
      ),
      DAppHive(name: 'Aave', des: 'DeFi lending', url: 'https://aave.com'),
      DAppHive(
        name: 'Cartesi',
        des: 'Blockchain app layer',
        url: 'https://cartesi.io',
      ),
    ];

    test('matches multiple query words', () {
      final result = DiscoverSearchUtils.fuzzySearch(dapps, 'magic market');

      expect(result, hasLength(1));
      expect(result.first.name, 'Magic Eden');
    });

    test('prioritizes name matches over description matches', () {
      final result = DiscoverSearchUtils.fuzzySearch(dapps, 'aave');

      expect(result.first.name, 'Aave');
    });
  });
}
