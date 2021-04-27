import 'dart:convert';

import 'package:chinesenotes/chinesenotes.dart';

const pinyin2Ascii = {
  'ā': 'a',
  'á': 'a',
  'ǎ': 'a',
  'à': 'a',
  'Ā': 'a',
  'Á': 'a',
  'Ǎ': 'a',
  'À': 'a',
  'ē': 'e',
  'é': 'e',
  'ě': 'e',
  'è': 'e',
  'Ē': 'e',
  'É': 'e',
  'Ě': 'e',
  'È': 'e',
  'ī': 'i',
  'í': 'i',
  'ǐ': 'i',
  'ì': 'i',
  'Ī': 'i',
  'Í': 'i',
  'Ǐ': 'i',
  'Ì': 'i',
  'ō': 'o',
  'ó': 'o',
  'ǒ': 'o',
  'ò': 'o',
  'Ō': 'o',
  'Ó': 'o',
  'Ǒ': 'o',
  'Ò': 'o',
  'ū': 'u',
  'ú': 'u',
  'ǔ': 'u',
  'ù': 'u',
  'Ū': 'u',
  'Ú': 'u',
  'Ǔ': 'u',
  'Ù': 'u'
};

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

/// Build a forward index by parsing a dictionary from a JSON string.
///
/// Indended for the Chinese Notes and NTI Reader native dictionary structure
DictionaryCollectionIndex dictFromJson(
    String jsonString, DictionarySource source) {
  var sw = Stopwatch();
  sw.start();
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
  sw.stop();
  print('dictFromJson completed in ${sw.elapsedMilliseconds} ms with '
      '${entryMap.length} entries for ${source.abbreviation}');
  return DictionaryCollectionIndex(entryMap);
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

/// HeadwordIDIndex indexes the dictionary by headword ID.
///
/// A headword ID uniquely identifies a dictionary entry with a specific source.
class HeadwordIDIndex {
  final Map<int, DictionaryEntry> entries;

  HeadwordIDIndex(this.entries);
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

String flattenPinyin(String pinyin) {
  var flattened = pinyin;
  for (var e in pinyin2Ascii.entries) {
    flattened = flattened.replaceAll(e.key, e.value);
  }
  return flattened;
}

PinyinIndex buildPinyinIndex(HeadwordIDIndex hwIDIndex) {
  var sw = Stopwatch();
  sw.start();
  Map<String, PinyinIndexEntry> entries = {};
  for (var hw in hwIDIndex.entries.values) {
    if (hw.pinyin.isEmpty) {
      continue;
    }
    for (var pinyin in hw.pinyin) {
      var pinyinFlat = flattenPinyin(pinyin);
      var entry = entries[pinyinFlat];
      if (entry == null) {
        var newEntry = PinyinIndexEntry(pinyinFlat, {hw});
        entries[pinyinFlat] = newEntry;
        continue;
      }
      entry.entries.add(hw);
    }
  }
  print('buildPinyinIndex completed in ${sw.elapsedMilliseconds} ms with '
      '${entries.length} entries');
  return PinyinIndex(entries);
}

/// PinyinIndex indexes the dictionary by equivalent.
///
/// The entries are indexed by Senses, which is part of a Chinese headword.
class PinyinIndex {
  final Map<String, PinyinIndexEntry> entries;

  PinyinIndex(this.entries);

  /// Null safe lookup
  ///
  /// Return: the senses or an empty list if there is no match found
  PinyinIndexEntry lookup(String pinyin) {
    var result = entries[pinyin];
    if (result == null) {
      return PinyinIndexEntry(pinyin, {});
    }
    return result;
  }
}

/// PinyinIndex indexes the dictionary by flattened pinyin.
///
/// The diacritics are removed and capitals and lower cased.
class PinyinIndexEntry {
  final String pinyin;
  final Set<DictionaryEntry> entries;

  PinyinIndexEntry(this.pinyin, this.entries);
}
