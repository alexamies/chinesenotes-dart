import 'package:test/test.dart';

import 'cnotes.dart';

void main() {
  test('DictionaryEntry.pinyin gets the expected result with no senses', () {
    var entry = DictionaryEntry('你好', 42, 1, []);
    expect(entry.pinyin, equals(''));
  });
  test('DictionaryEntry.pinyin gets the expected result with one sense', () {
    var chinese = '你好';
    var p = 'níhǎo';
    var sense = Sense(chinese, '', p, 'hello', 'interjection', 'p. 655');
    var entry = DictionaryEntry(chinese, 42, 1, [sense]);
    expect(entry.pinyin, equals(p));
  });
}
