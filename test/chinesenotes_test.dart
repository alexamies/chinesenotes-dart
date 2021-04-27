import 'package:test/test.dart';

import 'package:chinesenotes/chinesenotes.dart';

const jsonString = """
[{"s":"邃古","t":"","p":"suìgǔ","e": "remote antiquity","g":"noun","n":"(CC-CEDICT '邃古'; Guoyu '邃古')","h":"2"},
{"s":"围","t":"圍","p":"wéi","e": "to surround; to encircle; to corral","g":"verb","n":"(Unihan '圍')","h":"3"},
{"s":"欧洲","t":"歐洲","p":"ōuzhōu","e": "Europe","g":"proper noun","n":"Short form is 欧 (SDC 58; XHZD, p. 700)","h":"261"},
{"s":"欧","t":"歐","p":"ōu","e": "Europe","g":"proper noun","n":"Abbreviation for 欧洲 (Guoyu '歐' n 1)","h":"3681"},
{"s":"玫瑰","t":"","p":"méiguī","e":"rose","g":"noun", "n":"Scientific name: Rosa rugosa (CC-CEDICT '玫瑰'; Guoyu '玫瑰' 1; Wikipedia '玫瑰')","h":"3492"},
{"s":"五蕴","t":"五蘊","p":"wǔ yùn","e":"five aggregates","g":"phrase", "n":"Sanskrit equivalent: pañcaskandha, Pāli: pañcakhandhā; the five ...","h":"5049"},
{"s":"恐龙","t":"恐龍","p":"kǒnglóng","e":"dinosaur","g":"noun", "n":"Measure word: 头 (CC-CEDICT '恐龍')","h":"75439"},
{"s":"恐","t":"","p":"kǒng","e":"fear","g":"verb", "n":"In the sense of 害怕","h":"5084"}
]
""";

const jsonString2 = """
[{"s":"汲引高风","t":"汲引高風","p":"jí yǐn gāo fēng","e": "to imitate a person of lofty character","g":"phrase","n":"Reworded from Mathews 1931 '汲引高風', p. 62)","h":"3001251", "luid": "3001251"}]
""";

var cnSource = DictionarySource(
    1,
    'ntireader_words.json',
    'NTI Reader',
    'NTI Reader Chinese-English Dictionary',
    'https://github.com/alexamies/buddhist-dictionary',
    'Alex Amies',
    'Creative Commons Attribution-Share Alike 3.0',
    0);

// DictionaryLoader load a dictionary from some source.
class TestDictionaryLoader {
  /// fill in real implementation
  DictionaryCollectionIndex load() {
    var chinese = '你好';
    var sense =
        Sense(-1, 42, chinese, '', 'níhǎo', 'hello', 'interjection', 'p. 655');
    var senses = Senses([sense]);
    var entry = DictionaryEntry(chinese, 42, 1, {'níhǎo'}, senses);
    var entryList = DictionaryEntries(chinese, [entry]);
    var entries = <String, DictionaryEntries>{chinese: entryList};
    return DictionaryCollectionIndex(entries);
  }
}

void main() {
  test('DictionaryCollectionIndex.lookup finds a matching headword.', () {
    var loader = TestDictionaryLoader();
    var forwardIndex = loader.load();
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
      expect(ent.getSenses().length, equals(1));
      for (var sense in ent.getSenses().senses) {
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
      expect(ent.getSenses().length, equals(1));
      for (var sense in ent.getSenses().senses) {
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
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var app = App();
    app.buildApp([forwardIndex], [hwIDIndex], sources);
    const query = '你好';
    const pinyin = 'níhǎo';
    var result = app.lookup(query);
    expect(result.terms.length, equals(1));
    for (var term in result.terms) {
      expect(term.query, equals(query));
      expect(term.entries.entries.length, equals(1));
      for (var entry in term.entries.entries) {
        expect(entry.headword, equals(query));
        expect(entry.hwRollup, equals(query));
        expect(entry.pinyinRollup, equals(pinyin));
      }
    }
  });
  test('App.lookup can find a word with an English query', () async {
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var loader = TestDictionaryLoader();
    var forwardIndex = loader.load();
    var hwIDIndex = headwordsFromJson('[]', cnSource);
    var app = App();
    app.buildApp([forwardIndex], [hwIDIndex], sources);
    const query = 'hello';
    const chinese = '你好';
    const pinyin = 'níhǎo';
    var result = app.lookup(query);
    expect(result.terms.length, equals(1));
    var term = result.terms.first;
    expect(term.query, equals(query));
    expect(term.senses.senses.length, equals(1));
    for (var sense in term.senses.senses) {
      expect(sense.simplified, equals(chinese));
      expect(sense.pinyin, equals(pinyin));
    }
  });
  test('App.lookup works with mixed case', () async {
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var forwardIndex = dictFromJson(jsonString, cnSource);
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var app = App();
    app.buildApp([forwardIndex], [hwIDIndex], sources);
    const query = 'Europe';
    var result = app.lookup(query);
    //expect(result.terms.length, equals(1));
    for (var term in result.terms) {
      expect(term.query, equals(query));
      expect(term.senses.length, equals(2));
      for (var sense in term.senses.senses) {
        var gotOne = sense.simplified == '欧洲' || sense.simplified == '欧';
        expect(gotOne, equals(true));
      }
    }
  });
  test('App.lookup English query reverse lookup with a stop word', () async {
    const sourceId = 1;
    var sources =
        DictionarySources(<int, DictionarySource>{sourceId: cnSource});
    var forwardIndex = dictFromJson(jsonString, cnSource);
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var app = App();
    app.buildApp([forwardIndex], [hwIDIndex], sources);
    const query = 'encircle';
    const chinese = '围';
    var result = app.lookup(query);
    expect(result.terms.length, equals(1));
    for (var term in result.terms) {
      expect(term.query, equals(query));
      expect(term.senses.senses.length, equals(1));
      for (var sense in term.senses.senses) {
        expect(sense.simplified, equals(chinese));
        var source = app.getSource(sense.hwid);
        expect(source!.sourceId, equals(sourceId));
      }
    }
  });
  test('App.lookup can find a word from an equivalent in the notes', () {
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var forwardIndex = dictFromJson(jsonString, cnSource);
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var app = App();
    app.buildApp([forwardIndex], [hwIDIndex], sources);
    const query = 'Rosa rugosa';
    const simplified = '玫瑰';
    var result = app.lookup(query);
    expect(result.terms.length, equals(1));
    for (var term in result.terms) {
      expect(term.query, equals(query));
      expect(term.senses.senses.length, equals(1));
      for (var sense in term.senses.senses) {
        expect(sense.simplified, equals(simplified));
      }
    }
  });
  test('mergeDictionaries works as expected.', () {
    var loader = TestDictionaryLoader();
    var index1 = loader.load();
    var simplified = '再见';
    var sense = Sense(
        -2, 43, simplified, '再見', 'zàijiàn', 'goodbye', 'interjection', '');
    var senses = Senses([sense]);
    var entry = DictionaryEntry(simplified, 43, 2, {'zàijiàn'}, senses);
    var entryList = DictionaryEntries(simplified, [entry]);
    var entries = <String, DictionaryEntries>{simplified: entryList};
    var index2 = DictionaryCollectionIndex(entries);
    var indexes = [index1, index2];
    var mergedIndex = mergeDictionaries(indexes);
    expect(mergedIndex.entries.length, equals(2));
    var result = mergedIndex.lookup(simplified);
    expect(result.entries.length, equals(1));
    var first = result.entries.first;
    expect(first.headword, equals(simplified));
  });
  test('mergeHWIDIndexes works as expected.', () {
    var hwIDIndex1 = headwordsFromJson(jsonString, cnSource);
    var hwIDIndex2 = headwordsFromJson(jsonString2, cnSource);
    var indexes = [hwIDIndex1, hwIDIndex2];
    var mergedIndex = mergeHWIDIndexes(indexes);
    var entry = mergedIndex.entries[3001251]!;
    expect(entry.headword, equals('汲引高风'));
  });
  test('Sense == equals with same LUID and HWID.', () {
    var chinese = '你好';
    var hello1 =
        Sense(42, 42, chinese, '', 'níhǎo', 'hello', 'interjection', 'p. 655');
    var hello2 =
        Sense(42, 42, chinese, '', 'níhǎo', 'hello', 'interjection', 'p. 655');
    expect(hello1, equals(hello2));
  });
  test('Sense == not equals with different LUID and HWID.', () {
    var chinese = '你好';
    var hello1 =
        Sense(42, 42, chinese, '', 'níhǎo', 'hello', 'interjection', 'p. 655');
    var hello2 =
        Sense(43, 43, chinese, '', 'níhǎo', 'hello', 'interjection', 'p. 655');
    expect(hello1, isNot(hello2));
  });
  test('Sense == equivalent is equals with no LUID.', () {
    var chinese = '你好';
    var hello1 =
        Sense(-1, 42, chinese, '', 'níhǎo', 'hello', 'interjection', 'p. 655');
    var hello2 =
        Sense(-1, 43, chinese, '', 'níhǎo', 'hello', 'interjection', 'p. 655');
    expect(hello1, equals(hello2));
  });
  test('Sense == not equals with same LUID, different HWID.', () {
    var chinese = '你好';
    var hello1 =
        Sense(1, 42, chinese, '', 'níhǎo', 'hello', 'interjection', 'p. 655');
    var hello2 =
        Sense(1, 43, chinese, '', 'níhǎo', 'hello', 'interjection', 'p. 655');
    expect(hello1, isNot(hello2));
  });
  test('Sense.fromJson constructs a Sense object correctly.', () {
    var luid = 1;
    var hwid = 42;
    var simplified = '你好';
    var traditional = '';
    var pinyin = 'níhǎo';
    var english = 'hello';
    var grammar = 'interjection';
    var notes = 'p. 655';
    var obj = {
      'luid': luid,
      'hwid': hwid,
      'simplified': simplified,
      'traditional': traditional,
      'pinyin': pinyin,
      'english': english,
      'grammar': grammar,
      'notes': notes
    };
    var sense = Sense.fromJson(obj);
    var retObj = sense.toJson();
    expect(luid, retObj['luid']);
    expect(hwid, retObj['hwid']);
    expect(simplified, retObj['simplified']);
    expect(traditional, retObj['traditional']);
    expect(pinyin, retObj['pinyin']);
    expect(english, retObj['english']);
    expect(grammar, retObj['grammar']);
    expect(notes, retObj['notes']);
  });
  test('Senses.fromJson constructs a Senses object correctly.', () {
    var obj1 = {
      'luid': 1,
      'hwid': 42,
      'simplified': '你好',
      'traditional': '',
      'pinyin': 'níhǎo',
      'english': 'hello',
      'grammar': 'interjection',
      'notes': 'p. 655'
    };
    var obj2 = {
      'luid': 2,
      'hwid': 43,
      'simplified': '再见',
      'traditional': '再見',
      'pinyin': 'zàijiàn',
      'english': 'good bye',
      'grammar': 'interjection',
      'notes': 'p. 655'
    };
    var senseList = [obj1, obj2];
    var sensesObj = {'senses': senseList};
    var senses = Senses.fromJson(sensesObj);
    expect(
      senseList.length,
      senses.length,
    );
  });
  test('flattenPinyin with a string with no accents', () {
    const String nihao = 'nihao';
    var flat = flattenPinyin(nihao);
    expect(flat, equals(nihao));
  });
  test('flattenPinyin with an accents', () {
    const String ouzhou = 'Ōuzhōu';
    var flat = flattenPinyin(ouzhou);
    expect(flat, equals('ouzhou'));
  });
  test('tokenize with no dictionary entries', () {
    var loader = TestDictionaryLoader();
    var forwardIndex = loader.load();
    var tokenizer = DictTokenizer(forwardIndex);
    const String text = 'hello';
    var tokens = tokenizer.tokenize(text);
    expect(tokens.length, equals(text.length));
    expect(tokens.first.token, equals('h'));
  });
  test('tokenize a single Chinese character', () {
    var forwardIndex = dictFromJson(jsonString, cnSource);
    var tokenizer = DictTokenizer(forwardIndex);
    const String text = '围';
    var tokens = tokenizer.tokenize(text);
    expect(tokens.length, equals(text.length));
    expect(tokens.first.token, equals('围'));
    expect(tokens.first.entries.length, equals(1));
    expect(tokens.first.entries.first.pinyinRollup, equals('wéi'));
  });
  test('tokenize a zero-length string', () {
    var forwardIndex = dictFromJson(jsonString, cnSource);
    var tokenizer = DictTokenizer(forwardIndex);
    const String text = '';
    var tokens = tokenizer.tokenize(text);
    expect(tokens.length, equals(text.length));
  });
  test('tokenize a two-character Chinese word', () {
    var forwardIndex = dictFromJson(jsonString, cnSource);
    var tokenizer = DictTokenizer(forwardIndex);
    const String text = '歐洲';
    var tokens = tokenizer.tokenize(text);
    expect(tokens.length, equals(1));
    expect(tokens.first.token, equals('歐洲'));
    expect(tokens.first.entries.length, equals(1));
    expect(tokens.first.entries.first.pinyinRollup, equals('ōuzhōu'));
  });
  test('tokenize method picks the longest terms', () {
    var forwardIndex = dictFromJson(jsonString, cnSource);
    var tokenizer = DictTokenizer(forwardIndex);
    const String text = '恐龍';
    var tokens = tokenizer.tokenize(text);
    expect(tokens.length, equals(1));
    expect(tokens.first.token, equals('恐龍'));
    expect(tokens.first.entries.length, equals(1));
    expect(tokens.first.entries.first.pinyinRollup, equals('kǒnglóng'));
  });
  test('isCJKChar correctly identifies a non-Chinese character', () {
    expect(isCJKChar('ō'), equals(false));
  });
  test('isCJKChar correctly identifies a Chinese character', () {
    expect(isCJKChar('歐'), equals(true));
  });
}
