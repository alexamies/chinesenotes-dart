import 'dart:convert';

import 'package:chinesenotes/chinesenotes.dart';

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

  @override
  bool operator ==(dynamic other) {
    return other is DictionaryEntry && (other.headwordId == headwordId);
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

  String get simplified {
    if (_senses.senses.isEmpty) {
      return "";
    }
    return _senses.senses.first.simplified;
  }

  Set<String> get traditional {
    Set<String> trad = {};
    for (var sense in _senses.senses) {
      if (sense.traditional != '') {
        trad.add(sense.traditional);
      }
    }
    return trad;
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

/// Build a forward index by parsing a dictionary from a JSON string.
///
/// Indended for the Chinese Notes and NTI Reader native dictionary structure
HeadwordIDIndex headwordsFromJson(String jsonString, DictionarySource source) {
  var sw = Stopwatch();
  sw.start();
  var i = source.startHeadwords;
  List data = json.decode(jsonString) as List;
  Map<int, DictionaryEntry> entryMap = {};
  for (var lu in data) {
    try {
      int luid = (lu['luid'] != null) ? lu['luid'] : i;
      int hwid = (lu['h'] != null) ? lu['h'] : i;
      String s = lu['s'] ?? '';
      String t = lu['t'] ?? '';
      String p = lu['p'] ?? '';
      String e = lu['e'] ?? '';
      String g = lu['g'] ?? '';
      String n = lu['n'] ?? '';
      var sense = Sense(luid, hwid, s, t, p, e, g, n);
      var entry = entryMap[hwid];
      if (entry == null) {
        entryMap[hwid] =
            DictionaryEntry(s, hwid, source.sourceId, {p}, Senses([sense]));
      } else {
        entry.addSense(sense);
      }
      i++;
    } on Exception catch (ex) {
      print('Could not load parse entry ${lu['h']}, ${lu['s']}: $ex');
    }
  }
  print('headwordsFromJson: Loaded in ${sw.elapsedMilliseconds} ms with '
      '${entryMap.length} headwords');
  return HeadwordIDIndex(entryMap);
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
            (((luid <= 0) &&
                (other.simplified == simplified) &&
                (other.english == english))));
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

  Sense? lookup(int luid) {
    for (var sense in senses) {
      if (sense.luid == luid) {
        return sense;
      }
    }
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
