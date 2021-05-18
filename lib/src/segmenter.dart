import 'package:characters/characters.dart';

/// isCJKChar tests whether the symbol is a CJK character, excluding punctuation
/// Only looks at the first charater in the string
bool isCJKChar(String ch) {
  var c = ch.characters.first;
  var cu = c.codeUnits;
  return cu.first > 646;
}

class TextSegment {
  final String text;
  final bool isChinese;

  TextSegment(this.text, this.isChinese);
}

List<TextSegment> Segment(String text) {
  List<TextSegment> segments = [];
  var cjk = '';
  var noncjk = '';
  for (var character in text.characters) {
    if (isCJKChar(character)) {
      if (noncjk != '') {
        var s = TextSegment(noncjk, false);
        segments.add(s);
        noncjk = '';
      }
      cjk += character;
    } else if (cjk != '') {
      var s = TextSegment(cjk, true);
      segments.add(s);
      cjk = '';
      noncjk += character;
    } else {
      noncjk += character;
    }
  }
  if (cjk != '') {
    var s = TextSegment(cjk, true);
    segments.add(s);
  }
  if (noncjk != '') {
    var s = TextSegment(noncjk, false);
    segments.add(s);
  }
  return segments;
}
