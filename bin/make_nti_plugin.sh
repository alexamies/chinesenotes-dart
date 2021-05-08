#! /usr/bin/bash
echo 'Making the NTI Reader Chrome Plugin'
VERSION=0.0.5
DART_HOME=$HOME/development/flutter/bin/cache/dart-sdk
NTI_READER_HOME=../buddhist-dictionary
TARGET_DIR=ntireader-chrome-ext
CNOTES_DART_HOME=$PWD
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/main.dart.js web/main.dart
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/serviceworker_ext.dart.js web/serviceworker_ext.dart
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/content.dart.js web/content.dart
cd $NTI_READER_HOME
bin/make_downloads.sh
python3 bin/tsv2json.py "data/dictionary/fgs_mwe.txt" fgs_mwe.json \
  "Fo Guang Shan Glossary of Humnastic Buddhism" "HB Glossary" "FGS" "Copyright Fo Guang Shan"
cd $CNOTES_DART_HOME
cp $NTI_READER_HOME/downloads/ntireader_words.json $TARGET_DIR/.
cp $NTI_READER_HOME/downloads/buddhist_named_entities.json $TARGET_DIR/.
mv $NTI_READER_HOME/fgs_mwe.json $TARGET_DIR/.
cd $TARGET_DIR
zip ntireader-chrome-ext-${VERSION}.zip *.js* *.json *.html *.css images/*
cd ..
mv $TARGET_DIR/ntireader-chrome-ext-${VERSION}.zip downloads/
