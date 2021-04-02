import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:chinesenotes/cnotes.dart';

const url = 'https://ntireader.org/dist/ntireader.json';

/// downloads the file from the given url
Future<String> download(String url) async {
  StringBuffer sb = StringBuffer();
  HttpClient client = new HttpClient();
  try {
    var request = await client.getUrl(Uri.parse(url));
    var response = await request.close();
    if (response.statusCode != 200) {
      throw Exception('server error or not found');
    }
    var contents = response.transform(utf8.decoder);
    await for (var chunk in contents) {
      sb.write(chunk);
    }
    client.close();
  } catch (ex) {
    print('Could not load the dictionary from ${url}');
    rethrow;
  }
  var s = sb.toString();
  print('Downloaded ${s.length} characters');
  return s;
}

void main() {
  test('Test dictFromJson with I/O download', () async {
    var cnSource = DictionarySource(
        1,
        url,
        'Chinese Notes',
        'Chinese Notes Chinese-English Dictionary',
        'https://github.com/alexamies/chinesenotes.com, accessed 2021-04-01');
    var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
    var jsonString = await download(cnSource.url);
    var forrwardIndex = dictFromJson(jsonString, cnSource);
    var dictEntries = forrwardIndex.lookup('你好');
    expect(dictEntries.entries.length, equals(1));
    for (var ent in dictEntries.entries) {
      var source = sources.lookup(ent.sourceId);
      expect(source.abbreviation, equals('Chinese Notes'));
      expect(ent.pinyin, equals('níhǎo'));
    }
  });
}
