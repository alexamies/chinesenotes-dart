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

/// ForwardIndex is an index for a collection of dictionaries.
///
/// The entries are indexed by Chinese headword, either or both of simplified
/// and traditional Chinese.
class ForwardIndex {
  final Map<String, Set<int>> headwordIds;

  ForwardIndex(this.headwordIds);

  ForwardIndex.fromHWIndex(HeadwordIDIndex index) : headwordIds = {} {
    for (var e in index.entries.entries) {
      var hwId = e.key;
      var dictEntry = e.value;

      // Index by simplified
      var hwIdsSimp = headwordIds[dictEntry.simplified];
      if (hwIdsSimp == null) {
        hwIdsSimp = {};
      }
      hwIdsSimp.add(hwId);
      headwordIds[dictEntry.simplified] = hwIdsSimp;

      // Index by traditional
      var trad = dictEntry.traditional;
      for (var t in trad) {
        var hwIdsTrad = headwordIds[t];
        if (hwIdsTrad == null) {
          hwIdsTrad = {};
        }
        hwIdsTrad.add(hwId);
        headwordIds[t] = hwIdsTrad;
      }
    }
    print('ForwardIndex.fromHWIndex loaded ${headwordIds.length} keys');
  }

  Iterable<String> keys() {
    return headwordIds.keys;
  }

  /// Null safe lookup
  ///
  /// Return: the value or an empty list if there is no match found
  /// Params:
  ///   key - a Chinese term, simplified or traditional
  /// Returns:
  ///   A list of matching entries
  DictionaryEntries lookup(HeadwordIDIndex hwIndex, String key) {
    var hwIDs = headwordIds[key];
    if (hwIDs == null) {
      return DictionaryEntries(key, []);
    }
    List<DictionaryEntry> entries = [];
    for (var hwid in hwIDs) {
      var entry = hwIndex.entries[hwid];
      if (entry != null) {
        entries.add(entry);
      } else {
        print('No matching entry for term $key, $hwid');
      }
    }
    return DictionaryEntries(key, entries);
  }
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
  Map<String, Set<int>> entries = {};
  for (var hw in hwIDIndex.entries.values) {
    if (hw.pinyin.isEmpty) {
      continue;
    }
    for (var pinyin in hw.pinyin) {
      var pinyinFlat = flattenPinyin(pinyin);
      var entry = entries[pinyinFlat];
      if (entry == null) {
        entries[pinyinFlat] = {hw.headwordId};
        continue;
      }
      entry.add(hw.headwordId);
    }
  }
  print('buildPinyinIndex completed in ${sw.elapsedMilliseconds} ms with '
      '${entries.length} entries');
  return PinyinIndex(entries);
}

/// PinyinIndex indexes the dictionary by equivalent.
///
/// The entries are indexed by headword IDs.
class PinyinIndex {
  final Map<String, Set<int>> entries;

  PinyinIndex(this.entries);

  /// Null safe lookup
  ///
  /// Return: the senses or an empty list if there is no match found
  Set<int> lookup(String pinyin) {
    var result = entries[pinyin];
    if (result == null) {
      return {};
    }
    return result;
  }
}
