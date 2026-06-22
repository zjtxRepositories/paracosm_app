import 'package:lpinyin/lpinyin.dart';

final RegExp _letterRegExp = RegExp(r'^[A-Z]$');

const List<String> allContactIndexLetters = [
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
];

class ContactIndexGroup<T> {
  final String initial;
  final List<T> contacts;

  const ContactIndexGroup({required this.initial, required this.contacts});
}

String contactInitial(String name) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    return '#';
  }

  final firstChar = String.fromCharCode(trimmedName.runes.first);
  final upperFirstChar = firstChar.toUpperCase();

  if (_letterRegExp.hasMatch(upperFirstChar)) {
    return upperFirstChar;
  }

  if (ChineseHelper.isChinese(firstChar)) {
    final pinyin = PinyinHelper.getFirstWordPinyin(firstChar).toUpperCase();
    if (pinyin.isNotEmpty && _letterRegExp.hasMatch(pinyin[0])) {
      return pinyin[0];
    }
  }

  return '#';
}

String contactSortKey(String name) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    return '';
  }

  final buffer = StringBuffer();
  for (final rune in trimmedName.runes) {
    final char = String.fromCharCode(rune);
    if (ChineseHelper.isChinese(char)) {
      buffer.write(PinyinHelper.getFirstWordPinyin(char).toUpperCase());
    } else {
      buffer.write(char.toUpperCase());
    }
    buffer.write(' ');
  }

  return buffer.toString();
}

List<ContactIndexGroup<T>> buildContactIndexGroups<T>(
  Iterable<T> contacts,
  String Function(T contact) nameOf,
) {
  final groupedContacts = <String, List<T>>{
    for (final letter in allContactIndexLetters) letter: <T>[],
  };

  for (final contact in contacts) {
    groupedContacts[contactInitial(nameOf(contact))]!.add(contact);
  }

  for (final contacts in groupedContacts.values) {
    contacts.sort((a, b) {
      final aName = nameOf(a);
      final bName = nameOf(b);
      final sortResult = contactSortKey(aName).compareTo(contactSortKey(bName));
      if (sortResult != 0) {
        return sortResult;
      }
      return aName.compareTo(bName);
    });
  }

  return [
    for (final letter in allContactIndexLetters)
      if (groupedContacts[letter]!.isNotEmpty)
        ContactIndexGroup(
          initial: letter,
          contacts: List.unmodifiable(groupedContacts[letter]!),
        ),
  ];
}
