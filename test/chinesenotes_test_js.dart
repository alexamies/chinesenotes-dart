import 'package:test/test.dart';

import 'package:chinesenotes/chinesenotes_js.dart';

void main() {
  test('Sense.fromJson constructs a Sense object correctly.', () {
    var luid = 1;
    var hwid = 42;
    var simplified = '你好';
    var traditional = '';
    var pinyin = 'níhǎo';
    var english = 'hello';
    var grammar = 'interjection';
    var notes = 'p. 655';
    var obj = {
      'luid': luid,
      'hwid': hwid,
      'simplified': simplified,
      'traditional': traditional,
      'pinyin': pinyin,
      'english': english,
      'grammar': grammar,
      'notes': notes
    };
    var sense = senseFromJson(obj);
    var retObj = sense.toJson();
    expect(luid, retObj['luid']);
    expect(hwid, retObj['hwid']);
    expect(simplified, retObj['simplified']);
    expect(traditional, retObj['traditional']);
    expect(pinyin, retObj['pinyin']);
    expect(english, retObj['english']);
    expect(grammar, retObj['grammar']);
    expect(notes, retObj['notes']);
  });
  test('Senses.fromJson constructs a Senses object correctly.', () {
    var obj1 = {
      'luid': 1,
      'hwid': 42,
      'simplified': '你好',
      'traditional': '',
      'pinyin': 'níhǎo',
      'english': 'hello',
      'grammar': 'interjection',
      'notes': 'p. 655'
    };
    var obj2 = {
      'luid': 2,
      'hwid': 43,
      'simplified': '再见',
      'traditional': '再見',
      'pinyin': 'zàijiàn',
      'english': 'good bye',
      'grammar': 'interjection',
      'notes': 'p. 655'
    };
    var senseList = [obj1, obj2];
    var sensesObj = sensesFromJson(senseList);
    var retObj = sensesObj.toJson();
    expect(retObj.length, senseList.length);
  });
}
