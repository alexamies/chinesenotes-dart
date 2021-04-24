/// A library to process Chinese text.
///
/// The library lookups Chinese terms in dictionaries in both forward and
/// reverse directions.
library chinesenotes;

import 'dart:convert';

const separator = '; ';
const stopWords = ['a ', 'an ', 'to ', 'the '];
const notesPatterns = [
  r'Scientific name: (.+?)(\(|,|;)',
  r'Sanskrit equivalent: (.+?)(\(|,|;)',
  r'Pāli: (.+?)(\(|,|;)',
  r'Pali: (.+?)(\(|,|;)',
  r'Japanese: (.+?)(\(|,|;)',
  r'Tibetan: (.+?)(\(|,|;)',
  r'or: (.+?)(\(|,|;)'
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
    var queryLower = query.toLowerCase();
    var senses = reverseIndex.lookup(queryLower);
    var term = Term(query, entries, senses);
    Map<int, String> sourceAbbrev = {};
    for (var sense in senses.senses) {
      var entry = hwIDIndex.entries[sense.hwid];
      if (entry != null) {
        var source = sources.lookup(entry.sourceId);
        sourceAbbrev[sense.hwid] = source.abbreviation;
      }
    }
    for (var entry in entries.entries) {
      var source = sources.lookup(entry.sourceId);
      sourceAbbrev[entry.headwordId] = source.abbreviation;
    }
    return QueryResults(query, [term], sourceAbbrev);
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
        var equivLower = equiv.toLowerCase();
        revIndex[equivLower] = Senses([sense]);
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
      for (var sense in entry.getSenses().senses) {
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
  final Map<String, DictionaryEntries> entries;

  DictionaryCollectionIndex(this.entries);

  Iterable<String> keys() {
    return entries.keys;
  }

  /// Null safe lookup
  ///
  /// Return: the value or an empty list if there is no match found
  DictionaryEntries lookup(String key) {
    var dictEntries = entries[key];
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

  DictionaryEntries.fromJson(var obj)
      : headword = obj['headword'],
        entries = [] {
    var entriesObj = obj['entries'];
    if (entriesObj is! List) {
      return;
    }
    List entriesArray = entriesObj;
    for (var entryObj in entriesArray) {
      var entry = DictionaryEntry.fromJson(entryObj);
      entries.add(entry);
    }
  }

  int get length {
    return entries.length;
  }

  Map toJson() {
    var entriesObj = [];
    for (var entry in entries) {
      entriesObj.add(entry.toJson());
    }
    return {'headword': headword, 'entries': entriesObj};
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

  /// Rolls up different writings of Hanyun pinyin from all senses
  final Set<String> pinyin;

  final Senses _senses;

  DictionaryEntry(
      this.headword, this.headwordId, this.sourceId, this.pinyin, this._senses);

  DictionaryEntry.fromJson(var obj)
      : headword = obj['headword'],
        headwordId = obj['headwordId'],
        sourceId = obj['sourceId'],
        pinyin = {},
        _senses = Senses.fromJson(obj['senses']) {
    var pinyinObj = obj['sourceId'];
    if (pinyinObj is! String) {
      return;
    }
    var tokens = pinyinObj.split(',');
    pinyin.addAll(tokens);
  }

  void addSense(Sense sense) {
    pinyin.add(sense.pinyin);
    _senses.add(sense);
  }

  Senses getSenses() {
    return _senses;
  }

  /// A rollup of simplified, traditional, and variant forms of the headword
  ///
  /// The headword may have simplified, traditional, and variant forms. For
  /// example, 围 (圍).
  String get hwRollup {
    var variants = <String, bool>{};
    for (var sense in _senses.senses) {
      if (sense.traditional != '') {
        variants[sense.traditional] = true;
      }
    }
    var rollup = variants.isEmpty ? '' : variants.keys.join('、').trim();
    ;
    return rollup == '' ? headword : '$headword （$rollup）';
  }

  /// A rollup of pinyin pronunciations of the headword
  String get pinyinRollup {
    var sb = StringBuffer();
    sb.writeAll(pinyin, ',');
    return sb.toString();
  }

  Map toJson() {
    var sb = StringBuffer();
    sb.writeAll(pinyin, ',');
    return {
      'headword': headword,
      'headwordId': headwordId,
      'sourceId': sourceId,
      'pinyin': sb.toString(),
      'senses': _senses.toJson()
    };
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
  /// A numeric identifier for the source
  final int sourceId;

  /// The URL that the source can be loaded from
  final String url;

  /// A short title for the source
  final String abbreviation;

  /// The full title of the source
  final String title;

  /// A citation
  final String citation;

  /// The author(s)
  final String author;

  /// Licence or copyright
  final String license;

  /// Each source should have a unique range of headword ids, starting with
  /// this. Some sources, such as Chinese Notes, have their own headword ids,
  /// which will be used instead of computing a headword id starting with this
  /// value.
  final int startHeadwords;

  DictionarySource(this.sourceId, this.url, this.abbreviation, this.title,
      this.citation, this.author, this.license, this.startHeadwords);

  DictionarySource.fromJson(var obj)
      : sourceId = obj['sourceId'],
        url = obj['url'],
        abbreviation = obj['abbreviation'],
        title = obj['title'],
        citation = obj['citation'],
        author = obj['author'],
        license = obj['license'],
        startHeadwords = obj['startHeadwords'];
}

/// The identity of a dictionary source, how to download it, and a citation.
class DictionarySources {
  final Map<int, DictionarySource> sources;

  DictionarySources(this.sources);

  DictionarySources.fromJson(var obj) : sources = {} {
    if (obj is! List) {
      return;
    }
    for (var sourceObj in obj) {
      var source = DictionarySource.fromJson(sourceObj);
      sources[source.sourceId] = source;
    }
  }

  DictionarySource lookup(int key) {
    var source = sources[key];
    if (source == null) {
      throw Exception('dictionary source $key not found');
    }
    return source;
  }
}

/// Build a forward index by parsing a dictionary from a JSON string.
///
/// Indended for the Chinese Notes and NTI Reader native dictionary structure
DictionaryCollectionIndex dictFromJson(
    String jsonString, DictionarySource source) {
  var i = source.startHeadwords;
  List data = json.decode(jsonString) as List;
  Map<String, DictionaryEntries> entryMap = {};
  for (var lu in data) {
    try {
      var luid = (lu['luid'] != null) ? int.parse(lu['luid']) : i;
      var hwid = (lu['h'] != null) ? int.parse(lu['h']) : i;
      var s = lu['s'] ?? '';
      var t = lu['t'] ?? '';
      var p = lu['p'] ?? '';
      var e = lu['e'] ?? '';
      var g = lu['g'] ?? '';
      var n = lu['n'] ?? '';
      var sense = Sense(luid, hwid, s, t, p, e, g, n);
      var entries = entryMap[s];
      if (entries == null || entries.length == 0) {
        var senses = Senses([sense]);
        var entry = DictionaryEntry(s, hwid, source.sourceId, {p}, senses);
        entryMap[s] = DictionaryEntries(s, [entry]);
      } else {
        entries.entries[0].addSense(sense);
      }
      if (t != '') {
        var entries = entryMap[t];
        if (entries == null) {
          var entry =
              DictionaryEntry(s, hwid, source.sourceId, {p}, Senses([sense]));
          entryMap[t] = DictionaryEntries(t, [entry]);
        } else {
          entries.entries[0].addSense(sense);
        }
      }
      i++;
    } on Exception catch (ex) {
      print('Could not load parse entry ${lu['h']}, ${lu['s']}: $ex');
      rethrow;
    }
  }
  return DictionaryCollectionIndex(entryMap);
}

/// Gets the dictionary configuration from a JSON string
DictionarySources getConfig(String jsonString) {
  Map<int, DictionarySource> dSources = {};
  Map data = json.decode(jsonString) as Map;
  List sources = data['data'];
  var i = 0;
  for (var source in sources) {
    i++;
    var sid = (source['sourceId'] != null) ? int.parse(source['sourceId']) : i;
    var startHeadwords = (source['startHeadwords'] != null)
        ? int.parse(source['startHeadwords'])
        : (i - 1) * 1000000 + 2;
    dSources[sid] = DictionarySource(
        sid,
        source['url'],
        source['abbreviation'],
        source['title'],
        source['citation'],
        source['author'],
        source['license'],
        startHeadwords);
  }
  return DictionarySources(dSources);
}

/// A default set of sources
DictionarySources getDefaultSources() {
  Map<int, DictionarySource> sources = {};
  sources[1] = DictionarySource(
      1,
      'chinesenotes_words.json',
      'Chinese Notes',
      'Chinese Notes Chinese-English Dictionary',
      'https://github.com/alexamies/chinesenotes.com',
      'Alex Amies',
      'Creative Commons Attribution-Share Alike 3.0',
      2);
  sources[2] = DictionarySource(
      2,
      'modern_named_entities.json',
      'Modern Entities',
      'Chinese Notes modern named entities',
      'https://github.com/alexamies/chinesenotes.com',
      'Alex Amies',
      'Creative Commons Attribution-Share Alike 3.0',
      6000002);
  return DictionarySources(sources);
}

/// Build a forward index by parsing a dictionary from a JSON string.
///
/// Indended for the Chinese Notes and NTI Reader native dictionary structure
HeadwordIDIndex headwordsFromJson(String jsonString, DictionarySource source) {
  var i = source.startHeadwords;
  List data = json.decode(jsonString) as List;
  Map<int, DictionaryEntry> entryMap = {};
  for (var lu in data) {
    try {
      var luid = (lu['luid'] != null) ? int.parse(lu['luid']) : i;
      var hwid = (lu['h'] != null) ? int.parse(lu['h']) : i;
      var s = lu['s'] ?? '';
      var t = lu['t'] ?? '';
      var p = lu['p'] ?? '';
      var e = lu['e'] ?? '';
      var g = lu['g'] ?? '';
      var n = lu['n'] ?? '';
      var sense = Sense(luid, hwid, s, t, p, e, g, n);
      var entry = entryMap[s];
      if (entry == null) {
        entryMap[hwid] =
            DictionaryEntry(s, hwid, source.sourceId, {p}, Senses([sense]));
      } else {
        entry.addSense(sense);
      }
      if (t != '') {
        var entry = entryMap[t];
        if (entry == null) {
          entryMap[hwid] =
              DictionaryEntry(s, hwid, source.sourceId, {p}, Senses([sense]));
        } else {
          entry.addSense(sense);
        }
      }
      i++;
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

/// Build a combined index by combining multiple dictionaries
DictionaryCollectionIndex mergeDictionaries(
    List<DictionaryCollectionIndex> dictionaries) {
  Map<String, DictionaryEntries> index = {};
  for (var dictionary in dictionaries) {
    for (var headword in dictionary.keys()) {
      var entriesToAdd = dictionary.lookup(headword);
      var e = index[headword];
      if (e == null) {
        index[headword] = entriesToAdd;
      } else {
        e.entries.addAll(entriesToAdd.entries);
      }
    }
  }
  return DictionaryCollectionIndex(index);
}

/// Build a combined headword ID index by combining multiple dictionaries.
///
/// Headword IDs for dicttionaries should be unique.
HeadwordIDIndex mergeHWIDIndexes(List<HeadwordIDIndex> indexes) {
  Map<int, DictionaryEntry> index = {};
  for (var dictionary in indexes) {
    for (var hwid in dictionary.entries.keys) {
      var entry = dictionary.entries[hwid]!;
      var e = index[hwid];
      if (e == null) {
        index[hwid] = entry;
      } else {
        print('Conflict merging headword ID indexes: entry ${entry.headword}, '
            '${entry.headwordId}, ${entry.sourceId} conflicts with entry '
            '${e.headword}, ${e.sourceId}');
      }
    }
  }
  return HeadwordIDIndex(index);
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
  /// The query that lead to these results
  String query;

  /// The lookup results
  List<Term> terms;

  /// A map from headword id to source abbreviation, for reverse lookup
  Map<int, String> sourceAbbrev;

  QueryResults(this.query, this.terms, this.sourceAbbrev);

  QueryResults.fromJson(var obj)
      : query = obj['query'],
        terms = [],
        sourceAbbrev = {} {
    var termsObj = obj['terms'];
    if (!(termsObj is List)) {
      return;
    }
    List termsArray = termsObj;
    for (var tObj in termsArray) {
      var term = Term.fromJson(tObj);
      terms.add(term);
    }
    var abbrevObj = obj['sourceAbbrev'];
    if (!(abbrevObj is String)) {
      return;
    }
    var tokens = abbrevObj.split(',');
    for (var token in tokens) {
      var pair = token.split(':');
      if (pair.length == 2) {
        var sourceId = int.parse(pair[0]);
        var abbreviation = pair[1];
        sourceAbbrev[sourceId] = abbreviation;
      }
    }
  }

  /// For JavaScript interoperability
  Map toJson() {
    var termsObj = [];
    for (var term in terms) {
      termsObj.add(term.toJson());
    }
    List<String> abbrevList = [];
    for (var key in sourceAbbrev.keys) {
      abbrevList.add('${key}:${sourceAbbrev[key]}');
    }
    var abbrevObj = StringBuffer();
    abbrevObj.writeAll(abbrevList, ',');
    return {
      'query': query,
      'terms': termsObj,
      'sourceAbbrev': abbrevObj.toString()
    };
  }
}

/// Sense is the meaning of a dictionary entry.
class Sense {
  /// Lexical unit ID, uniquely identifies the word sense for a given headword
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

  Sense.fromJson(var obj)
      : luid = obj['luid'],
        hwid = obj['hwid'],
        simplified = obj['simplified'],
        traditional = obj['traditional'],
        pinyin = obj['pinyin'],
        english = obj['english'],
        grammar = obj['grammar'],
        notes = obj['notes'] {}

  @override
  bool operator ==(dynamic other) {
    return other is Sense &&
        (((luid > 0) && (other.luid == luid) && (other.hwid == hwid)) ||
            (((luid <= 0) && (other.english == english))));
  }

  // Combines simplified and traditional if they differe, eg 围 (圍)
  String get chinese {
    if (traditional == '' || simplified == traditional) {
      return simplified;
    }
    return '$simplified （$traditional）';
  }

  /// For JavaScript interoperability
  Map toJson() {
    return {
      'luid': luid,
      'hwid': hwid,
      'simplified': simplified,
      'traditional': traditional,
      'pinyin': pinyin,
      'english': english,
      'grammar': grammar,
      'notes': notes
    };
  }
}

/// Senses is a list of word senses.
class Senses {
  final List<Sense> senses;

  Senses(this.senses);

  Senses.fromJson(var obj) : senses = [] {
    var sensesObj = obj['senses'];
    if (obj['senses'] is! List) {
      return;
    }
    List sensesArray = sensesObj;
    for (var senseObj in sensesArray) {
      var sense = Sense.fromJson(senseObj);
      senses.add(sense);
    }
  }

  void add(Sense sense) {
    senses.add(sense);
  }

  int get length {
    return senses.length;
  }

  /// For JavaScript interoperability
  Map toJson() {
    var sensesArray = [];
    for (var sense in senses) {
      sensesArray.add(sense.toJson());
    }
    return {'senses': sensesArray};
  }
}

/// A Term contains the QueryText searched for and possibly a matching
/// dictionary entry. There will only be matching dictionary entries for
/// Chinese words in the dictionary. For reverse lookups with non-Chinese text,
/// Chinese words will have nil DictEntry values and matching values will be
/// included in the Senses field.
class Term {
  String query;
  DictionaryEntries entries;
  Senses senses;

  Term(this.query, this.entries, this.senses);

  Term.fromJson(var obj)
      : query = obj['query'],
        entries = DictionaryEntries.fromJson(obj['entries']),
        senses = Senses.fromJson(obj['senses']) {}

  /// For JavaScript interoperability
  Map toJson() {
    return {
      'query': query,
      'entries': entries.toJson(),
      'senses': senses.toJson()
    };
  }
}
