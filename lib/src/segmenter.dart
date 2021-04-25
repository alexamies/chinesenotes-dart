import 'package:characters/characters.dart';

/// isCJKChar tests whether the symbol is a CJK character, excluding punctuation
/// Only looks at the first charater in the string
bool isCJKChar(String ch) {
  var c = ch.characters.first;
  var cu = c.codeUnits;
  return cu.first > 646;
}
