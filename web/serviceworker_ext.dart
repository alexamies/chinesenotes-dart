import 'dart:convert';

/// Service worker for Chrome Extension

import 'dart:html';
import 'dart:js';

import 'package:chinesenotes/chinesenotes.dart';
import 'package:chinesenotes/chinesenotes_html.dart';

var app = App();
AppConfig? appConfig;

Future<String> loadFromExt(String filename) async {
  try {
    final response = await ServiceWorkerGlobalScope.instance.fetch(filename);
    final body = response as Body;
    return await body.text();
  } catch (e) {
    print('Unable to load file $filename, error: $e');
    return '';
  }
}

void initApp() async {
  var sw = Stopwatch();
  sw.start();
  print('CNotes, initApp enter');
  try {
    String jsonConfigString = await loadFromExt('config.json');
    if (jsonConfigString.isNotEmpty) {
      Map configData = json.decode(jsonConfigString) as Map;
      appConfig = AppConfig.fromJson(configData);
    }

    var sources = appConfig != null ? appConfig!.sources : getDefaultSources();
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

    app.buildApp(forwardIndexes, hwIDIndexes, sources);
    sw.stop();
    print('Dictionary loaded in ${sw.elapsedMilliseconds} ms with '
        '${app.hwIDIndex?.entries.length} entries');
  } catch (e) {
    print('Unable to load dictionary, error: $e');
  }
  print('CNotes, initApp exit');
}

void onMenuEvent(JsObject info, var tabsNotUsed) async {
  print('onMenuEvent enter');
  var activeObj = JsObject.jsify({'active': true, 'currentWindow': true});
  var query = info['selectionText'];
  QueryResults results = await app.lookup(query);
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
  var jsOnClicked = context['chrome']['contextMenus']['onClicked'];
  JsObject onClicked = (jsOnClicked is JsObject
      ? jsOnClicked
      : new JsObject.fromBrowserObject(jsOnClicked));
  onClicked.callMethod('addListener', [onMenuEvent]);
}

void setUpApp(var details) async {
  try {
    String jsonConfigString = await loadFromExt('config.json');
    if (jsonConfigString.isNotEmpty) {
      Map configData = json.decode(jsonConfigString) as Map;
      appConfig = AppConfig.fromJson(configData);
    }
  } catch (e) {
    print('setUpApp: Unable to load config: $e');
  }
  var contextMenuText = appConfig != null
      ? appConfig!.contextMenuText
      : 'Lookup with Chinese Notes ...';
  var menuObj = JsObject.jsify({
    'id': 'cnotes',
    'title': contextMenuText,
    'contexts': ['selection']
  });
  context['chrome']['contextMenus'].callMethod('create', [menuObj]);
}

void onInstalled() async {
  try {
    var jsOnInstalled = context['chrome']['runtime']['onInstalled'];
    JsObject dartOnInstalled = (jsOnInstalled is JsObject
        ? jsOnInstalled
        : new JsObject.fromBrowserObject(jsOnInstalled));
    dartOnInstalled.callMethod('addListener', [setUpApp]);

    initApp();
  } catch (e) {
    print('Unable to listen for Chrome service worker install events: $e');
  }
}

void main() {
  print('CNotes: running service worker');
  onInstalled();
  contextMenuSetup();
}
