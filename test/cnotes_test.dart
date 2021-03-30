import 'package:test/test.dart';

import '../cnotes.dart';

// DictionaryLoader load a dictionary from some source.
class TestDictionaryLoader implements DictionaryLoader {
  /// fill in real implementation
  Future<DictionaryCollection> load() async {
    var chinese = '你好';
    var sense = Sense(chinese, '', 'níhǎo', 'hello', 'interjection', 'p. 655');
    var entry = DictionaryEntry(chinese, 42, 1, [sense]);
    var entryList = DictionaryEntries(chinese, [entry]);
    var entries = <String, DictionaryEntries>{chinese: entryList};
    return DictionaryCollection(entries);
  }
}

void main() {
  test('DictionaryEntry.pinyin gets the expected result with one sense', () {
    var chinese = '你好';
    var p = 'níhǎo';
    var sense = Sense(chinese, '', p, 'hello', 'interjection', 'p. 655');
    var entry = DictionaryEntry(chinese, 42, 1, [sense]);
    expect(entry.pinyin, equals(p));
  });
  test('DictionaryEntry.pinyin gets the expected result with no senses',
      () async {
    var cnSource = DictionarySource(1, 'cnotes.json', 'Chinese Notes',
        'Chinese Notes Chinese-English Dictionary', 'www.com');
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var loader = HttpDictionaryLoader('abc');
    var dictionaries = await loader.load();
    var app = App(dictionaries, sources);
    var dictEntries = app.dictionaries.lookup('你好');
    expect(dictEntries.entries.length, equals(1));
  });
}
