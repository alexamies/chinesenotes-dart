# Chinese-English Dictionary Browser Extension

## What is the Chinese Notes Chrome Extension?

A Chinese-English dictionary 
- Simplified, Traditional, and pinyin -> English
- Also includes a base Chinese-English dictionary with many literary Chinese and
  modern Chinese terms
- Can do multiple term lookup and reverse lookup of English terms
- Like the basic function of the chinesenotes.com web site but can be installed
  as a Chrome Extension
- It can help you stay within the flow of a Chinese document, avoiding the need
  to switch back and forth between pages.
- The dictionary is well suited to literary Chinese and historic Chinese texts.

Find out more about the dictionary and sources at https://chinesenotes.com 

## Installing and Using the Extension

In Chrome, go to Extensions -> Manage extensions -> Open Chrome Web Store
Search for Chinese Notes Chinese-English Dictionary. Click and install

https://chrome.google.com/webstore/detail/chinese-notes-chinese-eng/pamihenokjbcmbinloihppkjplfdifak 

The extension package includes the dictionary, which takes about 3 seconds to
load and initialize indexes. Use it by selecting text on a page, right clicking,
and selecting Lookup with Chinese Notes ...

See screenshots in the ../drawings directory.

## Developers

This page describes how to use the code as a Chrome browser extension.

### Compiling the code

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
```

### Try it out

In developmenet deploy to the browser by loading this directory as a Chrome
extension in development mode.

### Build the Chrome Extensions

Use the scripts in the `bin` directory to build the Chrome extensions.

```shell
bin/make_cnotes_plugin.sh
```