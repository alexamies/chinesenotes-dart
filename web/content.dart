/// Chrome extension content script to display dictionary lookup results.

import 'dart:html';
import 'dart:js';

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

  void displayLookup(var results) {
    var query = results['query'] != null ? results['query'] : '';
    if (query == '') {
      print('displayLookup, query empty');
      return;
    }
    print('displayLookup, $query');
    div?.children = [];
    try {
      var terms = results['terms'] != null ? results['terms'] : [];
      print('displayLookup, got ${terms.length} term(s)');
      for (var term in terms) {
        var dictEntries = term['entries'] != null ? term['entries'] : [];
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
            //var source = sources.lookup(ent.sourceId);
            var sourceDiv = DivElement();
            sourceDiv.className = 'dict-entry-source';
            //sourceDiv.text = 'Source: ${source.abbreviation}';
            sourceDiv.text = 'Source: ${ent.sourceId}';
            entryDiv.children.add(sourceDiv);
          }
        } else if (term.senses.senses.length > 0) {
          var counttDiv = DivElement();
          counttDiv.className = 'counttDiv';
          var numFound = term.senses.senses.length;
          if (numFound == 1) {
            counttDiv.text = 'Found 1 sense.';
          } else {
            if (numFound <= maxSenses) {
              counttDiv.text = 'Found ${numFound} senses.';
            } else {
              counttDiv.text =
                  'Found ${numFound} senses, showing ${maxSenses}.';
            }
          }
          div?.children.add(counttDiv);
          var ul = UListElement();
          div?.children.add(ul);
          var numAdded = 0;
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
            //var source = app.getSource(sense.hwid);
            //if (source != null) {
            //  sourceSpan.text = 'Source: ${source.abbreviation}';
            //}
            notesDiv.children.add(sourceSpan);
            li.children.add(notesDiv);
            ul.children.add(li);
            numAdded++;
            if (numAdded >= maxSenses) {
              break;
            }
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
    openDialog(cnOutput, textField, results.query);
  }

  void onMessageListener(msg, sender, sendResponse) {
    if (msg == null) {
      print('onMessageListener msg is null');
    }
    if (!msg.hasProperty('term')) {
      print('onMessageListener msg does not have term');
    }
    var query = msg['query'];
    print('onMessageListener, term: ${query} from $sender');
    displayLookup(msg);
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