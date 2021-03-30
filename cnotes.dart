// A library to process Chinese text.

// The library lookup Chinese terms in dictionaries in both forward and reverse
// directions.
library chinesenotes;

import 'dart:convert';
import 'dart:io';

// App is a top level class that holds state of resources.
class App {
  final DictionaryCollection dictionaries;
  final DictionarySources sources;

  App(this.dictionaries, this.sources);
}

// DictionaryCollection is a collection of dictionaries for lookup of terms.
//
// The entries are indexed by Chinese headword.
class DictionaryCollection {
  final Map<String, DictionaryEntries> _entries;

  DictionaryCollection(this._entries);

  DictionaryEntries lookup(String key) {
    var dictEntries = _entries[key];
    if (dictEntries == null) {
      return DictionaryEntries(key, []);
    }
    return dictEntries;
  }
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
  final String url;
  final String abbreviation;
  final String title;
  final String citation;

  DictionarySource(
      this.sourceId, this.url, this.abbreviation, this.title, this.citation);
}

class DictionarySources {
  final Map<int, DictionarySource> _sources;

  DictionarySources(this._sources);

  DictionarySource lookup(int key) {
    var source = _sources[key];
    if (source == null) {
      // return DictionarySource(-1, '', '', '', '');
      throw Exception('dictionary source not found');
    }
    return source;
  }
}

// DictionaryLoader load a dictionary from some source.
class HttpDictionaryLoader implements DictionaryLoader {
  final DictionarySource source;

  HttpDictionaryLoader(this.source);

  /// fill in real implementation
  Future<DictionaryCollection> load() async {
    Map<String, DictionaryEntries> entryMap = {};
    HttpClient client = new HttpClient();
    try {
      client
          .getUrl(Uri.parse(this.source.url))
          .then((HttpClientRequest request) {
        return request.close();
      }).then((HttpClientResponse response) {
        response.transform(utf8.decoder).listen((contents) {
          List data = json.decode(contents) as List;
          for (var lu in data) {
            var hwid = lu['h'] as int;
            var s = lu['s'];
            var t = lu['t'];
            var p = lu['p'];
            var e = lu['e'];
            var g = lu['e'];
            var n = lu['n'];
            var sense = Sense(s, t, p, e, g, n);
            var entries = entryMap[s];
            if (entries == null) {
              var entry = DictionaryEntry(s, hwid, source.sourceId, [sense]);
              entryMap[s] = DictionaryEntries(s, [entry]);
            } else {
              entries.entries[0].senses.add(sense);
            }
          }
        });
      });
    } catch (ex) {
      rethrow;
    }
    return DictionaryCollection(entryMap);
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
  var cnSource = DictionarySource(
      1,
      'https://ntireader.org/dist/ntireader.json',
      'Chinese Notes',
      'Chinese Notes Chinese-English Dictionary',
      'https://github.com/alexamies/chinesenotes.com');
  var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
  var loader = HttpDictionaryLoader(cnSource);
  var dictionaries = await loader.load();
  var app = App(dictionaries, sources);
  var dictEntries = app.dictionaries.lookup('你好');
  for (var ent in dictEntries.entries) {
    var source = app.sources.lookup(ent.sourceId);
    print('Entry found for ${ent.headword} in source ${source.abbreviation}');
    print('Pinyin: ${ent.pinyin}');
  }
}
