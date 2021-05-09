/// A command line utility for transforming TEI files into JSON files that can
/// be read by the Chinese Notes APIs
///
/// Usage:
/// dart tools/parse_tei.dart \
///  -s data/${SOURCE_XML} \ # source-file, Source TEI file
///  -t data/${SOURCE_JSON} \ # target-file, Target JSON file
///  -l "chinese" \ # source-lang, Source language 'chinese' or 'sanskrit'
///  -n "A Full Title" \ # title
///  -x "Abbreviated Title" \ # abbreviation
///  -a "A. Author" \ # author, Author name
///  -y "Copyright by author" # license, included in the output JSON file

import 'dart:io';

import 'package:args/args.dart';
import 'package:xml/xml.dart';

import 'package:chinesenotes/chinesenotes.dart';

// Command line options
const sourceFile = 'source-file';
const sourceDefault = 'data/tei.p5.xml';
const targetFile = 'target-file';
const targetDefault = 'dictionary.json';
const sourceLang = 'source-lang';
const sourceLangDefault = 'chinese';
const titleOption = 'title';
const titleDefault = 'Full Title';
const abbrevOption = 'abbreviation';
const abbrevDefault = 'Title Abbreviation';
const authorOption = 'author';
const authorDefault = 'A Author';
const licenseOption = 'license';
const licenseDefault = 'Copyright by Author';

const defReplace = {'\n': ' ', '"': ' ', '<': '&lt;', '>': '&gt;'};
const pinyinReplace = {';': ''};

ArgResults? argResults;

class ChineseEntry {
  final String chinese;
  final String pinyin;
  final String english;

  ChineseEntry(this.chinese, this.pinyin, this.english);
}

class SanskritEntry {
  final String sanskrit;
  final String chinese;
  final List<String> tibWylie;
  final List<String> tibScript;

  SanskritEntry(this.sanskrit, this.chinese, this.tibWylie, this.tibScript);
}

String formatEntry(ChineseEntry entry, int headwordId) {
  var eng = entry.english;
  for (var ent in defReplace.entries) {
    eng = eng.replaceAll(ent.key, ent.value);
  }
  var pinyin = entry.pinyin;
  for (var ent in pinyinReplace.entries) {
    pinyin = pinyin.replaceAll(ent.key, ent.value);
  }
  return '{"luid": $headwordId, '
      '"h": $headwordId,'
      '"s": "${entry.chinese}",'
      '"p": "${pinyin}",'
      '"e": "${eng}"'
      '}';
}

String formatSanskritEntry(SanskritEntry entry, int headwordId) {
  return '{"luid": $headwordId, '
      '"h": $headwordId,'
      '"s": "${entry.chinese}",'
      '"n": "Sanskrit equivalent: ${entry.sanskrit}, '
      'Tibetan: ${entry.tibWylie.first}, '
      'Tibetan script: ${entry.tibScript.first}"'
      '}';
}

List<ChineseEntry> parseEntry(XmlElement entry) {
  List<ChineseEntry> pEntries = [];
  final orthElems = entry.findAllElements('orth');
  final orthElem = orthElems.first;
  final ch = orthElem.text.trim();
  if (ch.isEmpty || (ch == '\\') || !isCJKChar(ch)) {
    return pEntries;
  }

  final pinyinElems = entry
      .findAllElements('pron')
      .where((el) => el.getAttribute('notation') == 'pinyin');
  final pinyinElem = pinyinElems.first;
  final pinyin = pinyinElem.text.trim();

  final defElems = entry.findAllElements('def');
  if (defElems.isEmpty) {
    return pEntries;
  }
  final defElem = defElems.first;
  final definition = defElem.text.trim();
  var pEntry = ChineseEntry(ch, pinyin, definition);
  pEntries.add(pEntry);
  return pEntries;
}

List<SanskritEntry> parseSanskritEntry(XmlElement entry) {
  List<SanskritEntry> pEntries = [];
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
      var pEntry = SanskritEntry(sanskrit, ch, tibWylie, tibScript);
      pEntries.add(pEntry);
    }
  });
  return pEntries;
}

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption(sourceFile, defaultsTo: sourceDefault, abbr: 's')
    ..addOption(targetFile, defaultsTo: targetDefault, abbr: 't')
    ..addOption(sourceLang, defaultsTo: sourceLangDefault, abbr: 'l')
    ..addOption(titleOption, defaultsTo: titleDefault, abbr: 'n')
    ..addOption(abbrevOption, defaultsTo: abbrevDefault, abbr: 'x')
    ..addOption(authorOption, defaultsTo: authorDefault, abbr: 'a')
    ..addOption(licenseOption, defaultsTo: licenseDefault, abbr: 'y');
  argResults = parser.parse(arguments);
  final fName = argResults![sourceFile];
  final outFName = argResults![targetFile];
  final sLanguage = argResults![sourceLang];
  final title = argResults![titleOption];
  final abbreviation = argResults![abbrevOption];
  final author = argResults![authorOption];
  final license = argResults![licenseOption];
  print('Reading $fName in $sLanguage');
  var sb = StringBuffer();
  sb.writeln('['
      '{"source_title":"${title}",'
      '"source_abbreviation":"${abbreviation}",'
      '"source_author":"${author}",'
      '"source_license":"${license}"},');
  try {
    final file = new File(fName);
    final document = XmlDocument.parse(file.readAsStringSync());
    final entries = document.findAllElements('entry');
    var hwid = 0;
    for (var entry in entries) {
      if (sLanguage == 'sanskrit') {
        var pEntries = parseSanskritEntry(entry);
        for (var pEntry in pEntries) {
          hwid++;
          if (hwid > 1) {
            sb.writeln(',');
          }
          var entryJSON = formatSanskritEntry(pEntry, hwid);
          sb.write(entryJSON);
        }
      } else {
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
    }
    sb.writeln(']');
    var outFile = File(outFName);
    outFile.writeAsString(sb.toString());
    print('Write: $hwid entries to $outFName');
  } catch (e) {
    print('Could not parse file, error: $e');
    rethrow;
  }
}
