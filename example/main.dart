import 'package:chinesenotes/cnotes.dart';

void main() {
  var testSource = DictionarySource(1, 'http://example.com', 'Test source',
      'Chinese Notes Chinese-English Dictionary', 'Accessed 2021-04-02');
  var sources = DictionarySources(<int, DictionarySource>{1: testSource});
  const jsonString =
      """[{"s":"邃古","t":"","p":"suìgǔ","e": "remote antiquity","g":"noun","n":"(CC-CEDICT '邃古'; Guoyu '邃古')","h":"2"}]""";
  var forrwardIndex = dictFromJson(jsonString, testSource);
  const headword = '邃古';
  var dictEntries = forrwardIndex.lookup(headword);
  if (dictEntries.entries.isEmpty) {
    print('Did not find an entry for $headword');
    return;
  }
  for (var ent in dictEntries.entries) {
    var source = sources.lookup(ent.sourceId);
    print('Found an entry in ${source.abbreviation}');
    for (var sense in ent.senses) {
      print('Pinyin: ${sense.pinyin}');
      print('English: ${sense.english}');
    }
  }
}
