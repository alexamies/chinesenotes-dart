import 'dart:convert';
import 'dart:html';

import 'package:chinesenotes/chinesenotes.dart';

const url = 'dist/ntireader.json';

DictionaryCollectionIndex? forrwardIndex;
DictionarySource? cnSource;
DictionarySources? sources;

void loadDictionary(Element output) async {
  final request = HttpRequest();
  request
    ..open('GET', url)
    ..onLoadEnd.listen((e) => requestComplete(request, output))
    ..send('');
}

void processResponse(String jsonString, Element output) {
  try {
    forrwardIndex = dictFromJson(jsonString, cnSource!);
  } catch (e) {
    print('got an error ${e}');
    querySelector('#output')?.text = 'Got an error';
    rethrow;
  }
}

void requestComplete(HttpRequest request, Element output) {
  switch (request.status) {
    case 200:
      var jsonString = request.responseText;
      if (jsonString != null) {
        processResponse(jsonString, output);
      }
      return;
    default:
      final div = LIElement();
      div.text = 'Request failed: ${request.status}';
      output.children.add(div);
  }
}

void main() async {
  print('Starting client app');
  var output = querySelector('#findError')!;
  loadDictionary(output);
  var textField = querySelector('#findInput') as TextInputElement;
  cnSource = DictionarySource(
      1,
      ntiReaderJson,
      'Chinese Notes',
      'Chinese Notes Chinese-English Dictionary',
      'https://github.com/alexamies/chinesenotes.com, accessed 2021-04-01');
  sources = DictionarySources(<int, DictionarySource>{1: cnSource!});
  var div = querySelector('#findResults')!;

  void lookup(Event evt) {
    var dictEntries = forrwardIndex!.lookup(textField.value!);
    div.text = 'Found ${dictEntries.entries.length} entries. ';
    if (dictEntries.entries.length > 0) {
      var ul = UListElement();
      output.children.add(ul);
      for (var ent in dictEntries.entries) {
        var source = sources!.lookup(ent.sourceId);
        StringBuffer sb = StringBuffer('Source: ${source.abbreviation}: ');
        for (var sense in ent.senses) {
          sb.write('pinyin: ${sense.pinyin}, ');
          sb.write('English: ${sense.english}.');
        }
        var li = LIElement();
        li.text = sb.toString();
        ul.children.add(li);
      }
    }
    evt.preventDefault();
  }

  var findForm = querySelector('#findForm')!;
  findForm.onSubmit.listen(lookup);
}
