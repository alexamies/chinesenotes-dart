// A library to process Chinese text.

// The library lookup Chinese terms in dictionaries in both forward and reverse
// directions.
library chinesenotes;

import 'dart:convert';
import 'dart:io';

const separator = ' / ';

// App is a top level class that holds state of resources.
class App {
  final DictionaryCollectionIndex forrwardIndex;
  final DictionarySources sources;

  App(this.forrwardIndex, this.sources);
}

// Builds a reverse index from the given forward in dex.
DictionaryReverseIndex buildReverseIndex(
    DictionaryCollectionIndex forrwardIndex) {
  var revIndex = <String, Senses>{};
  var keys = forrwardIndex.keys();
  for (var hw in keys) {
    var e = forrwardIndex.lookup(hw);
    for (var entry in e.entries) {
      for (var sense in entry.senses) {
        var equivalents = sense.english.split(separator);
        for (var equiv in equivalents) {
          var ent = revIndex[equiv];
          if (ent == null) {
            revIndex[equiv] = Senses([sense]);
          } else {
            ent.senses.add(sense);
          }
        }
      }
    }
  }
  return DictionaryReverseIndex(revIndex);
}

// DictionaryCollection is a collection of dictionaries for lookup of terms.
//
// The entries are indexed by Chinese headword.
class DictionaryCollectionIndex {
  final Map<String, DictionaryEntries> _entries;

  DictionaryCollectionIndex(this._entries);

  Iterable<String> keys() {
    return _entries.keys;
  }

  /// Null safe lookup
  ///
  /// Return: the value or an empty list if there is no match found
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
  Future<DictionaryCollectionIndex> load();
}

// DictionaryReverseIndex indexes the dictionary by equivalent.
//
// The entries are indexed by Chinese headword.
class DictionaryReverseIndex {
  final Map<String, Senses> _senses;

  DictionaryReverseIndex(this._senses);

  /// Null safe lookup
  ///
  /// Return: the senses or an empty list if there is no match found
  Senses lookup(String key) {
    var senses = _senses[key];
    if (senses == null) {
      return Senses([]);
    }
    return senses;
  }
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

// HttpDictionaryLoader loads a dictionary from command line or a mobile client.
//
// This loader does not work from a browser.
class HttpDictionaryLoader implements DictionaryLoader {
  final DictionarySource source;

  HttpDictionaryLoader(this.source);

  /// fill in real implementation
  Future<DictionaryCollectionIndex> load() async {
    var jsonString = await _download(source.url);
    return dictFromJson(jsonString, source);
  }

  /// downloads the file from the given url
  Future<String> _download(String url) async {
    StringBuffer sb = StringBuffer();
    HttpClient client = new HttpClient();
    try {
      var request = await client.getUrl(Uri.parse(url));
      var response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('server error or not found');
      }
      await for (var contents in response.transform(Utf8Decoder())) {
        //print('Received ${contents.length} characters');
        sb.write(contents);
      }
    } catch (ex) {
      print('Could not load the dictionary ${source.title}');
      rethrow;
    }
    var s = sb.toString();
    print('Downloaded ${s.length} characters');
    return s;
  }
}

// Build a forward index by parsing a dictionary from a JSON string.
DictionaryCollectionIndex dictFromJson(
    String jsonString, DictionarySource source) {
  List data = json.decode(jsonString) as List;
  Map<String, DictionaryEntries> entryMap = {};
  for (var lu in data) {
    try {
      var h = lu['h'];
      var hwid = -1;
      if (h != null) {
        hwid = int.parse(h);
      } else {
        print('HW id is null for ${lu['s']}');
      }
      var s = '';
      if (lu['s'] != null) {
        s = lu['s'];
      }

      var t = '';
      if (lu['t'] != null) {
        t = lu['t'];
      }
      var p = '';
      if (lu['p'] != null) {
        p = lu['p'];
      }
      var e = '';
      if (lu['e'] != null) {
        e = lu['e'];
      }
      var g = '';
      if (lu['g'] != null) {
        g = lu['g'];
      }
      var n = '';
      if (lu['n'] != null) {
        n = lu['n'];
      }
      var sense = Sense(s, t, p, e, g, n);
      var entries = entryMap[s];
      if (entries == null) {
        var entry = DictionaryEntry(s, hwid, source.sourceId, [sense]);
        entryMap[s] = DictionaryEntries(s, [entry]);
      } else {
        entries.entries[0].senses.add(sense);
      }
    } catch (ex) {
      print('Could not load parse entry ${lu['h']}, ${lu['s']}: $ex');
      rethrow;
    }
  }
  print('Loaded ${entryMap.length} entries');
  return DictionaryCollectionIndex(entryMap);
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

// Senses is a list of word senses.
class Senses {
  final List<Sense> senses;

  Senses(this.senses);
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
  var dictEntries = app.forrwardIndex.lookup('你好');
  for (var ent in dictEntries.entries) {
    var source = app.sources.lookup(ent.sourceId);
    print('Entry found for ${ent.headword} in source ${source.abbreviation}');
    print('Pinyin: ${ent.pinyin}');
  }
}
