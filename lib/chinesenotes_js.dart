/// A library to process Chinese text.
///
/// The library lookups Chinese terms in dictionaries in both forward and
/// reverse directions.
library chinesenotes_html;

import 'dart:js';

import 'package:chinesenotes/chinesenotes.dart';

DictionaryEntry dictionaryEntryFromJson(var obj) {
  String headword = obj['headword'];
  int headwordId = obj['headwordId'];
  int sourceId = obj['sourceId'];
  var senses = sensesFromJson(obj['senses']);
  return DictionaryEntry(headword, headwordId, sourceId, senses);
}

DictionaryEntries dictionaryEntriesFromJson(var obj) {
  String headword = obj['headword'];
  var entriesObj = obj['entries'];
  if (!(entriesObj is JsArray)) {
    return DictionaryEntries(headword, []);
  }
  JsArray entriesArray = entriesObj;
  List<DictionaryEntry> entries = [];
  for (var entryObj in entriesArray) {
    var entry = dictionaryEntryFromJson(entryObj);
    entries.add(entry);
  }
  return DictionaryEntries(headword, entries);
}

QueryResults queryResultsFromJson(var obj) {
  String query = obj['query'];
  List<Term> terms = [];
  var termsObj = obj['terms'];
  if (!(termsObj is JsArray)) {
    return QueryResults(query, []);
  }
  JsArray termsArray = termsObj;
  for (var tObj in termsArray) {
    var term = termFromJson(tObj);
    terms.add(term);
  }
  return QueryResults(query, terms);
}

Sense senseFromJson(var obj) {
  int luid = obj['luid'];
  int hwid = obj['hwid'];
  String simplified = obj['simplified'];
  String traditional = obj['traditional'];
  String pinyin = obj['pinyin'];
  String english = obj['english'];
  String grammar = obj['grammar'];
  String notes = obj['notes'];
  return Sense(
      luid, hwid, simplified, traditional, pinyin, english, grammar, notes);
}

Senses sensesFromJson(var obj) {
  var sensesObj = obj['senses'];
  if (!(sensesObj is JsArray)) {
    return Senses([]);
  }
  JsArray sensesArray = sensesObj;
  List<Sense> senses = [];
  for (var senseObj in sensesArray) {
    var sense = senseFromJson(senseObj);
    senses.add(sense);
  }
  return Senses(senses);
}

Term termFromJson(var obj) {
  String query = obj['query'];
  var entries = dictionaryEntriesFromJson(obj['entries']);
  var senses = sensesFromJson(obj['senses']);
  return Term(query, entries, senses);
}
