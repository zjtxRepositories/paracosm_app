import '../../core/models/dApp_hive.dart';
import '../../modules/scan/scan_result_parser.dart';

class DiscoverSearchUtils {
  DiscoverSearchUtils._();

  static String? normalizeUrl(String input) {
    return ScanResultParser.normalizeUrl(input);
  }

  static String webSearchUrl(String keyword) {
    return Uri.https('duckduckgo.com', '/', {'q': keyword.trim()}).toString();
  }

  static List<DAppHive> fuzzySearch(List<DAppHive> items, String query) {
    final words = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return [];
    }

    final scored = <_ScoredDApp>[];
    for (final item in items) {
      final score = _score(item, words);
      if (score > 0) {
        scored.add(_ScoredDApp(item, score));
      }
    }

    scored.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return (a.item.name ?? '').compareTo(b.item.name ?? '');
    });

    return scored.map((entry) => entry.item).toList();
  }

  static int _score(DAppHive item, List<String> words) {
    final name = (item.name ?? '').toLowerCase();
    final description = (item.des ?? '').toLowerCase();
    final url = item.url.toLowerCase();
    final combined = '$name $description $url';

    if (!words.every(combined.contains)) {
      return 0;
    }

    var score = 10;
    for (final word in words) {
      if (name == word) {
        score += 100;
      } else if (name.startsWith(word)) {
        score += 80;
      } else if (name.contains(word)) {
        score += 60;
      }

      if (url.contains(word)) {
        score += 30;
      }
      if (description.contains(word)) {
        score += 20;
      }
    }

    return score;
  }
}

class _ScoredDApp {
  final DAppHive item;
  final int score;

  const _ScoredDApp(this.item, this.score);
}
