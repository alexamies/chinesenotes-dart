# chinesenotes

A Chinese-English dictionary in Dart.

Add a Chinese-English dictionary to your website or web app with no backend
application server or database required. This includes a Dart API.

Status: Experimental, will probably change.

## Quickstart

Clone the GitHub repo:

```shell
git clone https://github.com/alexamies/chinesenotes-go.git
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

Enable CORS for downloading the most up-to-date dictionary from the URLs at
chinesenotes.cnotesJson (included named modern entities) or 
chinesenotes.ntiReaderJson (optimized for Buddhist texts). You can copy the
dictionary to your site if enabling CORS is hard but beware the dictionary will
be updated.

### Calling from JavaScript

See [JavaScript interoperability](https://dart.dev/web/js-interop).

## Using the Web Example in Production

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