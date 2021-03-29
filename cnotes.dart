// A library to process Chinese text.

// The library lookup Chinese terms in dictionaries in both forward and reverse
// directions.
library chinesenotes;

// DictionaryCollection is a collection of dictionaries for lookup of terms.
//
// The entries are indexed by Chinese headword.
class DictionaryCollection {
  final Map<String, DictionaryEntries> entries;

  DictionaryCollection(this.entries);
}

// DictionaryEntries is a list of dictionary entries with the same headword.
//
// Each DictionaryEntry object should be from a different source
class DictionaryEntries {
  /// All sense of an entry should have the same headword.
  ///
  /// The headword is how the term would appear in a document.
  final String headword;
  final List<DictionaryEntry> entries;

  DictionaryEntries(this.headword, this.entries);
}

// DictionaryEntry is an entry for a term in a Chinese-English dictionary.
class DictionaryEntry {
  /// All sense of an entry should have the same headword.
  ///
  /// The headword is how the term would appear in a document.
  final String headword;

  /// A headwordId is an numeric identifier for the entry in a source.
  ///
  /// Different sources may have different values for headwordId.
  final int headwordId;

  /// The sourceId identifies the origin of the entry.
  final int sourceId;

  List<Sense> senses;

  DictionaryEntry(this.headword, this.headwordId, this.sourceId, this.senses);

  // Rolls up Hanyun pinyin from all senses
  String get pinyin {
    var values = <String, bool>{};
    for (var s in senses) {
      values[s.pinyin] = true;
    }
    return values.keys.join(' ').trim();
  }
}

// DictionaryLoader load a dictionary from some source.
abstract class DictionaryLoader {
  Future<DictionaryCollection> load();
}

// DictionarySource is a collection of dictionary entries from a single source.
class DictionarySource {
  final int sourceId;
  final String filename;
  final String abbreviation;
  final String title;
  final String citation;

  DictionarySource(this.sourceId, this.filename, this.abbreviation, this.title,
      this.citation);
}

class DictionarySources {
  final Map<int, DictionarySource> sources;

  DictionarySources(this.sources);
}

Future<DictionarySources> loadDictionarySources() async {
  var cnSource = DictionarySource(1, 'cnotes.json', 'Chinese Notes',
      'Chinese Notes Chinese-English Dictionary', 'www.com');
  var sources = <int, DictionarySource>{1: cnSource};
  return DictionarySources(sources);
}

// DictionaryLoader load a dictionary from some source.
class HttpDictionaryLoader implements DictionaryLoader {
  final String url;

  HttpDictionaryLoader(this.url);

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

// Sense is the meaning of a dictionary entry.
class Sense {
  final String simplified;
  final String traditional;
  final String pinyin;
  final String english;
  final String grammar;
  final String notes;

  Sense(this.simplified, this.traditional, this.pinyin, this.english,
      this.grammar, this.notes);
}

void main() async {
  var sources = await loadDictionarySources();
  var loader = HttpDictionaryLoader('abc');
  var future = loader.load();
  future.then((DictionaryCollection dictionaries) {
    var dictEntries = dictionaries.entries['你好'];
    for (var ent in dictEntries.entries) {
      var source = sources.sources[ent.sourceId];
      print('Entry found for ${ent.headword} in source ${source.abbreviation}');
      print('Pinyin: ${ent.pinyin}');
    }
  });
}
