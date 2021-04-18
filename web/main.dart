import 'dart:html';
import 'dart:js';

import 'package:chinesenotes/chinesenotes.dart';

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
    sources[1] = DictionarySource(
        1,
        'https://raw.githubusercontent.com/alexamies/chinesenotes.com/master/downloads/chinesenotes_words.json',
        'Chinese Notes',
        'Chinese Notes Chinese-English Dictionary',
        'https://github.com/alexamies/chinesenotes.com',
        'Alex Amies',
        'Creative Commons Attribution-Share Alike 3.0',
        2);
    sources[2] = DictionarySource(
        2,
        'https://raw.githubusercontent.com/alexamies/chinesenotes.com/master/downloads/modern_named_entities.json',
        'Modern Entities',
        'Chinese Notes modern named entities',
        'https://github.com/alexamies/chinesenotes.com',
        'Alex Amies',
        'Creative Commons Attribution-Share Alike 3.0',
        6000002);
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
    List<DictionaryCollectionIndex> forwardIndexes = [];
    List<HeadwordIDIndex> hwIDIndexes = [];
    for (var source in sources.sources.values) {
      try {
        final jsonString = await HttpRequest.getString(source.url);
        var forwardIndex = dictFromJson(jsonString, source);
        forwardIndexes.add(forwardIndex);
        var hwIDIndex = headwordsFromJson(jsonString, source);
        hwIDIndexes.add(hwIDIndex);
      } catch (ex) {
        print('Could not load dicitonary ${source.abbreviation}: $ex');
        errorDiv.text = 'Could not load dicitonary ${source.abbreviation}';
      }
    }

    var mergedFwdIndex = mergeDictionaries(forwardIndexes);
    var mergedHwIdIndex = mergeHWIDIndexes(hwIDIndexes);
    var reverseIndex = buildReverseIndex(mergedFwdIndex);
    var app = App(mergedFwdIndex, sources, reverseIndex, mergedHwIdIndex);
    if (submitButton != null) {
      var multiLookupSubmit = submitButton as ButtonElement;
      multiLookupSubmit.disabled = false;
    }
    sw.stop();
    print('Dictionary loaded in ${sw.elapsedMilliseconds} ms with '
        '${mergedFwdIndex.entries.length} entries');
    statusDiv.text = 'Dictionary loaded';
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
  cnOutput.style.display = 'none';
  cnOutput.style.height = '150px;';
  cnOutput.style.maxHeight = '200px;';
  cnOutput.style.width = '200px;';
  cnOutput.style.maxWidth = '300px';
  cnOutput.style.border = '1px solid black';
  cnOutput.style.zIndex = '2';
  cnOutput.style.background = '#FFFFFF';
  cnOutput.style.opacity = '80%';
  cnOutput.style.position = 'absolute';
  cnOutput.style.top = '200px';
  cnOutput.style.left = '300px';
  cnOutput.style.padding = '20px';

  var h2 = HeadingElement.h2();
  h2.text = 'Chinese Notes Chinese-English Dictionary';
  h2.style.fontSize = 'medium;';
  cnOutput.children.add(h2);

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

  void displayLookup(String query) {
    print('displayLookup, $query');
    div?.children = [];
    try {
      var results = app.lookup(query);
      print('displayLookup, got ${results.terms.length} terms');
      for (var term in results.terms) {
        var dictEntries = term.entries;
        print('displayLookup, got ${dictEntries.length} entries');
        if (dictEntries.length > 0) {
          var counttDiv = DivElement();
          counttDiv.className = 'counttDiv';
          if (dictEntries.length == 1) {
            counttDiv.text = 'Found 1 entry.';
          } else {
            counttDiv.text = 'Found ${dictEntries.length} entries.';
          }
          div?.children.add(counttDiv);
          var entryDiv = DivElement();
          div?.children.add(entryDiv);
          for (var ent in dictEntries.entries) {
            var hwDiv = DivElement();
            hwDiv.text = ent.hwRollup;
            hwDiv.className = 'dict-entry-headword';
            entryDiv.children.add(hwDiv);
            var ul = UListElement();
            entryDiv.children.add(ul);
            var li = LIElement();
            var senseOL = OListElement();
            for (var sense in ent.senses) {
              var senseLi = LIElement();
              var sensePrimary = DivElement();
              var pinyinSpan = SpanElement();
              pinyinSpan.className = 'cnnotes-pinyin';
              pinyinSpan.text = '${sense.pinyin} ';
              sensePrimary.children.add(pinyinSpan);
              var posSpan = SpanElement();
              posSpan.className = 'dict-entry-grammar';
              posSpan.text = '${sense.grammar} ';
              sensePrimary.children.add(posSpan);
              var engSpan = SpanElement();
              engSpan.className = 'dict-entry-definition';
              engSpan.text = '${sense.english} ';
              sensePrimary.children.add(engSpan);
              senseLi.children.add(sensePrimary);
              var notesDiv = DivElement();
              notesDiv.className = 'dict-entry-notes-content';
              notesDiv.text = sense.notes;
              senseLi.children.add(notesDiv);
              senseOL.children.add(senseLi);
            }
            li.children.add(senseOL);
            ul.children.add(li);
            var source = sources.lookup(ent.sourceId);
            var sourceDiv = DivElement();
            sourceDiv.className = 'dict-entry-source';
            sourceDiv.text = 'Source: ${source.abbreviation}';
            entryDiv.children.add(sourceDiv);
          }
        } else if (term.senses.senses.length > 0) {
          var counttDiv = DivElement();
          counttDiv.className = 'counttDiv';
          if (term.senses.senses == 1) {
            counttDiv.text = 'Found 1 sense.';
          } else {
            counttDiv.text = 'Found ${term.senses.senses.length} senses.';
          }
          div?.children.add(counttDiv);
          var ul = UListElement();
          div?.children.add(ul);
          for (var sense in term.senses.senses) {
            var li = LIElement();
            var primaryDiv = DivElement();
            primaryDiv.text = sense.chinese;
            primaryDiv.className = 'dict-sense-primary';
            li.children.add(primaryDiv);
            var secondaryDiv = DivElement();
            secondaryDiv.className = 'dict-sense-secondary';
            var pinyinSpan = SpanElement();
            pinyinSpan.className = 'dict-entry-pinyin';
            pinyinSpan.text = '${sense.pinyin} ';
            secondaryDiv.children.add(pinyinSpan);
            var posSpan = SpanElement();
            posSpan.className = 'dict-entry-grammar';
            posSpan.text = '${sense.grammar} ';
            secondaryDiv.children.add(posSpan);
            var engSpan = SpanElement();
            engSpan.className = 'dict-entry-definition';
            engSpan.text = '${sense.english} ';
            secondaryDiv.children.add(engSpan);
            li.children.add(secondaryDiv);
            var notesDiv = DivElement();
            notesDiv.className = 'dict-notes-div';
            var notesSpan = SpanElement();
            notesSpan.className = 'dict-entry-notes-content';
            if (sense.notes != '') {
              notesSpan.text = 'Notes: ${sense.notes} ';
            }
            notesDiv.children.add(notesSpan);
            var sourceSpan = SpanElement();
            sourceSpan.className = 'dict-sense-source';
            var source = app.getSource(sense.hwid);
            if (source != null) {
              sourceSpan.text = 'Source: ${source.abbreviation}';
            }
            notesDiv.children.add(sourceSpan);
            li.children.add(notesDiv);
            ul.children.add(li);
          }
        } else {
          div?.text = 'Did not find any results.';
        }
        statusDiv.text = '';
      }
    } catch (e) {
      errorDiv.text = 'Unable to load dictionary';
      statusDiv.text = 'Try a hard refresh of the page and search again';
      print('Unable to load dictionary, error: $e');
    }
    cnOutput?.style.display = 'block';
  }

  void onMessageListener(msg, sender, sendResponse) {
    if (msg == null) {
      print('onMessageListener msg is null');
    }
    if (!msg.hasProperty('term')) {
      print('onMessageListener msg does not have term');
    }
    var query = msg['term'];
    print('onMessageListener, term: ${query}');
    displayLookup(query);
  }

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

  // The service worker is a work in progress
  /*
  try {
    print('Preparing for offline use');
    var res = await window.navigator.serviceWorker?.register('sworker.dart.js');
    print('Registered service worker: ${res?.active}');
  } catch (e) {
    print('Unable to registere service worker: $e');
  }
  */
}
