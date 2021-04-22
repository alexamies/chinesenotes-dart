/// A library to process Chinese text.
///
/// The library lookups Chinese terms in dictionaries in both forward and
/// reverse directions.
library chinesenotes_html;

import 'dart:html';
import 'dart:js';

import 'package:chinesenotes/chinesenotes.dart';

const maxSenses = 10;

void displayLookup(
    QueryResults results,
    Element? cnOutput,
    Element? div,
    Element? statusDiv,
    Element? errorDiv,
    Element? textField,
    DictionarySources sources) {
  print('displayLookup, ${results.query}');
  div?.children = [];
  try {
    print('displayLookup, got ${results.terms.length} terms');
    for (var term in results.terms) {
      var dictEntries = term.entries;
      print('displayLookup, got ${dictEntries.length} entries');
      if (dictEntries.length > 0) {
        var counttDiv = DivElement();
        counttDiv.className = 'counttDiv';
        if (dictEntries.length == 1) {
          counttDiv.text = 'Found 1 entry.';
        } else {
          counttDiv.text = 'Found ${dictEntries.length} entries.';
        }
        div?.children.add(counttDiv);
        var entryDiv = DivElement();
        div?.children.add(entryDiv);
        for (var ent in dictEntries.entries) {
          var hwDiv = DivElement();
          hwDiv.text = ent.hwRollup;
          hwDiv.className = 'dict-entry-headword';
          entryDiv.children.add(hwDiv);
          var ul = UListElement();
          entryDiv.children.add(ul);
          var li = LIElement();
          var senseOL = OListElement();
          for (var sense in ent.senses.senses) {
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
          li.children.add(senseOL);
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
          var source = sources.lookup(sense.hwid);
          sourceSpan.text = 'Source: ${source.abbreviation}';
          notesDiv.children.add(sourceSpan);
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
  openDialog(cnOutput, textField, results.query);
}

void openDialog(Element? cnOutput, Element? textfield, String query) {
  if (textfield != null) {
    var tf = textfield as TextInputElement;
    tf.value = query;
  }
  cnOutput?.style.top = '200px';
  cnOutput?.style.left = '300px';
  cnOutput?.style.display = 'block';
}
