import 'dart:html';

import 'package:chinesenotes/chinesenotes.dart';

const url = 'dist/ntireader.json';

void main() async {
  print('Starting client app');
  var output = querySelector('#findError')!;
  output.text = 'Loading dictionary';

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
    output.text = 'Dictionary loaded';

    var app = App(forwardIndex, sources, reverseIndex);

    var textField = querySelector('#findInput') as TextInputElement;
    var div = querySelector('#findResults')!;

    void lookup(Event evt) {
      var results = app.lookup(textField.value!);
      for (var term in results.terms) {
        var dictEntries = term.entries;
        if (dictEntries.entries.length > 0) {
          div.text = 'Found ${dictEntries.entries.length} entries. ';
          var ul = UListElement();
          div.children.add(ul);
          for (var ent in dictEntries.entries) {
            var source = sources.lookup(ent.sourceId);
            StringBuffer sb = StringBuffer('Source: ${source.abbreviation}: ');
            for (var sense in ent.senses) {
              sb.write('pinyin: ${sense.pinyin}, ');
              sb.write('English: ${sense.english}, ');
              sb.write('Notes: ${sense.notes}.');
            }
            var li = LIElement();
            li.text = sb.toString();
            ul.children.add(li);
          }
        } else if (term.senses.senses.length > 0) {
          div.text = 'Found ${term.senses.senses.length} senses.';
          for (var sense in term.senses.senses) {
            var ul = UListElement();
            div.children.add(ul);
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
      }
      evt.preventDefault();
    }

    var findForm = querySelector('#findForm')!;
    findForm.onSubmit.listen(lookup);
  } catch (e) {
    output.text = 'Unable to load dictionary';
    print('Unable to load dictionary, error: $e');
  }
}
