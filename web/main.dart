/// Client application to load dicitonaries and display lookup results.

import 'dart:html';
import 'dart:js';

import 'package:chinesenotes/chinesenotes.dart';
import 'package:chinesenotes/chinesenotes_html.dart';

DictionarySources getSources() {
  const sourceNums = [1, 2, 3, 4, 5, 6];
  Map<int, DictionarySource> sources = {};
  for (var sourceNum in sourceNums) {
    var nameID = '#sourceName${sourceNum}';
    var sourceCB = querySelector(nameID);
    if (sourceCB == null) {
      continue;
    }
    var cb = sourceCB as CheckboxInputElement;
    if ((cb.checked == null) || !cb.checked!) {
      continue;
    }
    var tokens = cb.value;
    if (tokens == null) {
      continue;
    }
    var sourceTokens = tokens.split(',');
    if (sourceTokens.length < 7) {
      throw Exception('Not enough information to identify source: $tokens');
    }
    var urlID = '#sourceURL${sourceNum}';
    var sourceTF = querySelector(urlID) as InputElement;
    var sourceURL = sourceTF.value!;
    sources[sourceNum] = DictionarySource(
        sourceNum,
        sourceURL,
        sourceTokens[1],
        sourceTokens[2],
        sourceTokens[3],
        sourceTokens[4],
        sourceTokens[5],
        int.parse(sourceTokens[6]));
  }
  if (sources.isEmpty) {
    sources = getDefaultSources().sources;
  }
  return DictionarySources(sources);
}

Future<App?> initApp(DictionarySources sources, Element statusDiv,
    Element errorDiv, Element? submitButton) async {
  var sw = Stopwatch();
  sw.start();
  print('Starting client app');
  statusDiv.text = 'Loading dictionary';

  try {
    List<HeadwordIDIndex> hwIDIndexes = [];
    for (var source in sources.sources.values) {
      try {
        final jsonString = await HttpRequest.getString(source.url);
        var hwIDIndex = headwordsFromJson(jsonString, source);
        hwIDIndexes.add(hwIDIndex);
      } catch (ex) {
        print('Could not load dicitonary ${source.abbreviation}: $ex');
        errorDiv.text = 'Could not load dicitonary ${source.abbreviation}';
      }
    }
    statusDiv.text = 'Dictionary headwords loaded';
    var app = App();
    app.buildApp(hwIDIndexes, sources, true);
    if (submitButton != null) {
      var multiLookupSubmit = submitButton as ButtonElement;
      multiLookupSubmit.disabled = false;
    }
    sw.stop();
    print('Dictionary loaded in ${sw.elapsedMilliseconds} ms with '
        '${app.hwIDIndex?.entries.length} entries');
    statusDiv.text = 'Dictionary indexing complete';
    return app;
  } catch (e) {
    errorDiv.text = 'Unable to load dictionary';
    statusDiv.text = 'Try a hard refresh of the page and search again';
    print('Unable to load dictionary, error: $e');
  }
}

DivElement makeDialog() {
  // In a Chrome extension content script, create a DOM container for output
  print('In a Chrome extension content script');
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

void main() async {
  print('cnotes main enter');
  var sources = getSources();
  var body = querySelector('body')!;
  var cnOutput = querySelector('#cnOutput');
  if (cnOutput == null) {
    cnOutput = makeDialog();
    body.children.insert(0, cnOutput);
  }
  var statusDiv = querySelector('#status')!;
  var errorDiv = querySelector('#lookupError')!;
  var submitButton = querySelector('#multiLookupSubmit');
  var app = await initApp(sources, statusDiv, errorDiv, submitButton);
  if (app == null) {
    print('Could not init the app, giving up');
    return;
  }
  var textField = querySelector('#multiLookupInput');
  var div = querySelector('#lookupResults');

  void onMessageListener(msg, sender, sendResponse) async {
    if (msg == null) {
      print('onMessageListener msg is null');
    }
    if (!msg.hasProperty('term')) {
      print('onMessageListener msg does not have term');
    }
    var query = msg['term'];
    print('onMessageListener, term: ${query} from $sender');
    var results = await app.lookup(query);
    displayLookup(results, cnOutput, div, statusDiv, errorDiv, textField);
  }

  void lookup(Event evt) async {
    print('Got a lookup event');
    var query = '';
    if (textField != null) {
      var tf = textField as TextInputElement;
      query = tf.value!.trim();
      var results = await app.lookup(query);
      displayLookup(results, cnOutput, div, statusDiv, errorDiv, textField);
    }
    evt.preventDefault();
  }

  var findForm = querySelector('#multiLookupForm');
  findForm?.onSubmit.listen(lookup);

  // If we are a Chrome extension, then listen for messages
  try {
    var jsOnMessageEvent = context['chrome']['runtime']['onMessage'];
    JsObject dartOnMessageEvent = (jsOnMessageEvent is JsObject
        ? jsOnMessageEvent
        : new JsObject.fromBrowserObject(jsOnMessageEvent));
    dartOnMessageEvent.callMethod('addListener', [onMessageListener]);
  } catch (e) {
    print('Unable to listen for Chrome content events: $e');
  }
}
