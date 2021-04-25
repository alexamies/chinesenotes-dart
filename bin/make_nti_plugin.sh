#! /usr/bin/bash
echo 'Making the NTI Reader Chrome Plugin'
DART_HOME=$HOME/development/flutter/bin/cache/dart-sdk
NTI_READER_HOME=../buddhist-dictionary
CNOTES_DART_HOME=$PWD
$DART_HOME/bin/dart2js --csp -o ntireader-chrome-ext/main.dart.js web/main.dart
$DART_HOME/bin/dart2js --csp -o ntireader-chrome-ext/serviceworker_ext.dart.js web/serviceworker_ext.dart
$DART_HOME/bin/dart2js --csp -o ntireader-chrome-ext/content.dart.js web/content.dart
cd $NTI_READER_HOME
bin/make_downloads.sh
python3 bin/tsv2json.py "data/dictionary/fgs_mwe.txt" fgs_mwe.json \
  "Fo Guang Shan Glossary of Humnastic Buddhism" "HB Glossary" "FGS" "Copyright Fo Guang Shan"
cd $CNOTES_DART_HOME
cp $NTI_READER_HOME/downloads/ntireader_words.json ntireader-chrome-ext/.
cp $NTI_READER_HOME/downloads/buddhist_named_entities.json ntireader-chrome-ext/.
cp $NTI_READER_HOME/downloads/translation_memory_buddhist.json ntireader-chrome-ext/.
mv $NTI_READER_HOME/fgs_mwe.json ntireader-chrome-ext/.
cd ntireader-chrome-ext
zip ntireader-chrome-ext.zip *.js* *.json *.html *.css images/*
cd ..
mv ntireader-chrome-ext/ntireader-chrome-ext.zip archive/