/// Chrome extension content script to display dictionary lookup results.

import 'dart:html';
import 'dart:js';

import 'package:chinesenotes/chinesenotes.dart';
import 'package:chinesenotes/chinesenotes_html.dart';
import 'package:chinesenotes/chinesenotes_js.dart';

const maxSenses = 10;

DivElement makeDialog() {
  // In a Chrome extension content script, create a DOM container for output
  print('makeDialog enter');
  var cnOutput = DivElement();
  cnOutput.id = 'cnOutput';
  cnOutput.style.position = 'fixed';
  cnOutput.style.display = 'none';
  cnOutput.style.height = '250px;';
  cnOutput.style.maxHeight = '800px;';
  cnOutput.style.width = '300px;';
  cnOutput.style.maxWidth = '400px';
  cnOutput.style.border = '1px solid black';
  cnOutput.style.zIndex = '5';
  cnOutput.style.background = '#FFFFFF';
  //cnOutput.style.opacity = '80%';
  cnOutput.style.padding = '20px';

  var closeButton = ButtonElement();
  closeButton.style.position = 'absolute';
  closeButton.style.right = '20px;';
  closeButton.style.top = '20px';
  closeButton.style.right = '20px';
  closeButton.text = 'x';
  closeButton.title = 'Close dialog';
  closeButton.addEventListener('click', (Event event) {
    cnOutput.style.display = 'none';
    event.preventDefault();
  });
  cnOutput.children.add(closeButton);

  var header = HeadingElement.h4();
  header.text = 'Chinese-English Dictionary';
  header.style.fontSize = 'medium;';
  cnOutput.children.add(header);

  var findForm = FormElement();
  findForm.style.padding = '20px';
  findForm.id = 'multiLookupForm';

  var textField = TextInputElement();
  textField.id = 'multiLookupInput';
  findForm.children.add(textField);

  var submitButton = ButtonElement();
  submitButton.text = 'Find';
  submitButton.id = 'multiLookupSubmit';
  findForm.children.add(submitButton);
  cnOutput.children.add(findForm);

  var statusDiv = DivElement();
  statusDiv.id = 'status';
  cnOutput.children.add(statusDiv);

  var errorDiv = DivElement();
  errorDiv.id = 'lookupError';
  cnOutput.children.add(errorDiv);

  var div = DivElement();
  div.id = 'lookupResults';
  cnOutput.children.add(div);

  var dismissButton = ButtonElement();
  dismissButton.style.right = '20px;';
  dismissButton.text = 'OK';
  dismissButton.title = 'Close dialog';
  dismissButton.addEventListener('click', (Event event) {
    cnOutput.style.display = 'none';
    event.preventDefault();
  });
  cnOutput.children.add(dismissButton);

  return cnOutput;
}

void openDialog(Element? cnOutput, Element? textfield, String query) {
  if (textfield != null) {
    var tf = textfield as TextInputElement;
    tf.value = query;
  }
  cnOutput?.style.top = '200px';
  cnOutput?.style.left = '300px';
  cnOutput?.style.display = 'block';
}

void main() async {
  print('cnotes main enter');

  var body = querySelector('body')!;
  var cnOutput = querySelector('#cnOutput');
  if (cnOutput == null) {
    cnOutput = makeDialog();
    body.children.insert(0, cnOutput);
  }
  var statusDiv = querySelector('#status')!;
  var errorDiv = querySelector('#lookupError')!;
  var textField = querySelector('#multiLookupInput');
  var div = querySelector('#lookupResults');

  void onMessageListener(msg, sender, sendResponse) {
    if (msg == null) {
      print('onMessageListener msg is null');
    }
    var query = msg['query'];
    print('onMessageListener, query: ${query}');
    var results = queryResultsFromJson(msg);
    print('onMessageListener, got ${results.terms.length} terms');
    var sources = getDefaultSources();
    displayLookup(
        results, cnOutput, div, statusDiv, errorDiv, textField, sources);
  }

/*
  void lookup(Event evt) {
    var query = '';
    if (textField != null) {
      var tf = textField as TextInputElement;
      query = tf.value!.trim();
      displayLookup(query);
    }
    evt.preventDefault();
  }
  var findForm = querySelector('#multiLookupForm');
  findForm?.onSubmit.listen(lookup);
*/

  // If we are a Chrome extension, then listen for messages
  try {
    print('Adding listener for Chrome context menu events');
    var jsOnMessageEvent = context['chrome']['runtime']['onMessage'];
    JsObject dartOnMessageEvent = (jsOnMessageEvent is JsObject
        ? jsOnMessageEvent
        : new JsObject.fromBrowserObject(jsOnMessageEvent));
    dartOnMessageEvent.callMethod('addListener', [onMessageListener]);
  } catch (e) {
    print('Unable to listen for Chrome content events: $e');
  }
}
