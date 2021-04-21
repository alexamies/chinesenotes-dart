import 'dart:convert';

/// Service worker for Chrome Extension

import 'dart:html';
import 'dart:js';

import 'package:chinesenotes/chinesenotes.dart';

App? app;

DictionarySources getSources() {
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

Future<String> loadFromExt(String filename) async {
  final response = await ServiceWorkerGlobalScope.instance.fetch(filename);
  print('response is a ${response.runtimeType}');
  final body = response as Body;
  final text = await body.text();
  print('text is ${text.substring(0, 100)}');
  return text;
}

Future<App?> initApp(DictionarySources sources) async {
  var sw = Stopwatch();
  sw.start();
  print('CNotes, initApp enter');
  try {
    List<DictionaryCollectionIndex> forwardIndexes = [];
    List<HeadwordIDIndex> hwIDIndexes = [];
    for (var source in sources.sources.values) {
      try {
        String jsonString = await loadFromExt(source.url);
        var forwardIndex = dictFromJson(jsonString, source);
        forwardIndexes.add(forwardIndex);
        var hwIDIndex = headwordsFromJson(jsonString, source);
        hwIDIndexes.add(hwIDIndex);
      } catch (ex) {
        print('Could not load dicitonary ${source.abbreviation}: $ex');
      }
    }

    var mergedFwdIndex = mergeDictionaries(forwardIndexes);
    var mergedHwIdIndex = mergeHWIDIndexes(hwIDIndexes);
    var reverseIndex = buildReverseIndex(mergedFwdIndex);
    var app = App(mergedFwdIndex, sources, reverseIndex, mergedHwIdIndex);
    sw.stop();
    print('Dictionary loaded in ${sw.elapsedMilliseconds} ms with '
        '${mergedFwdIndex.entries.length} entries');
    return app;
  } catch (e) {
    print('Unable to load dictionary, error: $e');
  }
  print('CNotes, initApp exit');
}

void onMenuEvent(JsObject info, var tabsNotUsed) {
  print('onMenuEvent enter');
  var activeObj = JsObject.jsify({'active': true, 'currentWindow': true});
  var query = info['selectionText'];
  QueryResults results =
      (app != null) ? app!.lookup(query) : QueryResults(query, []);
  var terms = results.terms;
  print('onMenuEvent got ${terms.length} terms');
  var termsObj = [];
  for (var term in terms) {
    var entryObj = {'s': term.entries.headword};
    var entriesObj = [entryObj];
    var termObj = {'entries': entriesObj};
    termsObj.add(termObj);
  }
  var msg = {'query': query, 'terms': termsObj};
  var msgObj = JsObject.jsify(msg);
  void sendMessage(var tabs) {
    var tabId = tabs[0]['id'];
    print('sendMessage sending selectionText: ${query} to tab $tabId');
    context['chrome']['tabs'].callMethod('sendMessage', [tabId, msgObj]);
  }

  context['chrome']['tabs'].callMethod('query', [activeObj, sendMessage]);
}

void contextMenuSetup() {
  print('contextMenuSetup: enter');
  var jsOnClicked = context['chrome']['contextMenus']['onClicked'];
  JsObject onClicked = (jsOnClicked is JsObject
      ? jsOnClicked
      : new JsObject.fromBrowserObject(jsOnClicked));
  print('contextMenuSetup: onClicked ${onClicked.runtimeType}'
      ', hasProperty ${onClicked.hasProperty('addListener')}');
  onClicked.callMethod('addListener', [onMenuEvent]);
  print('contextMenuSetup: exit');
}

void setUpApp(var details) {
  print('CNotes: setUpApp enter');
  var menuObj = JsObject.jsify({
    'id': 'cnotes',
    'title': 'Lookup with Chinese Notes ...',
    'contexts': ['selection']
  });
  context['chrome']['contextMenus'].callMethod('create', [menuObj]);
}

void onInstalled() async {
  print('CNotes, onInstalled enter');
  try {
    var jsOnInstalled = context['chrome']['runtime']['onInstalled'];
    JsObject dartOnInstalled = (jsOnInstalled is JsObject
        ? jsOnInstalled
        : new JsObject.fromBrowserObject(jsOnInstalled));
    dartOnInstalled.callMethod('addListener', [setUpApp]);

    app = await initApp(getSources());
  } catch (e) {
    print('Unable to listen for Chrome service worker install events: $e');
  }
  print('CNotes, onInstalled exit');
}

void main() async {
  print('CNotes: running service worker');
  onInstalled();
  contextMenuSetup();
}
