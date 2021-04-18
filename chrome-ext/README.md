# Chinese-English Dictionary Browser Extension

This page describes how to use the code as a Chrome browser extension.

## Compiling the code

Set your Dart SDK home directory in an environment variable

```shell
DART_HOME=[your dart home]
```

If you have installed Flutter, it may be somewhere like

```shell
DART_HOME=$HOME/flutter/bin/cache/dart-sdk
```

From the top level directory, compile `main.dart` to JavaScript with the command

```shell
$DART_HOME/bin/dart2js --csp -o chrome-ext/main.dart.js web/main.dart 
$DART_HOME/bin/dart2js --csp -o chrome-ext/sworker.dart.js web/sworker.dart 
```

## Try it out

In developmenet deploy to the browser by loading this directory as a Chrome
extension in development mode.