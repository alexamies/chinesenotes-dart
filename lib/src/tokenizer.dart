import 'package:characters/characters.dart';

import 'package:chinesenotes/chinesenotes.dart';

/// Tokenizes a Chinese string into words and other terms in the dictionary.
///
/// If the terms are not found in the dictionary then individual characters will
/// be returned.
class DictTokenizer {
  final ForwardIndex index;
  final HeadwordIDIndex hwIndex;

  DictTokenizer(
    this.index,
    this.hwIndex,
  );

  List<TextToken> tokenize(String text) {
    return _greedyLtoR(text);
  }

  /// Tokenizes text with a greedy knapsack-like algorithm, scanning left to
  /// right.
  List<TextToken> _greedyLtoR(String fragment) {
    List<TextToken> tokens = [];
    if (fragment.length == 0) {
      return tokens;
    }
    for (var i = 0; i < fragment.characters.length; i++) {
      for (var j = fragment.characters.length; j > 0; j--) {
        var w = fragment.characters.getRange(i, j);
        var result = index.lookup(hwIndex, w.string);
        if (result.entries.isNotEmpty) {
          var token = TextToken(w.string, result.entries);
          tokens.add(token);
          i = j - 1;
          j = 0;
        } else if (w.length == 1) {
          var token = TextToken(w.string, []);
          tokens.add(token);
          break;
        }
      }
    }
    return tokens;
  }
}

class TextToken {
  final String token;
  final List<DictionaryEntry> entries;

  TextToken(this.token, this.entries);
}
