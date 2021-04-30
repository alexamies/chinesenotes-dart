/// Example native app to download and index dictionary and look up a word.
///
import 'dart:convert';
import 'dart:io';

import 'package:chinesenotes/chinesenotes.dart';

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

void main() async {
  var cnSource = DictionarySource(
      1,
      'https://raw.githubusercontent.com/alexamies/chinesenotes.com/master/downloads/chinesenotes_words.json',
      'NTI Reader',
      'NTI Reader Chinese-English Dictionary',
      'https://github.com/alexamies/buddhist-dictionary',
      'Alex Amies',
      'Creative Commons Attribution-Share Alike 3.0',
      1);
  var sources = DictionarySources(<int, DictionarySource>{1: cnSource});
  var jsonString = await download(cnSource.url);
  var hwIDIndex = headwordsFromJson(jsonString, cnSource);
  var app = App();
  app.buildApp([hwIDIndex], sources);
  const hw = '你好';
  print('Looking up $hw');
  var results = await app.lookup(hw);
  if (results.terms.length == 0) {
    print('No results found.');
    return;
  }
  if (results.terms.length == 1 && results.terms.first.entries.length == 0) {
    print('No results found.');
    return;
  }
  for (var term in results.terms) {
    var entries = term.entries.entries;
    print('Found ${entries.length} entries');
    for (var ent in entries) {
      var source = sources.lookup(ent.sourceId);
      print('Source: ${source.abbreviation}');
      for (var sense in ent.getSenses().senses) {
        print('Pinyin: ${sense.pinyin}');
        print('English: ${sense.english}');
      }
    }
  }
}
