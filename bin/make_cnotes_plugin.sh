#! /usr/bin/bash
echo 'Making the Chinese Notes Chrome Plugin'
DART_HOME=$HOME/development/flutter/bin/cache/dart-sdk
$DART_HOME/bin/dart2js --csp -o chrome-ext/main.dart.js web/main.dart
$DART_HOME/bin/dart2js --csp -o chrome-ext/serviceworker_ext.dart.js web/serviceworker_ext.dart
$DART_HOME/bin/dart2js --csp -o chrome-ext/content.dart.js web/content.dart
cd chrome-ext
zip chinesenotes-ext.zip *.js* *.json *.html *.css images/*
cd ..