/// Service worker for Chrome Extension

import 'dart:js';

void onMenuEvent(JsObject info, var tabs) {
  print('onMenuEvent enter');
  print(
      'onMenuEvent info: ${info.runtimeType}, ${info.hasProperty('selectionText')}');
  //var tabsObj = JsObject.jsify({'active': true, 'currentWindow': true});
  void sendMessage(var tabs) {
    var jsObj = JsObject.jsify({'term': info['selectionText']});
    context['chrome']['tabs'].callMethod('sendMessage', [tabs[0].id, jsObj]);
  }

  context['chrome']['tabs'].callMethod('query', [tabs, sendMessage]);
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

void onInstalled() {
  print('CNotes, onInstalled enter');
  try {
    var jsOnInstalled = context['chrome']['runtime']['onInstalled'];
    JsObject dartOnInstalled = (jsOnInstalled is JsObject
        ? jsOnInstalled
        : new JsObject.fromBrowserObject(jsOnInstalled));
    dartOnInstalled.callMethod('addListener', [setUpApp]);
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
