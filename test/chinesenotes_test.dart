import 'package:test/test.dart';

import 'package:chinesenotes/chinesenotes.dart';

const jsonString = """
[{"s":"邃古","t":"","p":"suìgǔ","e": "remote antiquity","g":"noun","n":"(CC-CEDICT '邃古'; Guoyu '邃古')","h":2},
{"s":"围","t":"圍","p":"wéi","e": "to surround; to encircle; to corral","g":"verb","n":"(Unihan '圍')","h":3},
{"s":"围","t":"圍","p":"wéi","e": "a defensive wall","g":"noun","n":"Guoyu '圍' n 4)","h":3},
{"s":"欧洲","t":"歐洲","p":"ōuzhōu","e": "Europe","g":"proper noun","n":"Short form is 欧 (SDC 58; XHZD, p. 700)","h":261},
{"s":"欧","t":"歐","p":"ōu","e": "Europe","g":"proper noun","n":"Abbreviation for 欧洲 (Guoyu '歐' n 1)","h":3681},
{"s":"玫瑰","t":"","p":"méiguī","e":"rose","g":"noun", "n":"Scientific name: Rosa rugosa (CC-CEDICT '玫瑰'; Guoyu '玫瑰' 1; Wikipedia '玫瑰')","h":3492},
{"s":"五蕴","t":"五蘊","p":"wǔ yùn","e":"five aggregates","g":"phrase", "n":"Sanskrit equivalent: pañcaskandha, Pāli: pañcakhandhā; the five ...","h":5049},
{"s":"恐龙","t":"恐龍","p":"kǒnglóng","e":"dinosaur","g":"noun", "n":"Measure word: 头 (CC-CEDICT '恐龍')","h":75439},
{"s":"恐","t":"","p":"kǒng","e":"fear","g":"verb", "n":"In the sense of 害怕","h":5084}
]
""";

const jsonString2 = """
[{"s":"汲引高风","t":"汲引高風","p":"jí yǐn gāo fēng","e": "to imitate a person of lofty character","g":"phrase","n":"Reworded from Mathews 1931 '汲引高風', p. 62)","h":3001251, "luid": 3001251}]
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
  var chinese = '你好';
  var senses = Senses([
    Sense(1, 42, '你好', '', 'níhǎo', 'nihao', 'hello', 'interjection', 'p. 655')
  ]);

  /// fill in real implementation
  ForwardIndex load() {
    Map<String, Set<int>> entries = {
      chinese: {42}
    };
    return ForwardIndex(entries);
  }

  HeadwordIDIndex getHeadwordIDIndex() {
    var entry = DictionaryEntry(chinese, 42, 1, {'níhǎo'}, {'nihao'}, senses);
    var hIndex = {42: entry};
    return HeadwordIDIndex(hIndex);
  }
}

void main() {
  test('Forward.lookup finds a matching headword.', () {
    var loader = TestDictionaryLoader();
    var forwardIndex = loader.load();
    var hwIdIndex = loader.getHeadwordIDIndex();
    const headword = '你好';
    var dictEntries = forwardIndex.lookup(hwIdIndex, headword);
    expect(dictEntries.entries.length, equals(1));
    var entry = dictEntries.entries.first;
    expect(entry.headword, equals(headword));
  });
  test('headwordsFromJson builds the index correctly', () {
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var forwardIndex = ForwardIndex.fromHWIndex(hwIDIndex);
    const headword = '邃古';
    var dictEntries = forwardIndex.lookup(hwIDIndex, headword);
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
  test('headwordsFromJson builds the index with traditional', () {
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var forwardIndex = ForwardIndex.fromHWIndex(hwIDIndex);
    const simp = '围';
    const trad = '圍';
    var dictEntries = forwardIndex.lookup(hwIDIndex, trad);
    expect(dictEntries.entries.length, equals(1));
    var entry = dictEntries.entries.first;
    expect(entry.headword, equals(simp));
    for (var ent in dictEntries.entries) {
      var source = sources.lookup(ent.sourceId);
      expect(source.abbreviation, cnSource.abbreviation);
      expect(ent.getSenses().length, equals(2));
      for (var sense in ent.getSenses().senses) {
        expect(sense.pinyin, 'wéi');
      }
    }
  });
  test('buildReverseIndex builds the reverse index correctly', () async {
    var loader = TestDictionaryLoader();
    var forwardIndex = await loader.load();
    var hwIndex = loader.getHeadwordIDIndex();
    var reverseIndex = buildReverseIndex(hwIndex, true);
    const headword = '你好';
    const english = 'hello';
    var senses = reverseIndex.lookup(english);
    expect(senses.length, equals(1));
    var rEntry = senses.first;
    var entries = forwardIndex.lookup(hwIndex, headword);
    var entry = entries.entries.first;
    expect(rEntry.luid, equals(entry.getSenses().senses.first.luid));
    expect(rEntry.hwid, equals(entry.headwordId));
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
    var hwIDIndex = loader.getHeadwordIDIndex();
    var app = App();
    app.buildApp([hwIDIndex], sources, false);
    const query = '你好';
    const pinyin = 'níhǎo';
    var result = await app.lookup(query);
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
    var hwIDIndex = loader.getHeadwordIDIndex();
    var app = App();
    app.buildApp([hwIDIndex], sources, true);
    const query = 'hello';
    const chinese = '你好';
    const pinyin = 'níhǎo';
    var result = await app.lookup(query);
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
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var app = App();
    app.buildApp([hwIDIndex], sources, true);
    const query = 'Europe';
    var result = await app.lookup(query);
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
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var app = App();
    app.buildApp([hwIDIndex], sources, true);
    const query = 'encircle';
    const chinese = '围';
    var result = await app.lookup(query);
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
  test('App.lookup can find a word from an equivalent in the notes', () async {
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var app = App();
    const query = 'Rosa rugosa';
    const simplified = '玫瑰';
    app.buildApp([hwIDIndex], sources, true);
    var result = await app.lookup(query);
    expect(result.terms.length, equals(1));
    for (var term in result.terms) {
      expect(term.query, equals(query));
      expect(term.senses.senses.length, equals(1));
      for (var sense in term.senses.senses) {
        expect(sense.simplified, equals(simplified));
      }
    }
  });
  test('App.lookup waits for the index to build', () async {
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var app = App();
    const query = '你好';
    const pinyin = 'níhǎo';
    var rFuture = app.lookup(query);
    app.buildApp([hwIDIndex], sources, true);
    rFuture.then((QueryResults result) {
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
  });
  test('Sense == equals with same LUID and HWID.', () {
    var chinese = '你好';
    var hello1 = Sense(42, 42, chinese, '', 'níhǎo', 'nihao', 'hello',
        'interjection', 'p. 655');
    var hello2 = Sense(42, 42, chinese, '', 'níhǎo', 'nihao', 'hello',
        'interjection', 'p. 655');
    expect(hello1, equals(hello2));
  });
  test('Sense == not equals with different LUID and HWID.', () {
    var chinese = '你好';
    var hello1 = Sense(42, 42, chinese, '', 'níhǎo', 'nihao', 'hello',
        'interjection', 'p. 655');
    var hello2 = Sense(43, 43, chinese, '', 'níhǎo', 'nihao', 'hello',
        'interjection', 'p. 655');
    expect(hello1, isNot(hello2));
  });
  test('Sense == equivalent is equals with no LUID.', () {
    var chinese = '你好';
    var hello1 = Sense(-1, 42, chinese, '', 'níhǎo', 'nihao', 'hello',
        'interjection', 'p. 655');
    var hello2 = Sense(-1, 43, chinese, '', 'níhǎo', 'nihao', 'hello',
        'interjection', 'p. 655');
    expect(hello1, equals(hello2));
  });
  test('Sense == not equals with same LUID, different HWID.', () {
    var chinese = '你好';
    var hello1 = Sense(1, 42, chinese, '', 'níhǎo', 'nihao', 'hello',
        'interjection', 'p. 655');
    var hello2 = Sense(1, 43, chinese, '', 'níhǎo', 'nihao', 'hello',
        'interjection', 'p. 655');
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
    var hwIDIndex = loader.getHeadwordIDIndex();
    var tokenizer = DictTokenizer(forwardIndex, hwIDIndex);
    const String text = 'hello';
    var tokens = tokenizer.tokenize(text);
    expect(tokens.length, equals(1));
    expect(tokens.first.token, equals('hello'));
  });
  test('tokenize a single Chinese character', () {
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var forwardIndex = ForwardIndex.fromHWIndex(hwIDIndex);
    var tokenizer = DictTokenizer(forwardIndex, hwIDIndex);
    const String text = '围';
    var tokens = tokenizer.tokenize(text);
    expect(tokens.length, equals(text.length));
    expect(tokens.first.token, equals('围'));
    expect(tokens.first.entries.length, equals(1));
    expect(tokens.first.entries.first.pinyinRollup, equals('wéi'));
  });
  test('tokenize a zero-length string', () {
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var forwardIndex = ForwardIndex.fromHWIndex(hwIDIndex);
    var tokenizer = DictTokenizer(forwardIndex, hwIDIndex);
    const String text = '';
    var tokens = tokenizer.tokenize(text);
    expect(tokens.length, equals(text.length));
  });
  test('tokenize a two-character Chinese word', () {
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var forwardIndex = ForwardIndex.fromHWIndex(hwIDIndex);
    var tokenizer = DictTokenizer(forwardIndex, hwIDIndex);
    const String text = '歐洲';
    var tokens = tokenizer.tokenize(text);
    expect(tokens.length, equals(1));
    expect(tokens.first.token, equals('歐洲'));
    expect(tokens.first.entries.length, equals(1));
    expect(tokens.first.entries.first.pinyinRollup, equals('ōuzhōu'));
  });
  test('tokenize method picks the longest terms', () {
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var forwardIndex = ForwardIndex.fromHWIndex(hwIDIndex);
    var tokenizer = DictTokenizer(forwardIndex, hwIDIndex);
    const String text = '恐龍';
    var tokens = tokenizer.tokenize(text);
    expect(tokens.length, equals(1));
    expect(tokens.first.token, equals('恐龍'));
    expect(tokens.first.entries.length, equals(1));
    expect(tokens.first.entries.first.pinyinRollup, equals('kǒnglóng'));
  });
  test('tokenize with a mixture of Chinese and non-Chinese', () {
    var hwIDIndex = headwordsFromJson(jsonString, cnSource);
    var forwardIndex = ForwardIndex.fromHWIndex(hwIDIndex);
    var tokenizer = DictTokenizer(forwardIndex, hwIDIndex);
    const String text = '恐龍Dinosaur';
    var tokens = tokenizer.tokenize(text);
    expect(tokens.length, equals(2));
    expect(tokens.first.token, equals('恐龍'));
    expect(tokens.first.entries.length, equals(1));
    expect(tokens[1].token, equals('Dinosaur'));
  });
  test('isCJKChar correctly identifies a non-Chinese character', () {
    expect(isCJKChar('ō'), equals(false));
  });
  test('isCJKChar correctly identifies a Chinese character', () {
    expect(isCJKChar('歐'), equals(true));
  });
  test('_normalizeQuery correctly lower cases a query string', () {
    expect(normalizeQuery('Mary O’Malley'), equals('mary o\'malley'));
  });
}
