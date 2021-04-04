import 'package:test/test.dart';

import 'package:chinesenotes/chinesenotes.dart';

const jsonString = """
[{"s":"邃古","t":"","p":"suìgǔ","e": "remote antiquity","g":"noun","n":"(CC-CEDICT '邃古'; Guoyu '邃古')","h":"2"},
{"s":"围","t":"圍","p":"wéi","e": "to surround / to encircle / to corral","g":"verb","n":"(Unihan '圍')","h":"3"},
{"s":"玫瑰","t":"","p":"méiguī","e":"rose","g":"noun", "n":"Scientific name: Rosa rugosa (CC-CEDICT '玫瑰'; Guoyu '玫瑰' 1; Wikipedia '玫瑰')","h":"3492"},
{"s":"五蕴","t":"五蘊","p":"wǔ yùn","e":"five aggregates","g":"phrase", "n":"Sanskrit equivalent: pañcaskandha, Pāli: pañcakhandhā, Japanese: goun; the five skandhas are form 色, sensation 受, perception 想, volition 行, and consciousness 识 (FGDB '五蘊'; DJBT 'goun'; Tzu Chuang 2012; Nyanatiloka Thera 1980, 'khandha')","h":"5049"}]
""";

var cnSource = DictionarySource(1, 'cnotes.json', 'Chinese Notes',
    'Chinese Notes Chinese-English Dictionary', 'www.com');

// DictionaryLoader load a dictionary from some source.
class TestDictionaryLoader {
  /// fill in real implementation
  Future<DictionaryCollectionIndex> load() async {
    var chinese = '你好';
    var sense =
        Sense(-1, 42, chinese, '', 'níhǎo', 'hello', 'interjection', 'p. 655');
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
    var forwardIndex = dictFromJson(jsonString, cnSource);
    const headword = '邃古';
    var dictEntries = forwardIndex.lookup(headword);
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
  test('dictFromJson builds the index with traditional', () {
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var forwardIndex = dictFromJson(jsonString, cnSource);
    const simp = '围';
    const trad = '圍';
    var dictEntries = forwardIndex.lookup(trad);
    expect(dictEntries.entries.length, equals(1));
    var entry = dictEntries.entries.first;
    expect(entry.headword, equals(simp));
    for (var ent in dictEntries.entries) {
      var source = sources.lookup(ent.sourceId);
      expect(source.abbreviation, cnSource.abbreviation);
      expect(ent.senses.length, equals(1));
      for (var sense in ent.senses) {
        expect(sense.pinyin, 'wéi');
      }
    }
  });
  test('buildReverseIndex builds the reverse index correctly', () async {
    var loader = TestDictionaryLoader();
    var forwardIndex = await loader.load();
    var reverseIndex = buildReverseIndex(forwardIndex);
    const headword = '你好';
    const english = 'hello';
    var senses = reverseIndex.lookup(english);
    expect(senses.senses.length, equals(1));
    var sense = senses.senses.first;
    expect(sense.simplified, equals(headword));
  });
  test('NotesProcessor.parseNotes return equivalents in notes', () {
    const notes = 'Scientific name: Rosa rugosa (CC-CEDICT)';
    var np = NotesProcessor(notesPatterns);
    var equivalents = np.parseNotes(notes);
    expect(equivalents.length, equals(1));
    expect(equivalents[0], equals('Rosa rugosa'));
  });
  test(
      'NotesProcessor.parseNotes gets equivalents in notes with training comma',
      () {
    const notes = 'Sanskrit equivalent: pañcaskandha, xxx';
    var np = NotesProcessor(notesPatterns);
    var equivalents = np.parseNotes(notes);
    expect(equivalents.length, equals(1));
    expect(equivalents[0], equals('pañcaskandha'));
  });
  test('NotesProcessor.parseNotes gets equivalents with multiple commas', () {
    const notes = 'Sanskrit equivalent: pañcaskandha, Pāli: pañcakhandhā, xxx';
    var np = NotesProcessor(notesPatterns);
    var equivalents = np.parseNotes(notes);
    expect(equivalents.length, equals(2));
    expect(equivalents[0], equals('pañcaskandha'));
    expect(equivalents[1], equals('pañcakhandhā'));
  });
  test('App.lookup can find a word with a Chinese query', () async {
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var loader = TestDictionaryLoader();
    var forwardIndex = await loader.load();
    var reverseIndex = buildReverseIndex(forwardIndex);
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var app = App(forwardIndex, sources, reverseIndex, hwIDIndex);
    const query = '你好';
    const pinyin = 'níhǎo';
    var result = app.lookup(query);
    expect(result.terms.length, equals(1));
    for (var term in result.terms) {
      expect(term.queryText, equals(query));
      expect(term.entries.entries.length, equals(1));
      for (var entry in term.entries.entries) {
        expect(entry.headword, equals(query));
        expect(entry.pinyin, equals(pinyin));
      }
    }
  });
  test('App.lookup can find a word with an English query', () async {
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var loader = TestDictionaryLoader();
    var forwardIndex = await loader.load();
    var reverseIndex = buildReverseIndex(forwardIndex);
    var hwIDIndex = headwordsFromJson('[]', cnSource);
    var app = App(forwardIndex, sources, reverseIndex, hwIDIndex);
    const query = 'hello';
    const chinese = '你好';
    const pinyin = 'níhǎo';
    var result = app.lookup(query);
    //expect(result.terms.length, equals(1));
    for (var term in result.terms) {
      expect(term.queryText, equals(query));
      expect(term.senses.senses.length, equals(1));
      for (var sense in term.senses.senses) {
        expect(sense.simplified, equals(chinese));
        expect(sense.pinyin, equals(pinyin));
      }
    }
  });
  test('App.lookup English query reverse lookup with a stop word', () async {
    const sourceId = 1;
    var sources =
        DictionarySources(<int, DictionarySource>{sourceId: cnSource});
    var forwardIndex = dictFromJson(jsonString, cnSource);
    var reverseIndex = buildReverseIndex(forwardIndex);
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var app = App(forwardIndex, sources, reverseIndex, hwIDIndex);
    const query = 'encircle';
    const chinese = '围';
    var result = app.lookup(query);
    expect(result.terms.length, equals(1));
    for (var term in result.terms) {
      expect(term.queryText, equals(query));
      expect(term.senses.senses.length, equals(1));
      for (var sense in term.senses.senses) {
        expect(sense.simplified, equals(chinese));
        var source = app.getSource(sense.hwid);
        expect(source!.sourceId, equals(sourceId));
      }
    }
  });
  test('App.lookup can find a word from an equivalent in the notes', () async {
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var forwardIndex = dictFromJson(jsonString, cnSource);
    var reverseIndex = buildReverseIndex(forwardIndex);
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var app = App(forwardIndex, sources, reverseIndex, hwIDIndex);
    const query = 'Rosa rugosa';
    const simplified = '玫瑰';
    var result = app.lookup(query);
    expect(result.terms.length, equals(1));
    for (var term in result.terms) {
      expect(term.queryText, equals(query));
      expect(term.senses.senses.length, equals(1));
      for (var sense in term.senses.senses) {
        expect(sense.simplified, equals(simplified));
      }
    }
  });
}
