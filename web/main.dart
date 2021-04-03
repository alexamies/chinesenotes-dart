import 'dart:html';

import 'package:chinesenotes/chinesenotes.dart';

const url = 'ntireader_sample.json';

void main() async {
  try {
    print('Starting client app');
    var output = querySelector('#output')!;
    output.text = 'Loading sample dictionary';
    String jsonString = await HttpRequest.getString(url);
    var cnSource = DictionarySource(
        1,
        ntiReaderJson,
        'Chinese Notes',
        'Chinese Notes Chinese-English Dictionary',
        'https://github.com/alexamies/chinesenotes.com, accessed 2021-04-01');
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var forrwardIndex = dictFromJson(jsonString, cnSource);
    const hw = '四面八方';
    var dictEntries = forrwardIndex.lookup(hw);
    querySelector('#output')?.text =
        'Looking up $hw. Found ${dictEntries.entries.length} entries. ';
    if (dictEntries.entries.length > 0) {
      var ul = UListElement();
      output.children.add(ul);
      for (var ent in dictEntries.entries) {
        var source = sources.lookup(ent.sourceId);
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
  } catch (e) {
    print('got an error ${e}');
    querySelector('#output')?.text = 'Got an error';
    rethrow;
  }
}
