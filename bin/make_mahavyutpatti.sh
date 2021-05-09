#! /usr/bin/bash
echo 'Making the Mahavyutpatti Chrome Plugin'
VERSION=0.0.1
DART_HOME=$HOME/development/flutter/bin/cache/dart-sdk
TARGET_DIR=mahavyutpatti-chrome-ext
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/main.dart.js web/main.dart
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/serviceworker_ext.dart.js web/serviceworker_ext.dart
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/content.dart.js web/content.dart
if [ ! -f $TARGET_DIR/mahavyutpatti.json ]; then
  mkdir data
  cd data
  curl -k -o mahavyutpatti.dila.tei.p5.xml.zip https://glossaries.dila.edu.tw/data/mahavyutpatti.dila.tei.p5.xml.zip
  unzip mahavyutpatti.dila.tei.p5.xml.zip
  cd ..
  dart tools/parse_tei.dart \
    -s 'data/mahavyutpatti.dila.tei.p5.xml' \
    -t 'mahavyutpatti-chrome-ext/mahavyutpatti.json' \
    -l "sanskrit" \
    -n "Mahāvyutpatti Sanskrit-Tibetan-Chinese dictionary" \
    -x "Mahāvyutpatti" \
    -a "" \
    -y "Copyright expired"
fi
cd $TARGET_DIR
zip mahavyutpatti-chrome-ext-${VERSION}.zip *.js* *.json *.html *.css images/*
cd ..
mv mahavyutpatti-chrome-ext/mahavyutpatti-chrome-ext-${VERSION}.zip downloads/
echo 'The Mahavyutpatti Chrome Plugin is in the downloads directory'
