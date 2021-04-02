import 'package:test/test.dart';

import 'package:chinesenotes/chinesenotes.dart';

const jsonString =
    """[{"s":"邃古","t":"","p":"suìgǔ","e": "remote antiquity","g":"noun","n":"(CC-CEDICT '邃古'; Guoyu '邃古')","h":"2"}]""";

var cnSource = DictionarySource(1, 'cnotes.json', 'Chinese Notes',
    'Chinese Notes Chinese-English Dictionary', 'www.com');

// DictionaryLoader load a dictionary from some source.
class TestDictionaryLoader {
  /// fill in real implementation
  Future<DictionaryCollectionIndex> load() async {
    var chinese = '你好';
    var sense = Sense(chinese, '', 'níhǎo', 'hello', 'interjection', 'p. 655');
    var entry = DictionaryEntry(chinese, 42, 1, [sense]);
    var entryList = DictionaryEntries(chinese, [entry]);
    var entries = <String, DictionaryEntries>{chinese: entryList};
    return DictionaryCollectionIndex(entries);
  }
}

void main() {
  test('DictionaryCollectionIndex.lookup finds a matching headword.', () async {
    var loader = TestDictionaryLoader();
    var forwardIndex = await loader.load();
    const headword = '你好';
    var dictEntries = forwardIndex.lookup(headword);
    expect(dictEntries.entries.length, equals(1));
    var entry = dictEntries.entries.first;
    expect(entry.headword, equals(headword));
  });
  test('dictFromJson builds the index correctly', () {
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var forrwardIndex = dictFromJson(jsonString, cnSource);
    const headword = '邃古';
    var dictEntries = forrwardIndex.lookup(headword);
    expect(dictEntries.entries.length, equals(1));
    var entry = dictEntries.entries.first;
    expect(entry.headword, equals(headword));
    for (var ent in dictEntries.entries) {
      var source = sources.lookup(ent.sourceId);
      expect(source.abbreviation, cnSource.abbreviation);
      expect(ent.senses.length, equals(1));
      for (var sense in ent.senses) {
        expect(sense.pinyin, 'suìgǔ');
        expect(sense.english, 'remote antiquity');
      }
    }
  });
  test('buildReverseIndex builds the reverse index correctly', () async {
    var loader = TestDictionaryLoader();
    var forwardIndex = await loader.load();
    List<String> patterns = [];
    var np = NotesProcessor(patterns);
    var reverseIndex = buildReverseIndex(forwardIndex, np);
    const headword = '你好';
    const english = 'hello';
    var senses = reverseIndex.lookup(english);
    expect(senses.senses.length, equals(1));
    var sense = senses.senses.first;
    expect(sense.simplified, equals(headword));
  });
  test('NotesProcessor.parseNotes return equivalents in notes', () {
    const notes = 'Scientific name: Rosa rugosa (CC-CEDICT)';
    var np = NotesProcessor([r'Scientific name: (.+) \(']);
    var equivalents = np.parseNotes(notes);
    expect(equivalents.length, equals(1));
    expect(equivalents[0], equals('Rosa rugosa'));
  });
}
