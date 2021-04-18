#! /usr/bin/bash
echo 'Making the Chinese Notes Chrome Plugin'
$DART_HOME/bin/dart2js --csp -o chrome-ext/main.dart.js web/main.dart 
cd chrome-ext
zip chinesenotes-ext.zip *.js* *.json *.html *.css images/*
cd ..