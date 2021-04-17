import 'dart:html';
import 'dart:js';

const cacheName = "offline";
const offlineURL = "offline.html";

void installSW(var event) async {
  var cs = await window.caches!;
  print('Service worker installed');
  var cache = await cs.open(cacheName) as JsObject;
  cache.callMethod('addAll', [offlineURL]);
  print('Offline data cached');
}

void main() {
  print('Starting service worker');
  var self = ServiceWorkerGlobalScope.instance.self;
  self.addEventListener('install', installSW);
}
