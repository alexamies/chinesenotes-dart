import 'dart:convert';

/// Service worker for Chrome Extension

import 'dart:html';
import 'dart:js';

import 'package:chinesenotes/chinesenotes.dart';

App? app;

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
      (app != null) ? app!.lookup(query) : QueryResults(query, [], {});
  var res = results.toJson();
  print('onMenuEvent got ${results.terms.length} terms');
  var msg = JsObject.jsify(res);
  void responseCallback() {
    print('onMenuEvent responseCallback for query $query');
  }

  void sendMessage(var tabs) {
    var tabId = tabs[0]['id'];
    print('sendMessage sending selectionText: ${query} to tab $tabId');
    context['chrome']['tabs']
        .callMethod('sendMessage', [tabId, msg, null, responseCallback]);
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

    app = await initApp(getDefaultSources());
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
