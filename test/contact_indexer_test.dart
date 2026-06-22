import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/contact/contact_indexer.dart';

void main() {
  group('contactInitial', () {
    test('uses A-Z for English names', () {
      expect(contactInitial('Alice'), 'A');
      expect(contactInitial('bob'), 'B');
    });

    test('uses pinyin initial for Chinese names', () {
      expect(contactInitial('张三'), 'Z');
      expect(contactInitial('李四'), 'L');
      expect(contactInitial('陈一'), 'C');
    });

    test('uses # for names without a valid first letter', () {
      expect(contactInitial('1号'), '#');
      expect(contactInitial('😀Tom'), '#');
      expect(contactInitial('_abc'), '#');
      expect(contactInitial(''), '#');
    });
  });

  test('allContactIndexLetters always contains A-Z and #', () {
    expect(allContactIndexLetters, [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
      '#',
    ]);
  });

  test('buildContactIndexGroups groups by initial and keeps # last', () {
    final groups = buildContactIndexGroups([
      '张三',
      'bob',
      'Alice',
      '李四',
      '1号',
      '陈一',
    ], (name) => name);

    expect(groups.map((group) => group.initial), [
      'A',
      'B',
      'C',
      'L',
      'Z',
      '#',
    ]);
    expect(groups[0].contacts, ['Alice']);
    expect(groups[1].contacts, ['bob']);
    expect(groups[2].contacts, ['陈一']);
    expect(groups[3].contacts, ['李四']);
    expect(groups[4].contacts, ['张三']);
    expect(groups[5].contacts, ['1号']);
  });

  test('sorts contacts inside the same initial group by pinyin', () {
    final groups = buildContactIndexGroups(['赵六', '张三', '周五'], (name) => name);

    expect(groups.single.initial, 'Z');
    expect(groups.single.contacts, ['张三', '赵六', '周五']);
  });
}
