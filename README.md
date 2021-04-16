# Chinese Notes Dictionary App

App for the Chinese Notes Chinese-English dictionary in Dart.

Add a Chinese-English dictionary to your website or web app with no backend
application server or database required. This includes a Dart API.

Status: Experimental, will probably change.

## Quickstart

Clone the GitHub repo:

```shell
git clone https://github.com/alexamies/chinesenotes-dart.git
```

Setup your Dart environment. See
[Get started: web apps](https://dart.dev/tutorials/web/get-started).

A sample web app is provided in the `web` directory. It uses a sample dictionary
to avoid CORS problems when getting started. To start the web app type

```shell
webdev serve
```

There are only two entries in the sample dictionary: 围 (traditioal 圍) surround
and 玫瑰 rose (Scientific name: Rosa rugosa).

## Using the Dart API in Production

To use the Dart API, add `chinesenotes` to `pubspec.yaml`:

```yaml
dependencies:
  chinesenotes: ^0.0.1
```

Update your depenendencies with the command:

```shell
dart pub get
```

Copy the latest versions of the dictionary files to your site with the commands

```shell
curl -o web/chinesenotes_words.json https://raw.githubusercontent.com/alexamies/chinesenotes.com/master/downloads/chinesenotes_words.json
curl -o web/modern_named_entities.json https://raw.githubusercontent.com/alexamies/chinesenotes.com/master/downloads/modern_named_entities.json
curl -o web/translation_memory_literary.json https://raw.githubusercontent.com/alexamies/chinesenotes.com/master/downloads/translation_memory_literary.json
curl -o web/translation_memory_modern.json https://raw.githubusercontent.com/alexamies/chinesenotes.com/master/downloads/translation_memory_modern.json
```

There are some Buddhist dictionaries in JSON format that can be downloaded from
https://github.com/alexamies/buddhist-dictionary/tree/master/downloads

### Calling from JavaScript

See [JavaScript interoperability](https://dart.dev/web/js-interop).

## Using the Web Example in Production

Set your Dart SDK home directory in an environment variable

```shell
DART_HOME=[your dart home]
```

If you have installed Flutter, it may be somewhere like

```shell
DART_HOME=$HOME/flutter/bin/cache/dart-sdk
```

Compile `web/main.dart` to JavaScript with the command

```shell
$DART_HOME/bin/dart2js -o main.dart.js web/main.dart 
```

Copy the most up-to-date dictionary from the URLs at chinesenotes.cnotesJson or 
chinesenotes.ntiReaderJson to your web server. Makes the styles in the
index.html page and styles.css match your web site. Follow instructions at
[Web deployment](https://dart.dev/web/deployment).


## Native App Example

See an example for a natively installed or mobile app under `example/main.dart`.
To run it type

```shell
dart run example/main.dart
```