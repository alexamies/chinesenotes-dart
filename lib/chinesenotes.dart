/// A library to process Chinese text.
///
/// The library lookups Chinese terms in dictionaries in both forward and
/// reverse directions.
library chinesenotes;

import 'dart:convert';

const ntiReaderJson = 'https://ntireader.org/dist/ntireader.json';
const cnotesJson = 'https://chinesenotes.com/dist/ntireader.json';
const separator = ' / ';
const stopWords = ['a ', 'an ', 'to '];
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
  final DictionaryReverseIndex reverseIndex;
  final HeadwordIDIndex hwIDIndex;

  App(this.forrwardIndex, this.sources, this.reverseIndex, this.hwIDIndex);

  QueryResults lookup(String query) {
    var entries = forrwardIndex.lookup(query);
    var senses = reverseIndex.lookup(query);
    var term = Term(query, entries, senses);
    return QueryResults([term]);
  }

  DictionarySource? getSource(int hwID) {
    var sourceId = hwIDIndex.entries[hwID]?.sourceId;
    return sources.lookup(sourceId!);
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
  Map<String, Senses> revIndex = {};
  void addSenses(List<String> equivalents, Sense sense) {
    for (var equiv in equivalents) {
      var ent = revIndex[equiv];
      if (ent == null) {
        revIndex[equiv] = Senses([sense]);
      } else if (!ent.senses.contains(sense)) {
        ent.senses.add(sense);
      }
    }
  }

  List<String> removeStopWords(List<String> equivalents) {
    List<String> cleaned = [];
    for (var equiv in equivalents) {
      var clean = equiv;
      for (var sw in stopWords) {
        clean = clean.replaceAll(sw, '');
      }
      cleaned.add(clean);
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
        addSenses(cleaned, sense);
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

  int get length {
    return entries.length;
  }
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

  final List<Sense> senses;

  DictionaryEntry(this.headword, this.headwordId, this.sourceId, this.senses);

  /// A rollup of simplified, traditional, and variant forms of the headword
  ///
  /// The headword may have simplified, traditional, and variant forms. For
  /// example, 围 (圍).
  String get hwRollup {
    var variants = <String, bool>{};
    for (var sense in senses) {
      if (sense.traditional != '') {
        variants[sense.traditional] = true;
      }
    }
    var rollup = variants.isEmpty ? '' : variants.keys.join('、').trim();
    ;
    return rollup == '' ? headword : '$headword （$rollup）';
  }

  /// Rolls up different writings of Hanyun pinyin from all senses
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
  final String author;
  final String license;

  DictionarySource(this.sourceId, this.url, this.abbreviation, this.title,
      this.citation, this.author, this.license);
}

/// The identity of a dictionary source, how to download it, and a citation.
class DictionarySources {
  final Map<int, DictionarySource> sources;

  DictionarySources(this.sources);

  DictionarySource lookup(int key) {
    var source = sources[key];
    if (source == null) {
      throw Exception('dictionary source not found');
    }
    return source;
  }
}

/// Build a forward index by parsing a dictionary from a JSON string.
///
/// Indended for the Chinese Notes and NTI Reader native dictionary structure
DictionaryCollectionIndex dictFromJson(
    String jsonString, DictionarySource source) {
  List data = json.decode(jsonString) as List;
  Map<String, DictionaryEntries> entryMap = {};
  for (var lu in data) {
    try {
      var luid = (lu['luid'] != null) ? int.parse(lu['luid']) : -1;
      var hwid = (lu['h'] != null) ? int.parse(lu['h']) : -1;
      var s = lu['s'] ?? '';
      var t = lu['t'] ?? '';
      var p = lu['p'] ?? '';
      var e = lu['e'] ?? '';
      var g = lu['g'] ?? '';
      var n = lu['n'] ?? '';
      var sense = Sense(luid, hwid, s, t, p, e, g, n);
      var entries = entryMap[s];
      if (entries == null || entries.length == 0) {
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

/// Build a forward index by parsing a dictionary from a JSON string.
///
/// Indended for the Chinese Notes and NTI Reader native dictionary structure
HeadwordIDIndex headwordsFromJson(String jsonString, DictionarySource source) {
  List data = json.decode(jsonString) as List;
  Map<int, DictionaryEntry> entryMap = {};
  for (var lu in data) {
    try {
      var luid = (lu['luid'] != null) ? int.parse(lu['luid']) : -1;
      var hwid = (lu['h'] != null) ? int.parse(lu['h']) : -1;
      var s = lu['s'] ?? '';
      var t = lu['t'] ?? '';
      var p = lu['p'] ?? '';
      var e = lu['e'] ?? '';
      var g = lu['g'] ?? '';
      var n = lu['n'] ?? '';
      var sense = Sense(luid, hwid, s, t, p, e, g, n);
      var entry = entryMap[s];
      if (entry == null) {
        entryMap[hwid] = DictionaryEntry(s, hwid, source.sourceId, [sense]);
      } else {
        entry.senses.add(sense);
      }
      if (t != '') {
        var entry = entryMap[t];
        if (entry == null) {
          entryMap[hwid] = DictionaryEntry(s, hwid, source.sourceId, [sense]);
        } else {
          entry.senses.add(sense);
        }
      }
    } on Exception catch (ex) {
      print('Could not load parse entry ${lu['h']}, ${lu['s']}: $ex');
      rethrow;
    }
  }
  print('Loaded ${entryMap.length} headwords');
  return HeadwordIDIndex(entryMap);
}

/// HeadwordIDIndex indexes the dictionary by headword ID.
///
/// A headword ID uniquely identifies a dictionary entry with a specific source.
class HeadwordIDIndex {
  final Map<int, DictionaryEntry> entries;

  HeadwordIDIndex(this.entries);
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
  /// Lexical unit ID, uniquely identifies the word sense in a dictionary
  final int luid;

  /// Headword ID, uniquely determines the headword in a specific dictionary
  final int hwid;

  /// The simplified Chinese form
  final String simplified;

  /// The traditional Chinese, form or empty string if the same as simplified
  final String traditional;

  /// The Hanyu pinyin pronunciation of the sense
  final String pinyin;

  /// A delimited set of English equivalents
  final String english;

  /// Part of speech
  final String grammar;

  /// Notes, including citations
  final String notes;

  Sense(this.luid, this.hwid, this.simplified, this.traditional, this.pinyin,
      this.english, this.grammar, this.notes);

  @override
  bool operator ==(dynamic other) {
    return other is Sense && other.english == english;
  }

  // Combines simplified and traditional if they differe, eg 围 (圍)
  String get chinese {
    if (traditional == '' || simplified == traditional) {
      return simplified;
    }
    return '$simplified （$traditional）';
  }
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
