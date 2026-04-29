import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/pages/discover/discover_search_utils.dart';

void main() {
  test('normalizes a bare URL for browser entry', () {
    expect(
      DiscoverSearchUtils.normalizeUrl('example.com'),
      'https://example.com',
    );
  });
}
