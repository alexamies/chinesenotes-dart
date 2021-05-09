# Recipes

This directory contains instructions for building new applications and browser
extensions.

Prequisites: Linux or compatible environment with Bash shell.

Set the Dart SDK home with the environment variable DART_HOME. For example,

```shell
DART_HOME=$HOME/development/flutter/bin/cache/dart-sdk
```

## Browser Extensions with TEI files

This recipe intended for the dictionaries and glossaries at 

https://glossaries.dila.edu.tw

Here is an example for Seishi Karashima's *Glossary of Lokakṣema's Translation
of the Aṣṭasāhasrikā Prajñāpāramitā*.

Download the TEI file and place it in the `data` directory by executing
these commands from the top level directory of the project:

```shell
mkdir data
SOURCE=lokaksema
SOURCE_XML=${SOURCE}.xml
SOURCE_ZIP=${SOURCE_XML}.dila.tei.p5.xml.zip
curl -k -o data/${SOURCE_ZIP}  https://glossaries.dila.edu.tw/data/${SOURCE_ZIP}
cd data
unzip ${SOURCE_ZIP}
cd ..
```

Make a directory to place the extension

```shell
TARGET_DIR=lokaksema
mkdir $TARGET_DIR
```

Parse the TEI file and transform to JSON that can be read by the Chinese Notes
libraries.

```shell
TARGET_JSON=${SOURCE}.json
dart tools/parse_tei.dart \
  -s data/${SOURCE_XML} \
  -t ${TARGET_DIR}/${TARGET_JSON} \
  -l "chinese" \
  -n "A Glossary of Lokakṣema's Translation of the Aṣṭasāhasrikā Prajñāpāramitā" \
  -x "Lokakṣema" \
  -a "Seishi Karashima" \
  -y "Copyright by author"
```

Add a Chrome extension manifest file using the template in this directory

```shell
cp recipes/manifest.json ${TARGET_DIR}/
```

Edit the `manifest.json` file, entering the values for your extension.

Compile the Dart code with the JavaScript placed in the extension directory:

```shell
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/main.dart.js web/main.dart
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/serviceworker_ext.dart.js web/serviceworker_ext.dart
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/content.dart.js web/content.dart
```

Add other files for icon images and CSS styles with the commands:

```shell
mkdir $TARGET_DIR/images
cp web/styles.css $TARGET_DIR/
cp web/images/icon16.png $TARGET_DIR/images/
cp web/images/icon32.png $TARGET_DIR/images/
cp web/images/icon48.png $TARGET_DIR/images/
cp web/images/icon128.png $TARGET_DIR/images/
```

There is also a popup file which allows the extension to be used indepdently of
an external web page. Copy it

```shell
cp recipes/config.json $TARGET_DIR/
```

and edit it to be suitable for the particular extension that you are creating.

There is also an application configuration file that tells the 
[service worker](https://developers.google.com/web/fundamentals/primers/service-workers)
how to load the dictionary file. Copy a template with this command

```shell
cp recipes/popup.html $TARGET_DIR/
```

That is sufficient to create all the resources needed by the extension.
To load the extension in Chrome, first enable Develop mode in Chrome extensions.
Then load the unpacked extension. You can now test the extension. A screenshot
is shown below:

![](../drawings/lokaksema-chrome-ext-dialog.png?raw=true)
