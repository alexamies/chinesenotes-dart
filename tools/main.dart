import 'dart:io';

import 'package:xml/xml.dart';

import 'package:chinesenotes/chinesenotes.dart';

class EntryBase {
  final String sanskrit;
  final String chinese;
  final List<String> tibWylie;
  final List<String> tibScript;

  EntryBase(this.sanskrit, this.chinese, this.tibWylie, this.tibScript);
}

String formatEntry(EntryBase entry, int headwordId) {
  return '{"luid": $headwordId, '
      '"h": $headwordId,'
      '"s": "${entry.chinese}",'
      '"n": "Sanskrit equivalent: ${entry.sanskrit}, '
      'Tibetan: ${entry.tibWylie.first}, '
      'Tibetan script: ${entry.tibScript.first}"'
      '}';
}

List<EntryBase> parseEntry(XmlElement entry) {
  List<EntryBase> pEntries = [];
  final san = entry
      .findAllElements('orth')
      .where((el) => el.getAttribute('xml:lang') == 'san-Latn');
  final zhElems = entry
      .findAllElements('cit')
      .where((el) => el.getAttribute('xml:lang') == 'zho-Hant');
  zhElems.forEach((element) {
    final chineseTerms = element.text.split('\n');
    for (var chinese in chineseTerms) {
      var ch = chinese.trim();
      if (ch.isEmpty || (ch == '\\') || !isCJKChar(ch)) {
        continue;
      }
      final sanskrit = san.first.text.trim();
      final tibElems = entry
          .findAllElements('cit')
          .where((el) => el.getAttribute('xml:lang') == 'bod-Latn');
      List<String> tibWylie = [];
      tibElems.forEach((element) {
        tibWylie.add(element.text.trim());
      });
      final tibStriptElems = entry
          .findAllElements('cit')
          .where((el) => el.getAttribute('xml:lang') == 'bod-Tibt');
      List<String> tibScript = [];
      tibStriptElems.forEach((element) {
        tibScript.add(element.text.trim());
      });
      var pEntry = EntryBase(sanskrit, ch, tibWylie, tibScript);
      pEntries.add(pEntry);
    }
  });
  return pEntries;
}

void main() async {
  final fName = 'data/mahavyutpatti.dila.tei.p5.xml';
  final outFName = 'mahavyutpatti-chrome-ext/mahavyutpatti.json';
  print('Reading $fName');
  var sb = StringBuffer();
  sb.writeln('['
      '{"source_title":"Mahāvyutpatti Sanskrit-Tibetan-Chinese dictionary",'
      '"source_abbreviation":"Mahāvyutpatti",'
      '"source_author":"",'
      '"source_license":"Copyright expired"},');
  try {
    final file = new File(fName);
    final document = XmlDocument.parse(file.readAsStringSync());
    final entries = document.findAllElements('entry');
    var hwid = 0;
    for (var entry in entries) {
      var pEntries = parseEntry(entry);
      for (var pEntry in pEntries) {
        hwid++;
        if (hwid > 1) {
          sb.writeln(',');
        }
        var entryJSON = formatEntry(pEntry, hwid);
        sb.write(entryJSON);
      }
    }
    sb.writeln(']');
    var outFile = File(outFName);
    outFile.writeAsString(sb.toString());
    print('Write: $hwid entries to $outFName');
  } catch (e) {
    print('Could not parse file, error: $e');
  }
}
