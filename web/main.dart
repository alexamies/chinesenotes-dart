import 'dart:html';

import 'package:chinesenotes/chinesenotes.dart';

DictionarySources getSources() {
  const sourceNums = [1, 2, 3, 4, 5];
  Map<int, DictionarySource> sources = {};
  for (var sourceNum in sourceNums) {
    var nameID = '#sourceName${sourceNum}';
    var sourceCB = querySelector(nameID);
    if (sourceCB != null) {
      var cb = sourceCB as CheckboxInputElement;
      var tokens = cb.value;
      if (tokens != null) {
        var sourceTokens = tokens.split(',');
        var urlID = '#sourceURL${sourceNum}';
        var sourceTF = querySelector(urlID) as CheckboxInputElement;
        var sourceURL = sourceTF.value!;
        sources[sourceNum] = DictionarySource(
            sourceNum,
            sourceURL,
            sourceTokens[1],
            sourceTokens[2],
            sourceTokens[3],
            sourceTokens[4],
            sourceTokens[5]);
      }
    }
  }
  return DictionarySources(sources);
}

void main() async {
  print('Starting client app');
  var lookupSubmit = querySelector('#lookupSubmit') as ButtonElement;
  var errorDiv = querySelector('#lookupError')!;
  var statusDiv = querySelector('#status')!;
  statusDiv.text = 'Loading dictionary';

  try {
    var sources = getSources();
    List<DictionaryCollectionIndex> forwardIndexes = [];
    List<HeadwordIDIndex> hwIDIndexes = [];
    for (var source in sources.sources.values) {
      final jsonString = await HttpRequest.getString(source.url);
      var forwardIndex = dictFromJson(jsonString, source);
      forwardIndexes.add(forwardIndex);
      var hwIDIndex = headwordsFromJson(jsonString, source);
      hwIDIndexes.add(hwIDIndex);
    }
    lookupSubmit.disabled = false;
    statusDiv.text = 'Dictionary loaded';

    var mergedFwdIndex = mergeDictionaries(forwardIndexes);
    var mergedHwIdIndex = mergeHWIDIndexes(hwIDIndexes);
    var reverseIndex = buildReverseIndex(mergedFwdIndex);
    var app = App(mergedFwdIndex, sources, reverseIndex, mergedHwIdIndex);

    var textField = querySelector('#lookupInput') as TextInputElement;
    var div = querySelector('#lookupResults')!;

    void lookup(Event evt) {
      div.children = [];
      var results = app.lookup(textField.value!);
      for (var term in results.terms) {
        var dictEntries = term.entries;
        if (dictEntries.length > 0) {
          var counttDiv = DivElement();
          counttDiv.className = 'counttDiv';
          if (dictEntries.length == 1) {
            counttDiv.text = 'Found 1 entry.';
          } else {
            counttDiv.text = 'Found ${dictEntries.length} entries.';
          }
          div.children.add(counttDiv);
          var entryDiv = DivElement();
          div.children.add(entryDiv);
          for (var ent in dictEntries.entries) {
            var hwDiv = DivElement();
            hwDiv.text = ent.hwRollup;
            hwDiv.className = 'dict-entry-headword';
            entryDiv.children.add(hwDiv);
            var ul = UListElement();
            entryDiv.children.add(ul);
            var li = LIElement();
            for (var sense in ent.senses) {
              var pinyinSpan = SpanElement();
              pinyinSpan.className = 'dict-entry-pinyin';
              pinyinSpan.text = '${sense.pinyin} ';
              li.children.add(pinyinSpan);
              var engSpan = SpanElement();
              engSpan.className = 'dict-entry-equivalent';
              engSpan.text = '${sense.english} ';
              li.children.add(engSpan);
              var notesDiv = DivElement();
              notesDiv.className = 'dict-entry-notes';
              notesDiv.text = sense.notes;
              li.children.add(notesDiv);
            }
            ul.children.add(li);
            var source = sources.lookup(ent.sourceId);
            var sourceDiv = DivElement();
            sourceDiv.className = 'dict-entry-source';
            sourceDiv.text = 'Source: ${source.abbreviation}';
            entryDiv.children.add(sourceDiv);
          }
        } else if (term.senses.senses.length > 0) {
          var counttDiv = DivElement();
          counttDiv.className = 'counttDiv';
          if (dictEntries.length == 1) {
            counttDiv.text = 'Found 1 sense.';
          } else {
            counttDiv.text = 'Found ${term.senses.senses.length} senses.';
          }
          div.children.add(counttDiv);
          var ul = UListElement();
          div.children.add(ul);
          for (var sense in term.senses.senses) {
            var li = LIElement();
            var primaryDiv = DivElement();
            primaryDiv.text = sense.chinese;
            primaryDiv.className = 'dict-sense-primary';
            li.children.add(primaryDiv);
            var secondaryDiv = DivElement();
            secondaryDiv.className = 'dict-sense-secondary';
            var pinyinSpan = SpanElement();
            pinyinSpan.className = 'dict-entry-pinyin';
            pinyinSpan.text = '${sense.pinyin} ';
            secondaryDiv.children.add(pinyinSpan);
            var engSpan = SpanElement();
            engSpan.className = 'dict-entry-equivalent';
            engSpan.text = '${sense.english} ';
            secondaryDiv.children.add(engSpan);
            li.children.add(secondaryDiv);
            var notesDiv = DivElement();
            notesDiv.className = 'dict-notes-div';
            var notesSpan = SpanElement();
            notesSpan.className = 'dict-entry-notes';
            if (sense.notes != '') {
              notesSpan.text = 'Notes: ${sense.notes} ';
            }
            notesDiv.children.add(notesSpan);
            var sourceSpan = SpanElement();
            sourceSpan.className = 'dict-sense-source';
            var source = app.getSource(sense.hwid);
            if (source != null) {
              sourceSpan.text = 'Source: ${source.abbreviation}';
            }
            notesDiv.children.add(sourceSpan);
            li.children.add(notesDiv);
            ul.children.add(li);
          }
        } else {
          div.text = 'Did not find any results.';
        }
        statusDiv.text = '';
      }
      evt.preventDefault();
    }

    var findForm = querySelector('#lookupForm')!;
    findForm.onSubmit.listen(lookup);
  } catch (e) {
    errorDiv.text = 'Unable to load dictionary';
    statusDiv.text = 'Try a hard refresh of the page and search again';
    print('Unable to load dictionary, error: $e');
    rethrow;
  }
}
