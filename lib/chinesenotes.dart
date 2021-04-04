/// A library to process Chinese text.
///
/// The library lookups Chinese terms in dictionaries in both forward and
/// reverse directions.
library chinesenotes;

import 'dart:convert';

const ntiReaderJson = 'https://ntireader.org/dist/ntireader.json';
const cnotesJson = 'https://chinesenotes.com/dist/ntireader.json';
const separator = ' / ';
const notesPatterns = [
  r'Scientific name: (.+?)(\(|,|;)',
  r'Sanskrit equivalent: (.+?)(\(|,|;)',
  r'Pāli: (.+?)(\(|,|;)',
  r'Pali: (.+?)(\(|,|;)',
  r'Japanese: (.+?)(\(|,|;)',
  r'Tibetan: (.+?)(\(|,|;)'
];

/// App is a top level class that holds state of resources.
class App {
  final DictionaryCollectionIndex forrwardIndex;
  final DictionarySources sources;
  DictionaryReverseIndex reverseIndex;

  App(this.forrwardIndex, this.sources, this.reverseIndex);

  QueryResults lookup(String query) {
    var entries = forrwardIndex.lookup(query);
    var senses = reverseIndex.lookup(query);
    var term = Term(query, entries, senses);
    return QueryResults([term]);
  }
}

/// Builds a reverse index from the given forward index.
///
/// The keys of the reserse index will be the equivalents in English and
/// possibly other languages contained in the notes field.
///
/// Params:
///   forrwardIndex - containing the dictionary entries
///   np - to extract secondary equivalents contained in notes
DictionaryReverseIndex buildReverseIndex(
    DictionaryCollectionIndex forrwardIndex) {
  var np = NotesProcessor(notesPatterns);
  var revIndex = <String, Senses>{};
  void addSenses(List<String> equivalents, Sense sense) {
    for (var equiv in equivalents) {
      print('Adding equiv: $equiv');
      var ent = revIndex[equiv];
      if (ent == null) {
        revIndex[equiv] = Senses([sense]);
      } else {
        ent.senses.add(sense);
      }
    }
  }

  List<String> removeStopWords(List<String> equivalents) {
    List<String> cleaned = [];
    for (var equiv in equivalents) {
      var s = equiv.replaceAll('a ', '');
      cleaned.add(s);
    }
    return cleaned;
  }

  var keys = forrwardIndex.keys();
  for (var hw in keys) {
    var e = forrwardIndex.lookup(hw);
    for (var entry in e.entries) {
      for (var sense in entry.senses) {
        var equivalents = sense.english.split(separator);
        var cleaned = removeStopWords(equivalents);
        addSenses(equivalents, sense);
        var notesEquiv = np.parseNotes(sense.notes);
        addSenses(notesEquiv, sense);
      }
    }
  }
  return DictionaryReverseIndex(revIndex);
}

/// DictionaryCollection is a collection of dictionaries for lookup of terms.
///
/// The entries are indexed by Chinese headword.
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

/// DictionaryEntries is a list of dictionary entries with the same headword.
///
/// Each DictionaryEntry object should be from a different source
class DictionaryEntries {
  /// All sense of an entry should have the same headword.
  ///
  /// The headword is how the term would appear in a document.
  final String headword;
  final List<DictionaryEntry> entries;

  DictionaryEntries(this.headword, this.entries);
}

/// DictionaryEntry is an entry for a term in a Chinese-English dictionary.
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

  /// Rolls up Hanyun pinyin from all senses
  String get pinyin {
    var values = <String, bool>{};
    for (var s in senses) {
      values[s.pinyin] = true;
    }
    return values.keys.join(' ').trim();
  }
}

/// DictionaryReverseIndex indexes the dictionary by equivalent.
///
/// The entries are indexed by Senses, which is part of a Chinese headword.
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

/// DictionarySource is a collection of dictionary entries from a single source.
class DictionarySource {
  final int sourceId;
  final String url;
  final String abbreviation;
  final String title;
  final String citation;

  DictionarySource(
      this.sourceId, this.url, this.abbreviation, this.title, this.citation);
}

/// The identity of a dictionary source, how to download it, and a citation.
class DictionarySources {
  final Map<int, DictionarySource> _sources;

  DictionarySources(this._sources);

  DictionarySource lookup(int key) {
    var source = _sources[key];
    if (source == null) {
      throw Exception('dictionary source not found');
    }
    return source;
  }
}

/// Build a forward index by parsing a dictionary from a JSON string.
DictionaryCollectionIndex dictFromJson(
    String jsonString, DictionarySource source) {
  List data = json.decode(jsonString) as List;
  Map<String, DictionaryEntries> entryMap = {};
  for (var lu in data) {
    try {
      var hwid = (lu['h'] == null) ? int.parse(lu['h']) : -1;
      var s = lu['s'] ?? '';
      var t = lu['t'] ?? '';
      var p = lu['p'] ?? '';
      var e = lu['e'] ?? '';
      var g = lu['g'] ?? '';
      var n = lu['n'] ?? '';
      var sense = Sense(s, t, p, e, g, n);
      var entries = entryMap[s];
      if (entries == null) {
        var entry = DictionaryEntry(s, hwid, source.sourceId, [sense]);
        entryMap[s] = DictionaryEntries(s, [entry]);
      } else {
        entries.entries[0].senses.add(sense);
      }
      if (t != '') {
        var entries = entryMap[t];
        if (entries == null) {
          var entry = DictionaryEntry(s, hwid, source.sourceId, [sense]);
          entryMap[t] = DictionaryEntries(t, [entry]);
        } else {
          entries.entries[0].senses.add(sense);
        }
      }
    } on Exception catch (ex) {
      print('Could not load parse entry ${lu['h']}, ${lu['s']}: $ex');
      rethrow;
    }
  }
  print('Loaded ${entryMap.length} entries');
  return DictionaryCollectionIndex(entryMap);
}

/// NotesProcessor processes notes in dictonary entries.
///
/// The Chinese Notes dictionary adds addition equivalents in the notes field.
/// For example,
/// Scientific name: Rosa rugosa
class NotesProcessor {
  List<RegExp> _exp;

  NotesProcessor(List<String> patterns) : _exp = [] {
    for (var pattern in patterns) {
      _exp.add(RegExp(pattern, unicode: true));
    }
  }

  /// Process the notes field for patterns.
  ///
  /// Params:
  ///   notes - the notes field to process
  ///   pattern - the pattern to match on
  /// Return: pattern matces from the first group in each match
  List<String> parseNotes(String notes) {
    List<String> matches = [];
    for (var exp in _exp) {
      var reMatch = exp.firstMatch(notes);
      if (reMatch != null) {
        matches.add(reMatch[1]!.trim());
      }
    }
    return matches;
  }
}

/// Contains the result of a lookup checking both forward and reverse indexes.
class QueryResults {
  List<Term> terms;

  QueryResults(this.terms);
}

/// Sense is the meaning of a dictionary entry.
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

/// Senses is a list of word senses.
class Senses {
  final List<Sense> senses;

  Senses(this.senses);
}

/// A Term contains the QueryText searched for and possibly a matching
/// dictionary entry. There will only be matching dictionary entries for
/// Chinese words in the dictionary. For reverse lookups with non-Chinese text,
/// Chinese words will have nil DictEntry values and matching values will be
/// included in the Senses field.
class Term {
  String queryText;
  DictionaryEntries entries;
  Senses senses;

  Term(this.queryText, this.entries, this.senses);
}
