# Firefox Add-On

This is currently under development

Compile

```shell
DART_HOME=$HOME/development/flutter/bin/cache/dart-sdk
EXT_HOME=firefox-addon
$DART_HOME/bin/dart2js --csp -o $EXT_HOME/background.dart.js web/background.dart
```
