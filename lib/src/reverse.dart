import 'package:chinesenotes/chinesenotes.dart';

const notesPatterns = [
  r'Scientific name: (.+?)(\(|,|;)',
  r'Sanskrit equivalent: (.+?)(\(|,|;)',
  r'Pāli: (.+?)(\(|,|;)',
  r'Pali: (.+?)(\(|,|;)',
  r'Japanese: (.+?)(\(|,|;)',
  r'Tibetan: (.+?)(\(|,|;)',
  r'or: (.+?)(\(|,|;)'
];
const separator = '; ';
const stopWords = ['a ', 'an ', 'to ', 'the '];

/// Builds a reverse index from the given forward index.
///
/// The keys of the reserse index will be the equivalents in English and
/// possibly other languages contained in the notes field.
///
/// Params:
///   forrwardIndex - containing the dictionary entries
///   np - to extract secondary equivalents contained in notes
DictionaryReverseIndex buildReverseIndex(HeadwordIDIndex hwIdIndex) {
  var sw = Stopwatch();
  sw.start();
  var np = NotesProcessor(notesPatterns);
  Map<String, Set<ReverseindexEntry>> revIndex = {};
  void addSenses(List<String> equivalents, Sense sense) {
    for (var equiv in equivalents) {
      var equivLower = equiv.toLowerCase();
      var s = revIndex[equivLower];
      var rEntry = ReverseindexEntry(sense.hwid, sense.luid);
      if (s == null) {
        revIndex[equivLower] = {rEntry};
      } else if (!s.contains(sense)) {
        s.add(rEntry);
        revIndex[equivLower] = s;
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

  for (var entry in hwIdIndex.entries.values) {
    for (var sense in entry.getSenses().senses) {
      var equivalents = sense.english.split(separator);
      var cleaned = removeStopWords(equivalents);
      addSenses(cleaned, sense);
      var notesEquiv = np.parseNotes(sense.notes);
      addSenses(notesEquiv, sense);
    }
  }
  print('buildReverseIndex completed in ${sw.elapsedMilliseconds} ms with '
      '${revIndex.length} entries');

  return DictionaryReverseIndex(revIndex);
}

/// DictionaryReverseIndex indexes the dictionary by English equivalent.
///
/// The entries are indexed by lexical unit ID, which map directly to senses.
class DictionaryReverseIndex {
  final Map<String, Set<ReverseindexEntry>> _senses;

  DictionaryReverseIndex(this._senses);

  /// Null safe lookup
  ///
  /// Return: the senses or an empty list if there is no match found
  Set<ReverseindexEntry> lookup(String key) {
    var senses = _senses[key];
    if (senses == null) {
      return {};
    }
    return senses;
  }
}

class ReverseindexEntry {
  final int hwid;
  final int luid;

  ReverseindexEntry(this.hwid, this.luid);
}
