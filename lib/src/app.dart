import 'dart:convert';

import 'package:chinesenotes/chinesenotes.dart';

/// App is a top level class that holds state of resources.
class App {
  ForwardIndex? forwardIndex;
  DictionarySources? sources;
  DictionaryReverseIndex? reverseIndex;
  HeadwordIDIndex? hwIDIndex;
  PinyinIndex? pinyinIndex;
  bool loadReverseIndex = false;

  App();

  buildApp(List<HeadwordIDIndex> hwIDIndexes, DictionarySources sources,
      bool loadReverseIndex) async {
    this.sources = sources;
    hwIDIndex = mergeHWIDIndexes(hwIDIndexes);
    forwardIndex = ForwardIndex.fromHWIndex(hwIDIndex!);
    this.loadReverseIndex = loadReverseIndex;
    if (loadReverseIndex) {
      reverseIndex = buildReverseIndex(hwIDIndex!);
      pinyinIndex = buildPinyinIndex(hwIDIndex!);
    }
  }

  Future<QueryResults> lookup(String query) async {
    var msg = '';
    List<Term> terms = [];
    if (isCJKChar(query)) {
      var retries = 1;
      while (forwardIndex == null && retries <= 3) {
        print('lookup: Index is not loaded, wait and try again - $retries');
        await Future.delayed(Duration(milliseconds: retries * 500));
        retries++;
      }
      if (forwardIndex == null) {
        //  Index is still not loaded, give up
        msg = '- Headword index not loaded';
      } else {
        var tokenizer = DictTokenizer(forwardIndex!, hwIDIndex!);
        var tokens = tokenizer.tokenize(query);
        for (var token in tokens) {
          terms.add(Term(token.token,
              DictionaryEntries(token.token, token.entries), Senses([])));
        }
      }
    } else {
      // did not find anything for Chinese lookup, try pinyin
      if (pinyinIndex == null) {
        msg = '- Pinyin index not loaded';
      } else {
        var flat = flattenPinyin(query);
        var hwIds = pinyinIndex!.lookup(flat);
        for (var hwId in hwIds) {
          var e = hwIDIndex?.entries[hwId];
          if (e != null) {
            var dEntry = DictionaryEntries(e.headword, [e]);
            terms.add(Term(query, dEntry, Senses([])));
          }
        }
      }
    }
    Senses senses = Senses([]);
    if (terms.isEmpty) {
      // did not find anything for forward lookup, try reverse lookup
      if (reverseIndex == null) {
        msg = '- Reverse index was loaded';
        loadReverseIndex = true;
        reverseIndex = buildReverseIndex(hwIDIndex!);
        pinyinIndex = buildPinyinIndex(hwIDIndex!);
      }
      var queryLower = query.toLowerCase();
      var rEntries = reverseIndex!.lookup(queryLower);
      List<Sense> sList = [];
      for (var rEntry in rEntries) {
        var e = hwIDIndex?.entries[rEntry.hwid];
        var s = e?.getSenses().lookup(rEntry.luid);
        if (s != null) {
          sList.add(s);
        }
      }
      var senses = Senses(sList);
      var term = Term(query, DictionaryEntries('', []), senses);
      terms.add(term);
    }
    Map<int, String> sourceAbbrev = {};
    if (hwIDIndex == null) {
      msg = '- Headword id\'s are not loaded';
      return QueryResults(query, terms, sourceAbbrev, msg);
    }
    if (sources == null) {
      msg = '- Source list is not loaded';
      return QueryResults(query, terms, sourceAbbrev, msg);
    }
    for (var sense in senses.senses) {
      var entry = hwIDIndex!.entries[sense.hwid];
      if (entry != null) {
        var source = sources!.lookup(entry.sourceId);
        sourceAbbrev[sense.hwid] = source.abbreviation;
      }
    }
    for (var t in terms) {
      for (var entry in t.entries.entries) {
        var source = sources!.lookup(entry.sourceId);
        sourceAbbrev[entry.headwordId] = source.abbreviation;
      }
    }
    return QueryResults(query, terms, sourceAbbrev, msg);
  }

  DictionarySource? getSource(int hwID) {
    var sourceId = hwIDIndex?.entries[hwID]?.sourceId;
    return sources?.lookup(sourceId!);
  }
}

/// Contains the result of a lookup checking both forward and reverse indexes.
class QueryResults {
  /// The query that lead to these results
  final String query;

  /// The lookup results
  final List<Term> terms;

  /// A map from headword id to source abbreviation, for reverse lookup
  final Map<int, String> sourceAbbrev;

  final String msg;

  QueryResults(this.query, this.terms, this.sourceAbbrev, this.msg);

  QueryResults.fromJson(var obj)
      : query = obj['query'],
        terms = [],
        sourceAbbrev = {},
        msg = obj['msg'] {
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
      'sourceAbbrev': abbrevObj.toString(),
      'msg': msg
    };
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
