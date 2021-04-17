// The service worker is a work in progress
import 'dart:html';
import 'dart:js';

import 'package:chinesenotes/chinesenotes.dart';

const cacheName = "offline";
const offlineURL = "offline.html";

App? app;

void cacheOfflinePage() async {
  try {
    var cs = await window.caches!;
    print('Service worker installed');
    var cache = await cs.open(cacheName) as JsObject;
    cache.callMethod('addAll', [offlineURL]);
    print('Offline data cached');
  } catch (e) {
    print('Offline data could not be cached: $e');
  }
}

void installSW(var event) async {
  cacheOfflinePage();
  initApp();
}

void initApp() async {
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
  var sw = Stopwatch();
  sw.start();
  try {
    List<DictionaryCollectionIndex> forwardIndexes = [];
    List<HeadwordIDIndex> hwIDIndexes = [];
    for (var source in sources.values) {
      try {
        final jsonString = await HttpRequest.getString(source.url);
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
    var ds = DictionarySources(sources);
    app = App(mergedFwdIndex, ds, reverseIndex, mergedHwIdIndex);
    sw.stop();
    print('SW: Dictionary loaded in ${sw.elapsedMilliseconds} ms');
  } catch (e) {
    print('SW: Offline data could not be cached: $e');
  }
}

void main() {
  print('Starting service worker');
  var self = ServiceWorkerGlobalScope.instance.self;
  self.addEventListener('install', installSW);
}
