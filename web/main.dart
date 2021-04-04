import 'dart:html';

import 'package:chinesenotes/chinesenotes.dart';

const url = 'dist/ntireader.json';

void main() async {
  print('Starting client app');
  var errorDiv = querySelector('#findError')!;
  var statusDiv = querySelector('#status')!;
  statusDiv.text = 'Loading dictionary';

  try {
    var cnSource = DictionarySource(
        1,
        ntiReaderJson,
        'Chinese Notes',
        'Chinese Notes Chinese-English Dictionary',
        'https://github.com/alexamies/chinesenotes.com, accessed 2021-04-01');
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    final jsonString = await HttpRequest.getString(url);
    var forwardIndex = dictFromJson(jsonString, cnSource);
    var reverseIndex = buildReverseIndex(forwardIndex);
    statusDiv.text = 'Dictionary loaded';

    var app = App(forwardIndex, sources, reverseIndex);

    var textField = querySelector('#findInput') as TextInputElement;
    var div = querySelector('#findResults')!;

    void lookup(Event evt) {
      div.children = [];
      var results = app.lookup(textField.value!);
      for (var term in results.terms) {
        var dictEntries = term.entries;
        if (dictEntries.length > 0) {
          var counttDiv = DivElement();
          counttDiv.className = 'counttDiv';
          if (dictEntries.length == 1) {
            counttDiv.text = 'Found 1 entry.';
          } else {
            counttDiv.text = 'Found ${dictEntries.length} entries.';
          }
          div.children.add(counttDiv);
          var entryDiv = DivElement();
          div.children.add(entryDiv);
          for (var ent in dictEntries.entries) {
            var hwDiv = DivElement();
            hwDiv.text = ent.hwRollup;
            hwDiv.className = 'dict-entry-headword';
            entryDiv.children.add(hwDiv);
            var ul = UListElement();
            entryDiv.children.add(ul);
            var li = LIElement();
            for (var sense in ent.senses) {
              var pinyinSpan = SpanElement();
              pinyinSpan.className = 'dict-entry-pinyin';
              pinyinSpan.text = '${sense.pinyin} ';
              li.children.add(pinyinSpan);
              var engSpan = SpanElement();
              engSpan.className = 'dict-entry-equivalent';
              engSpan.text = '${sense.english} ';
              li.children.add(engSpan);
              var notesSpan = SpanElement();
              notesSpan.className = 'dict-entry-notes';
              notesSpan.text = sense.notes;
              li.children.add(notesSpan);
            }
            ul.children.add(li);
            var source = sources.lookup(ent.sourceId);
            var sourceDiv = DivElement();
            sourceDiv.className = 'dict-entry-source';
            sourceDiv.text = 'Source: ${source.abbreviation}';
            entryDiv.children.add(sourceDiv);
          }
        } else if (term.senses.senses.length > 0) {
          div.text = 'Found ${term.senses.senses.length} senses.';
          var ul = UListElement();
          div.children.add(ul);
          for (var sense in term.senses.senses) {
            StringBuffer sb = StringBuffer();
            sb.write('Simplified: ${sense.simplified}, ');
            sb.write('Traditional: ${sense.traditional}, ');
            sb.write('pinyin: ${sense.pinyin}, ');
            sb.write('English: ${sense.english},');
            sb.write('Notes: ${sense.notes}.');
            var li = LIElement();
            li.text = sb.toString();
            ul.children.add(li);
          }
        } else {
          div.text = 'Did not find any results.';
        }
        statusDiv.text = '';
      }
      evt.preventDefault();
    }

    var findForm = querySelector('#findForm')!;
    findForm.onSubmit.listen(lookup);
  } catch (e) {
    errorDiv.text = 'Unable to load dictionary';
    statusDiv.text = 'Try a hard refresh of the page and search again';
    print('Unable to load dictionary, error: $e');
  }
}
