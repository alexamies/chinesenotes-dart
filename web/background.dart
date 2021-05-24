// Entry point for Firefox add-on.
// Firefix add-ons do not support service workers, so use a background script
// instead.

import 'dart:js';

void contextMenuSetup() {
  var jsOnClicked = context['browser']['contextMenus']['onClicked'];
  JsObject onClicked = (jsOnClicked is JsObject
      ? jsOnClicked
      : new JsObject.fromBrowserObject(jsOnClicked));
  onClicked.callMethod('addListener', [onMenuEvent]);
}

void onMenuEvent(JsObject info, var tabsNotUsed) async {
  var query = info['selectionText'];
  print('onMenuEvent query: ${query}');
}

void setUpApp() async {
  var contextMenuText = 'Lookup with Chinese Notes ...';
  var menuObj = JsObject.jsify({
    'id': 'cnotes',
    'title': contextMenuText,
    'contexts': ['selection']
  });
  context['browser']['contextMenus'].callMethod('create', [menuObj]);
}

void main() async {
  print('cnotes background enter');
  setUpApp();
  contextMenuSetup();
}
