/// A library to process Chinese text.
///
/// The library lookups Chinese terms in dictionaries in both forward and
/// reverse directions.
import 'dart:html';

import 'package:chinesenotes/chinesenotes.dart';

const maxSenses = 10;

class AppConfig {
  final String contextMenuText;
  final bool multiLingualIndex;
  final DictionarySources sources;

  AppConfig(this.contextMenuText, this.multiLingualIndex, this.sources);

  AppConfig.fromJson(var obj)
      : contextMenuText = obj['contextMenuText'],
        multiLingualIndex =
            obj['multiLingualIndex'] != null ? obj['multiLingualIndex'] : false,
        sources = DictionarySources.fromJson(obj['sources']) {}
}

void displayLookup(QueryResults results, Element? cnOutput, Element? div,
    Element? statusDiv, Element? errorDiv, Element? textField) {
  print('Showing results for ${results.query}, found ${results.terms.length} '
      'term(s) ${results.msg}');
  div?.children = [];
  if (textField == null) {
    var queryDiv = DivElement();
    queryDiv.text = 'Showing results for ${results.query} ${results.msg}';
    div?.children.add(queryDiv);
  }
  try {
    for (var term in results.terms) {
      var dictEntries = term.entries;
      print('Showing term ${term.query}, found ${dictEntries.length} entries');
      if (dictEntries.length > 0) {
        if (results.terms.length == 1) {
          var counttDiv = DivElement();
          counttDiv.className = 'counttDiv';
          if (dictEntries.length == 1) {
            counttDiv.text = 'Found 1 entry.';
          } else {
            counttDiv.text = 'Found ${dictEntries.length} entries.';
          }
          div?.children.add(counttDiv);
        }

        // If more than one term, then use a twistie
        Element entryDiv = DivElement();
        if (results.terms.length > 1) {
          entryDiv = DetailsElement();
          (entryDiv as DetailsElement).open = true;
        }
        print('displayLookup: adding results to ${div?.id}');
        div?.children.add(entryDiv);
        for (var ent in dictEntries.entries) {
          var hwDiv = DivElement();
          hwDiv.text = ent.hwRollup;
          hwDiv.className = 'dict-entry-headword';
          if (results.terms.length > 1) {
            var summaryElem = document.createElement("summary");
            summaryElem.children.add(hwDiv);
            entryDiv.children.add(summaryElem);
          } else {
            entryDiv.children.add(hwDiv);
          }
          var senses = ent.getSenses().senses;
          if (senses.length == 1) {
            var sense = senses.first;
            var senseDiv = DivElement();
            var sensePrimary = DivElement();
            var pinyinSpan = SpanElement();
            pinyinSpan.className = 'cnnotes-pinyin';
            pinyinSpan.text = '${sense.pinyin} ';
            sensePrimary.children.add(pinyinSpan);
            var posSpan = SpanElement();
            posSpan.className = 'dict-entry-grammar';
            posSpan.text = '${sense.grammar} ';
            sensePrimary.children.add(posSpan);
            var engSpan = SpanElement();
            engSpan.className = 'dict-entry-definition';
            engSpan.text = '${sense.english} ';
            sensePrimary.children.add(engSpan);
            senseDiv.children.add(sensePrimary);
            var notesDiv = DivElement();
            notesDiv.className = 'dict-entry-notes-content';
            notesDiv.text = sense.notes;
            senseDiv.children.add(notesDiv);
            entryDiv.children.add(senseDiv);
          } else {
            var senseOL = OListElement();
            for (var sense in ent.getSenses().senses) {
              var senseLi = LIElement();
              var sensePrimary = DivElement();
              var pinyinSpan = SpanElement();
              pinyinSpan.className = 'cnnotes-pinyin';
              pinyinSpan.text = '${sense.pinyin} ';
              sensePrimary.children.add(pinyinSpan);
              var posSpan = SpanElement();
              posSpan.className = 'dict-entry-grammar';
              posSpan.text = '${sense.grammar} ';
              sensePrimary.children.add(posSpan);
              var engSpan = SpanElement();
              engSpan.className = 'dict-entry-definition';
              engSpan.text = '${sense.english} ';
              sensePrimary.children.add(engSpan);
              senseLi.children.add(sensePrimary);
              var notesDiv = DivElement();
              notesDiv.className = 'dict-entry-notes-content';
              notesDiv.text = sense.notes;
              senseLi.children.add(notesDiv);
              senseOL.children.add(senseLi);
            }
            entryDiv.children.add(senseOL);
          }
          var sourceAbbrev = results.sourceAbbrev[ent.headwordId];
          if (sourceAbbrev != null && sourceAbbrev.isNotEmpty) {
            var sourceDiv = DivElement();
            sourceDiv.className = 'dict-entry-source';
            sourceDiv.text = 'Source: ${sourceAbbrev}';
            entryDiv.children.add(sourceDiv);
          }
        }
      } else if (term.senses.senses.length > 0) {
        var counttDiv = DivElement();
        counttDiv.className = 'counttDiv';
        var numFound = term.senses.senses.length;
        if (numFound == 1) {
          counttDiv.text = 'Found 1 sense.';
        } else {
          if (numFound <= maxSenses) {
            counttDiv.text = 'Found ${numFound} senses.';
          } else {
            counttDiv.text = 'Found ${numFound} senses, showing ${maxSenses}.';
          }
        }
        div?.children.add(counttDiv);
        var ul = UListElement();
        div?.children.add(ul);
        var numAdded = 0;
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
          var posSpan = SpanElement();
          posSpan.className = 'dict-entry-grammar';
          posSpan.text = '${sense.grammar} ';
          secondaryDiv.children.add(posSpan);
          var engSpan = SpanElement();
          engSpan.className = 'dict-entry-definition';
          engSpan.text = '${sense.english} ';
          secondaryDiv.children.add(engSpan);
          li.children.add(secondaryDiv);
          var notesDiv = DivElement();
          notesDiv.className = 'dict-notes-div';
          var notesSpan = SpanElement();
          notesSpan.className = 'dict-entry-notes-content';
          if (sense.notes != '') {
            notesSpan.text = 'Notes: ${sense.notes} ';
          }
          notesDiv.children.add(notesSpan);
          var sourceSpan = SpanElement();
          sourceSpan.className = 'dict-sense-source';
          var sourceAbbrev = results.sourceAbbrev[sense.hwid];
          if (sourceAbbrev != null && sourceAbbrev != '') {
            sourceSpan.text = 'Source: ${sourceAbbrev}';
            notesDiv.children.add(sourceSpan);
          }
          li.children.add(notesDiv);
          ul.children.add(li);
          numAdded++;
          if (numAdded >= maxSenses) {
            break;
          }
        }
      } else {
        div?.text = 'Did not find any results.';
      }
      statusDiv?.text = '';
    }
  } catch (e) {
    errorDiv?.text = 'Unable to load dictionary';
    statusDiv?.text = 'Try a hard refresh of the page and search again';
    print('Unable to load dictionary, error: $e');
  }
  openDialog(cnOutput);
}

void openDialog(
  Element? cnOutput,
) {
  cnOutput?.style.top = '200px';
  cnOutput?.style.left = '300px';
  cnOutput?.style.display = 'block';
}
