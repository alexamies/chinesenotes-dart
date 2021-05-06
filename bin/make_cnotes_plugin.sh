#! /usr/bin/bash
echo 'Making the Chinese Notes Chrome Plugin'
VERSION=0.0.5
DART_HOME=$HOME/development/flutter/bin/cache/dart-sdk
CNOTES_READER_HOME=../chinesenotes.com
CNOTES_DART_HOME=$PWD
EXT_HOME=chrome-ext
cd $CNOTES_READER_HOME
bin/make_downloads.sh
cd $CNOTES_DART_HOME
cp $CNOTES_READER_HOME/downloads/chinesenotes_words.json $EXT_HOME/.
cp $CNOTES_READER_HOME/downloads/modern_named_entities.json $EXT_HOME/.
$DART_HOME/bin/dart2js --csp -O2 -o $EXT_HOME/main.dart.js web/main.dart
$DART_HOME/bin/dart2js --csp -O2 -o $EXT_HOME/serviceworker_ext.dart.js web/serviceworker_ext.dart
$DART_HOME/bin/dart2js --csp -O2 -o $EXT_HOME/content.dart.js web/content.dart
cd $EXT_HOME
zip chinesenotes-ext-${VERSION}.zip *.js *.json *.html *.css images/*
cd ..
mv chrome-ext/chinesenotes-ext-${VERSION}.zip downloads/
