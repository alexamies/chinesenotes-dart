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
const sourceEntry = 'source-entry';
const sourceEntryDefault = 'chinese';
const titleOption = 'title';
const titleDefault = 'Full Title';
const abbrevOption = 'abbreviation';
const abbrevDefault = 'Title Abbreviation';
const authorOption = 'author';
const authorDefault = 'A Author';
const licenseOption = 'license';
const licenseDefault = 'Copyright by Author';
const hwStartOption = 'headword-start';
const hwStartDefault = "2";

const defReplace = {'\n': ' ', '"': ' ', '<': '&lt;', '>': '&gt;'};
const pinyinReplace = {';': ''};

const paliPattern = r'(P). (.+?)(\(|,|;|$)';
const sanskritPattern = r'(S|Skt). (.+?)(\(|,|;|$)';

ArgResults? argResults;

class ChineseEntry {
  final String chinese;
  final String pinyin;
  final String english;

  ChineseEntry(this.chinese, this.pinyin, this.english);
}

class PaliSanskritEntry {
  final String chinese;
  final String pali;
  final String sanskrit;

  PaliSanskritEntry(this.chinese, this.pali, this.sanskrit);
}

class PersonEntry {
  final String chinese;
  final String english;
  final String sanskrit;
  final String japanese;
  final String tibetan;
  final String authorityId;
  final List<String> aka;
  final String dynasty;
  final String placeOfOrigin;

  PersonEntry(
      this.chinese,
      this.english,
      this.sanskrit,
      this.japanese,
      this.tibetan,
      this.aka,
      this.authorityId,
      this.dynasty,
      this.placeOfOrigin);
}

class PlaceEntry {
  final String chinese;
  final String english;
  final String sanskrit;
  final String japanese;
  final String tibetan;
  final String authorityId;
  final List<String> aka;
  final String district;

  PlaceEntry(this.chinese, this.english, this.sanskrit, this.japanese,
      this.tibetan, this.aka, this.authorityId, this.district);
}

class SanskritEntry {
  final String sanskrit;
  final String chinese;
  final List<String> tibWylie;
  final List<String> tibScript;

  SanskritEntry(this.sanskrit, this.chinese, this.tibWylie, this.tibScript);
}

// PatternProcessor extracts Pali and Sanskrit from abbrevations
class PatternProcessor {
  RegExp paliExpr;
  RegExp sanskritExpr;

  PatternProcessor()
      : paliExpr = RegExp(paliPattern, unicode: true),
        sanskritExpr = RegExp(sanskritPattern, unicode: true);

  String _parseNoses(RegExp exp, String notes) {
    var reMatch = exp.firstMatch(notes);
    if (reMatch != null) {
      return reMatch[2]!.trim();
    }
    return '';
  }

  // Process the notes field for Pali pattern.
  //
  // Params:
  //   notes - the notes field to process
  // Return: pattern match from the first group
  String parsePali(String notes) {
    return _parseNoses(paliExpr, notes);
  }

  // Process the notes field for Sanskrit pattern.
  //
  // Params:
  //   notes - the notes field to process
  // Return: pattern match from the first group
  String parseSanskrit(String notes) {
    return _parseNoses(sanskritExpr, notes);
  }
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
      '"h":$headwordId,'
      '"s":"${entry.chinese}",'
      '"p":"${pinyin}",'
      '"e":"${eng}"'
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

String formatPaliSanskrit(PaliSanskritEntry entry, int headwordId) {
  var eng = [];
  var notes = [];
  if (entry.sanskrit != '') {
    eng.add(entry.sanskrit);
    notes.add('Sanskrit equivalent: ${entry.sanskrit}');
  }
  if (entry.pali != '') {
    eng.add(entry.pali);
    notes.add('Pali: ${entry.pali}');
  }
  var e = eng.join('; ');
  var n = notes.join(', ');
  return '{"luid": $headwordId, '
      '"h":$headwordId,'
      '"s":"${entry.chinese}",'
      '"e":"${e}",'
      '"n":"${n}"'
      '}';
}

String formatPersonEntry(PersonEntry entry, int headwordId) {
  var notes = ['Person'];
  if (entry.sanskrit != '') {
    notes.add('Sanskrit eqiuvialent: ${entry.sanskrit}');
  }
  if (entry.japanese != '') {
    notes.add('Japanese: ${entry.japanese}');
  }
  if (entry.tibetan != '') {
    notes.add('Tibetan: ${entry.tibetan}');
  }
  if (!entry.aka.isEmpty) {
    notes.add('also known as: ${entry.aka.join(', ')}');
  }
  if (entry.dynasty != '') {
    notes.add('dynasty: ${entry.dynasty}');
  }
  if (entry.authorityId != '') {
    notes.add('authority ID: ${entry.authorityId}');
  }
  if (entry.placeOfOrigin != '') {
    notes.add('place of origin: ${entry.placeOfOrigin}');
  }
  var note = notes
      .join('; ')
      .trim()
      .replaceAll('"', '')
      .replaceAll('\n', '')
      .replaceAll('\r', '');
  return '{"luid": $headwordId, '
      '"h":$headwordId,'
      '"s":"${entry.chinese}",'
      '"e":"${entry.english}",'
      '"n":"${note}"'
      '}';
}

String formatPlaceEntry(PlaceEntry entry, int headwordId) {
  var notes = ['Place'];
  if (entry.sanskrit != '') {
    notes.add('Sanskrit eqiuvialent: ${entry.sanskrit}');
  }
  if (entry.japanese != '') {
    notes.add('Japanese: ${entry.japanese}');
  }
  if (entry.tibetan != '') {
    notes.add('Tibetan: ${entry.tibetan}');
  }
  if (!entry.aka.isEmpty) {
    notes.add('also known as: ${entry.aka.join(', ')}');
  }
  if (entry.authorityId != '') {
    notes.add('authority ID: ${entry.authorityId}');
  }
  if (entry.district != '') {
    notes.add('district: ${entry.district}');
  }
  var note = notes
      .join('; ')
      .trim()
      .replaceAll('"', '')
      .replaceAll('\n', '')
      .replaceAll('\r', '');
  return '{"luid": $headwordId, '
      '"h":$headwordId,'
      '"s":"${entry.chinese}",'
      '"e":"${entry.english}",'
      '"n":"${note}"'
      '}';
}

List<ChineseEntry> parseEntry(XmlElement entry) {
  List<ChineseEntry> pEntries = [];
  final orthElems = entry.findAllElements('orth');
  final formElems = entry.findAllElements('form');
  final hwElem = (!orthElems.isEmpty) ? orthElems.first : formElems.first;
  var ch = hwElem.text.trim();
  if (ch.isEmpty || (ch == '\\') || !isCJKChar(ch)) {
    return pEntries;
  }
  ch = ch.replaceAll('\n', ' ');
  ch = ch.replaceAll('\r', ' ');

  final pinyinElems = entry
      .findAllElements('pron')
      .where((el) => el.getAttribute('notation') == 'pinyin');
  final pinyinElem = (!pinyinElems.isEmpty) ? pinyinElems.first : null;
  final pinyin = (pinyinElem != null) ? pinyinElem.text.trim() : '';

  final defElems = entry.findAllElements('def');
  final senseElems = entry.findAllElements('sense');
  if (defElems.isEmpty && senseElems.isEmpty) {
    return pEntries;
  }
  final defElem = (!defElems.isEmpty) ? defElems.first : senseElems.first;
  var definition = defElem.text.trim();
  definition = definition.replaceAll('\n', ' ');
  definition = definition.replaceAll('\r', ' ');
  if (definition.isEmpty || (definition == '\\')) {
    return pEntries;
  }
  var pEntry = ChineseEntry(ch, pinyin, definition);
  pEntries.add(pEntry);
  return pEntries;
}

List<PaliSanskritEntry> parsePaliSanskrit(
    XmlElement entry, PatternProcessor processor) {
  List<PaliSanskritEntry> pEntries = [];
  final formElems = entry.findAllElements('form');
  if (formElems.isEmpty) {
    return pEntries;
  }
  final hwElem = formElems.first;
  final ch = hwElem.text.trim();
  if (ch.isEmpty || (ch == '\\') || !isCJKChar(ch)) {
    return pEntries;
  }

  var pali = '';
  var sanskrit = '';
  final defElems = entry.findAllElements('p');
  for (var elem in defElems) {
    final definition = elem.text.trim();
    pali = processor.parsePali(definition);
    if (pali.contains('T1') ||
        pali.contains('T2') ||
        pali.contains('C1') ||
        pali.contains('C2')) {
      pali = '';
    }
    sanskrit = processor.parseSanskrit(definition);
    if (sanskrit.contains('T1') ||
        sanskrit.contains('T2') ||
        sanskrit.contains('C1') ||
        sanskrit.contains('C2')) {
      sanskrit = '';
    }
    if (pali != '' || sanskrit != '') {
      break;
    }
  }
  if (pali == '' && sanskrit == '') {
    return pEntries;
  }

  var pEntry = PaliSanskritEntry(ch, pali, sanskrit);
  pEntries.add(pEntry);
  return pEntries;
}

// Parse a TEI person entry from the authority database
List<PersonEntry> parsePersonEntry(XmlElement entry) {
  List<PersonEntry> pEntries = [];

  // Person authority ID
  final authId = entry.getAttribute('xml:id');
  String authorityID = (authId != null) ? authId : '';
  authorityID = authorityID.trim().replaceAll('\n', '');

  // Chinese name
  final nameElems = entry
      .findAllElements('persName')
      .where((el) => el.getAttribute('xml:lang') == 'zho-Hant');
  if (nameElems.isEmpty) {
    return pEntries;
  }
  String ch = nameElems.first.text;
  ch = ch.trim().replaceAll('\n', '');

  // Sanskrit name, may be empty
  var sanskrit = '';
  final sNameElems = entry
      .findAllElements('persName')
      .where((el) => el.getAttribute('xml:lang') == 'san-Latn');
  if (!sNameElems.isEmpty) {
    sanskrit = sNameElems.first.text;
  }
  sanskrit = sanskrit.trim();

  // Japanese name, may be empty
  var japanese = '';
  final jNameElems = entry
      .findAllElements('persName')
      .where((el) => el.getAttribute('xml:lang') == 'jpn-Latn');
  if (!jNameElems.isEmpty) {
    japanese = jNameElems.first.text;
  }
  japanese = japanese.trim();

  // Tibetan name, may be empty, example: 無著 Asaṅga, Thogs med
  var tibetan = '';
  final tNameElems = entry
      .findAllElements('persName')
      .where((el) => el.getAttribute('xml:lang') == 'bod-Latn');
  if (!tNameElems.isEmpty) {
    tibetan = tNameElems.first.text;
  }
  tibetan = tibetan.trim();

  // English name, may be empty, example: 迦膩色迦一世 Kanishka
  var english = '';
  final eNameElems = entry
      .findAllElements('persName')
      .where((el) => el.getAttribute('xml:lang') == 'eng-Latn');
  if (!eNameElems.isEmpty) {
    english = eNameElems.first.text;
  }

  var eng = (english != '')
      ? english
      : (sanskrit != '')
          ? sanskrit
          : (tibetan != '')
              ? tibetan
              : japanese;
  eng = eng
      .replaceAll('\"', '')
      .replaceAll('\'', '')
      .replaceAll('\\', '')
      .replaceAll('\n', '')
      .replaceAll('\r', '');

  // Aliases
  List<String> aka = [];
  final akaElems = entry
      .findAllElements('persName')
      .where((el) => el.getAttribute('type') == 'alternative');
  for (var akaElem in akaElems) {
    aka.add(akaElem.text.trim());
  }

  var dynasty = '';
  final dynastyElems = entry
      .findAllElements('note')
      .where((el) => el.getAttribute('type') == 'dynasty');
  for (var el in dynastyElems) {
    dynasty = el.text.trim();
  }

  var placeOfOrigin = '';
  final placeElems = entry
      .findAllElements('note')
      .where((el) => el.getAttribute('type') == 'placeOfOrigin');
  for (var el in placeElems) {
    placeOfOrigin = el.text;
  }
  placeOfOrigin = placeOfOrigin.replaceAll('\n', ' ');
  placeOfOrigin = placeOfOrigin.trim();

  var pEntry = PersonEntry(ch, eng, sanskrit, japanese, tibetan, aka,
      authorityID, dynasty, placeOfOrigin);
  pEntries.add(pEntry);
  return pEntries;
}

// Parse a TEI place entry from the authority database
List<PlaceEntry> parsePlaceEntry(XmlElement entry) {
  List<PlaceEntry> pEntries = [];
  final authId = entry.getAttribute('xml:id');
  String authorityID = (authId != null) ? authId : '';
  final nameElems = entry.findAllElements('placeName');
  if (nameElems.isEmpty) {
    return pEntries;
  }
  final ch = nameElems.first.text;
  List<String> aka = [];
  final akaElems = entry
      .findAllElements('placeName')
      .where((el) => el.getAttribute('type') == 'alternative');
  for (var akaElem in akaElems) {
    aka.add(akaElem.text);
  }

  // Sanskrit name, may be empty; example: 梵衍那國 Bāmiyān
  var sanskrit = '';
  final sNameElems = entry
      .findAllElements('placeName')
      .where((el) => el.getAttribute('xml:lang') == 'san-Latn');
  if (!sNameElems.isEmpty) {
    sanskrit = sNameElems.first.text;
  }

  // Japanese name, may be empty; example: 平城京 Heijō-kyō
  var japanese = '';
  final jNameElems = entry
      .findAllElements('placeName')
      .where((el) => el.getAttribute('xml:lang') == 'jpn-Latn');
  if (!jNameElems.isEmpty) {
    japanese = jNameElems.first.text;
  }

  // Tibetan name, may be empty; example: 岡仁波齊峰 Kangrinboqê (Mount Kailash)
  var tibetan = '';
  final tNameElems = entry
      .findAllElements('placeName')
      .where((el) => el.getAttribute('xml:lang') == 'bod-Latn');
  if (!tNameElems.isEmpty) {
    tibetan = tNameElems.first.text;
  }

  // English name, may be empty; example: 梵衍那國 Bamian
  var english = '';
  final eNameElems = entry
      .findAllElements('placeName')
      .where((el) => el.getAttribute('xml:lang') == 'eng-Latn');
  if (!eNameElems.isEmpty) {
    english = eNameElems.first.text;
  }

  var eng = (english != '')
      ? english
      : (sanskrit != '')
          ? sanskrit
          : (tibetan != '')
              ? tibetan
              : japanese;
  eng = eng
      .replaceAll('\"', '')
      .replaceAll('\'', '')
      .replaceAll('\\', '')
      .replaceAll('\n', '')
      .replaceAll('\r', '');

  var district = '';
  final districtElems = entry.findAllElements('district');
  for (var el in districtElems) {
    district = el.text;
  }
  district = district.replaceAll('\n', ' ');
  district = district.trim();

  var pEntry = PlaceEntry(
      ch, eng, sanskrit, japanese, tibetan, aka, authorityID, district);
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
    ..addOption(sourceEntry, defaultsTo: sourceEntryDefault, abbr: 'l')
    ..addOption(titleOption, defaultsTo: titleDefault, abbr: 'n')
    ..addOption(abbrevOption, defaultsTo: abbrevDefault, abbr: 'x')
    ..addOption(authorOption, defaultsTo: authorDefault, abbr: 'a')
    ..addOption(licenseOption, defaultsTo: licenseDefault, abbr: 'y')
    ..addOption(hwStartOption, defaultsTo: hwStartDefault, abbr: 'h');
  argResults = parser.parse(arguments);
  final fName = argResults![sourceFile];
  final outFName = argResults![targetFile];
  final sEntryType = argResults![sourceEntry];
  final title = argResults![titleOption];
  final abbreviation = argResults![abbrevOption];
  final author = argResults![authorOption];
  final license = argResults![licenseOption];
  final hwStartStr = argResults![hwStartOption];
  final hwStart = int.parse(hwStartStr);
  print('Reading $fName in $sEntryType');
  var sb = StringBuffer();
  sb.writeln('['
      '{"source_title":"${title}",'
      '"source_abbreviation":"${abbreviation}",'
      '"source_author":"${author}",'
      '"source_license":"${license}"}');
  try {
    final file = new File(fName);
    final document = XmlDocument.parse(file.readAsStringSync());

    // Find flavor of TEI entries to process
    final authorityTags = {'person', 'place'};
    final entryTag =
        (authorityTags.contains(sEntryType)) ? sEntryType : 'entry';
    print('Looking for $entryTag elements');

    // Iterate over entries
    final entries = document.findAllElements(entryTag);
    var hwid = hwStart;
    final processor = PatternProcessor();
    for (var entry in entries) {
      switch (sEntryType) {
        // Used for Mahāvyutpatti
        case 'sanskrit':
          var pEntries = parseSanskritEntry(entry);
          for (var pEntry in pEntries) {
            sb.writeln(',');
            var entryJSON = formatSanskritEntry(pEntry, hwid);
            sb.write(entryJSON);
            hwid++;
          }
          break;
        // Used for glossaries by Karashima
        case 'pali-sanskrit':
          var pEntries = parsePaliSanskrit(entry, processor);
          for (var pEntry in pEntries) {
            sb.writeln(',');
            var entryJSON = formatPaliSanskrit(pEntry, hwid);
            sb.write(entryJSON);
            hwid++;
          }
          break;
        // Used for Person authority database
        case 'person':
          var pEntries = parsePersonEntry(entry);
          for (var pEntry in pEntries) {
            sb.writeln(',');
            var entryJSON = formatPersonEntry(pEntry, hwid);
            sb.write(entryJSON);
            hwid++;
          }
          break;
        // Used for Place authority database
        case 'place':
          var pEntries = parsePlaceEntry(entry);
          for (var pEntry in pEntries) {
            sb.writeln(',');
            var entryJSON = formatPlaceEntry(pEntry, hwid);
            sb.write(entryJSON);
            hwid++;
          }
          break;
        // Used for all others, mostly Chinese dictionaries
        default:
          var pEntries = parseEntry(entry);
          for (var pEntry in pEntries) {
            sb.writeln(',');
            var entryJSON = formatEntry(pEntry, hwid);
            sb.write(entryJSON);
            hwid++;
          }
      }
    }
    sb.writeln(']');
    var outFile = File(outFName);
    outFile.writeAsString(sb.toString());
    print('Wrote ${hwid - hwStart} entries to $outFName');
  } catch (e) {
    print('Could not parse file, error: $e');
    rethrow;
  }
}
