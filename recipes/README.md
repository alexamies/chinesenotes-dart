# Chrome Extension Recipes

With the recipe given here you can create your own Chrome extensions. Examples
use the TEI dictionary files at 

<a href='http://authority.dila.edu.tw/'>Buddhist Studies Authority Database Project</a>

## Setup

This directory contains instructions for building new applications and browser
extensions.

Prequisites: Linux or compatible environment with Bash shell.

Set the Dart SDK home with the environment variable DART_HOME. For example,

```shell
DART_HOME=$HOME/development/flutter/bin/cache/dart-sdk
```

## Headword ID Ranges

The Chinese Notes code framework can combine entries from multiple souce
dictionaries into the same bundle. In order to index these uniquely, headword
IDs are assigned to each entry. Since most dictionary sources are just lists of
words, the headword IDs are generated when the JSON file is created. In order
to do this without collisions ranges are set aside in advance.

| Source                               | Range                   |
|--------------------------------------|-------------------------|
| Base dictionary                      |          2 -    999,999 |
| FGS Humanistic Buddhism Glossary     |  1,000,002 -  1,999,999 |
| Buddhist quotations                  |  2,00,0002 -  2,999,999 |
| Literary Chinese quotations          |  3,000,002 -  3,999,999 |
| FGS Humanistic Buddhism quotations   |  4,000,002 -  4,999,999 |
| Modern Chinese quotations            |  5,000,002 -  5,999,999 |
| Modern named entities                |  6,000,002 -  6,999,999 |
| Buddhist named entities              |  7,000,002 -  7,999,999 |
| Buddhist terminology                 |  8,000,002 -  8,999,999 |
| Mahāvyutpatti                        | 10,000,002 - 10,099,999 |
| Soothill-Hodous                      | 10,100,002 - 10,199,999 |
| Glosary of Asta (Lokaksema)          | 10,200,002 - 10,299,999 |
| Glosary of Dīrgha-āgama              | 10,300,002 - 10,399,999 |
| Glosary of Lotus Sūtra (Kumārajīva)  | 10,400,002 - 10,499,999 |
| Glosary of Lotus Sūtra (Dharmarakṣa) | 10,500,002 - 10,599,999 |
| DDBC Person Authority Database       | 10,600,002 - 10,699,999 |
| DDBC Place Authority Database        | 10,700,002 - 10,699,999 |

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
SOURCE_ZIP=${SOURCE}.dila.tei.p5.xml.zip
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
SOURCE_XML=${SOURCE}.xml
TARGET_JSON=${SOURCE}.json
dart tools/parse_tei.dart \
  -s data/${SOURCE_XML} \
  -t ${TARGET_DIR}/${TARGET_JSON} \
  -l "chinese" \
  -n "A Glossary of Lokakṣema's Translation of the Aṣṭasāhasrikā Prajñāpāramitā" \
  -x "Lokakṣema" \
  -a "Seishi Karashima" \
  -y "Copyright by author" \
  -h 10200002
```

Add a Chrome extension manifest file using the template in this directory

```shell
cp recipe/manifest.json ${TARGET_DIR}/
```

Edit the `manifest.json` file, entering the values for your extension or use
the ready-made one here:

```shell
cp recipe/lokaksema_manifest.json ${TARGET_DIR}/manifest.json
```

Compile the Dart code with the JavaScript placed in the extension directory:

```shell
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/main.dart.js web/main.dart
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/serviceworker_ext.dart.js web/serviceworker_ext.dart
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/content.dart.js web/content.dart
```

Add other files for icon images and CSS styles with the commands:

```shell
mkdir $TARGET_DIR/images
cp ntireader-chrome-ext/styles.css $TARGET_DIR/
cp ntireader-chrome-ext/images/icon16.png $TARGET_DIR/images/
cp ntireader-chrome-ext/images/icon32.png $TARGET_DIR/images/
cp ntireader-chrome-ext/images/icon48.png $TARGET_DIR/images/
cp ntireader-chrome-ext/images/icon128.png $TARGET_DIR/images/
```

There is also an application configuration file that tells the 
[service worker](https://developers.google.com/web/fundamentals/primers/service-workers)
how to load the dictionary file. Copy a template with this command

```shell
cp recipe/config.json $TARGET_DIR/
```

and edit it to be suitable for the particular extension that you are creating.

There is also a popup file which allows the extension to be used indepdently of
an external web page. Copy it

```shell
cp recipe/popup.html $TARGET_DIR/
```

That is sufficient to create all the resources needed by the extension.
To load the extension in Chrome, first enable Develop mode in Chrome extensions.
Then load the unpacked extension. You can now test the extension. A screenshot
is shown below:

![](../drawings/lokaksema-chrome-ext-dialog.png?raw=true)

Zip it up for submission to the Chrome Store with the command

```shell
VERSION=0.0.1
BUNDLE=${SOURCE}-chrome-ext-${VERSION}.zip
cd $TARGET_DIR
zip ${BUNDLE} *.js* *.json *.html *.css images/*
cd ..
mkdir archive
mv $TARGET_DIR/${BUNDLE} archive/
```

### Soothill-Hodous

This section includes the recipe for 
[Soothill-Hodous: A Dictionary of Chinese Buddhist Terms](https://glossaries.dila.edu.tw/glossaries/SHH?locale=en)

Download the TEI file

```shell
SOURCE=soothill-hodous
SOURCE_ZIP=${SOURCE}.ddbc.tei.p5.xml.zip
curl -k -o data/${SOURCE_ZIP}  https://glossaries.dila.edu.tw/data/${SOURCE_ZIP}
```

Follow the instructions above. Then create a JSON bundle

```shell
SOURCE_XML=ddbc.soothill-hodous.tei.p5.xml
TARGET_DIR=$SOURCE
TARGET_JSON=${SOURCE}.json
dart tools/parse_tei.dart \
  -s data/${SOURCE_XML} \
  -t ${TARGET_DIR}/${TARGET_JSON} \
  -l "chinese" \
  -n "Soothill-Hodous: A Dictionary of Chinese Buddhist Terms" \
  -x "Soothill-Hodous" \
  -a "William Edward Soothill and Lewis Hodous, Digitization, editorial changes and preface Charles Muller" \
  -y "Copyright by authors" \
  -h 10100002
```

The manifest:

```shell
cp  recipe/${SOURCE}_manifest.json  $TARGET_DIR/manifest.json
```

Use the NTI icons

Add other files for icon images and CSS styles with the commands:

```shell
mkdir $TARGET_DIR/images
cp ntireader-chrome-ext/styles.css $TARGET_DIR/
cp ntireader-chrome-ext/images/icon16.png $TARGET_DIR/images/
cp ntireader-chrome-ext/images/icon32.png $TARGET_DIR/images/
cp ntireader-chrome-ext/images/icon48.png $TARGET_DIR/images/
cp ntireader-chrome-ext/images/icon128.png $TARGET_DIR/images/
```

Configuration file

```shell
cp recipe/${SOURCE}_config.json $TARGET_DIR/config.json
```

Popup file

```shell
cp recipe/${SOURCE}_popup.html $TARGET_DIR/popup.html
```

Zip it up for archiving with the command

```shell
VERSION=0.0.1
BUNDLE=${SOURCE}-chrome-ext-${VERSION}.zip
cd $TARGET_DIR
zip ${BUNDLE} *.js* *.json *.html *.css images/*
cd ..
mkdir archive
mv $TARGET_DIR/${BUNDLE} archive/
```

### Dīrgha-āgama

This section includes the recipe for 
[Seishi Karashima: 「長阿含経」の原語の研究 (A study of the language of the Dīrgha-āgama)](https://glossaries.dila.edu.tw/glossaries/DAT?locale=en)

Download the TEI file

```shell
SOURCE_ZIP=Study_Dirgha-agama_language.xml.zip
curl -k -o data/${SOURCE_ZIP}  https://glossaries.dila.edu.tw/data/${SOURCE_ZIP}
```

Follow the instructions above to unbundle. Then create a JSON bundle

```shell
SOURCE=dirgha-agama
TARGET_DIR=$SOURCE
TARGET_JSON=${SOURCE}.json
SOURCE_XML=Study_Dirgha-agama_language.xml
mkdir $TARGET_DIR
dart tools/parse_tei.dart \
  -s data/${SOURCE_XML} \
  -t ${TARGET_DIR}/${TARGET_JSON} \
  -l "pali-sanskrit" \
  -n "A Study of the Language of the Dīrgha-āgama (1994)" \
  -x "Dīrgha-āgama" \
  -a "Seishi Karashima" \
  -y "Copyright by author" \
  -h 10300002
```

The manifest:

```shell
cp  recipe/${SOURCE}_manifest.json  $TARGET_DIR/manifest.json
```

As above for JavaScript compilation and icons.

Configuration file

```shell
cp recipe/${SOURCE}_config.json $TARGET_DIR/config.json
```

Popup file

```shell
cp recipe/${SOURCE}_popup.html $TARGET_DIR/popup.html
```

Zip it up for archiving with the command

```shell
VERSION=0.0.1
BUNDLE=${SOURCE}-chrome-ext-${VERSION}.zip
cd $TARGET_DIR
zip ${BUNDLE} *.js* *.json *.html *.css images/*
cd ..
mkdir archive
mv $TARGET_DIR/${BUNDLE} archive/
```

### Glossary of Kumārajīva's Translation of The Lotus Sutra

This section includes the recipe for 
[Glossary of Kumārajīva's Translation of The Lotus Sutra)]https://glossaries.dila.edu.tw/glossaries/KKJ?locale=en)
by Seishi Karashima (2001).

Download the TEI file

```shell
SOURCE_ZIP=kumarajiva.dila.tei.p5.xml.zip
curl -k -o data/${SOURCE_ZIP}  https://glossaries.dila.edu.tw/data/${SOURCE_ZIP}
```

Follow the instructions above to unbundle. Then create a JSON bundle

```shell
SOURCE=kumarajiva-lotus
TARGET_DIR=$SOURCE
TARGET_JSON=${SOURCE}.json
SOURCE_XML=kumarajiva.dila.tei.p5.xml
mkdir $TARGET_DIR
dart tools/parse_tei.dart \
  -s data/${SOURCE_XML} \
  -t ${TARGET_DIR}/${TARGET_JSON} \
  -l "chinese" \
  -n "A Glossary of Kumārajīva's translation of the Lotus Sūtra (2001)" \
  -x "Glossary of the Lotus Sūtra (Kumārajīva)" \
  -a "Seishi Karashima" \
  -y "Copyright by author" \
  -h 10400002
```

The manifest:

```shell
cp  recipe/${SOURCE}_manifest.json  $TARGET_DIR/manifest.json
```

As above for JavaScript compilation and icons.

Configuration file

```shell
cp recipe/${SOURCE}_config.json $TARGET_DIR/config.json
```

Popup file

```shell
cp recipe/${SOURCE}_popup.html $TARGET_DIR/popup.html
```

Zip it up for archiving with the command

```shell
VERSION=0.0.1
BUNDLE=${SOURCE}-chrome-ext-${VERSION}.zip
cd $TARGET_DIR
zip ${BUNDLE} *.js* *.json *.html *.css images/*
cd ..
mkdir archive
mv $TARGET_DIR/${BUNDLE} archive/
```
### Glossary of Dharmarakṣa's Translation of The Lotus Sutra

This section includes the recipe for 
[A Glossary of Dharmarakṣa's Translation of the Lotus Sūtra)]https://glossaries.dila.edu.tw/glossaries/KKJ?locale=en)
by Seishi Karashima (1998).

Download the TEI file

```shell
SOURCE_ZIP=dharmaraksa.dila.tei.p5.xml.zip
curl -k -o data/${SOURCE_ZIP}  https://glossaries.dila.edu.tw/data/${SOURCE_ZIP}
```

Follow the instructions above to unbundle. Then create a JSON bundle

```shell
SOURCE=dharmaraksa-lotus
TARGET_DIR=$SOURCE
TARGET_JSON=${SOURCE}.json
SOURCE_XML=dharmaraksa.dila.tei.p5.xml
mkdir $TARGET_DIR
dart tools/parse_tei.dart \
  -s data/${SOURCE_XML} \
  -t ${TARGET_DIR}/${TARGET_JSON} \
  -l "chinese" \
  -n "A Glossary of Dharmarakṣa's translation of the Lotus Sūtra (1998)" \
  -x "Glossary of the Lotus Sūtra (Dharmarakṣa)" \
  -a "Seishi Karashima" \
  -y "Copyright by author" \
  -h 10500002
```

The manifest:

```shell
cp  recipe/${SOURCE}_manifest.json $TARGET_DIR/manifest.json
```

As above for JavaScript compilation and icons.

Configuration file

```shell
cp recipe/${SOURCE}_config.json $TARGET_DIR/config.json
```

Popup file

```shell
cp recipe/${SOURCE}_popup.html $TARGET_DIR/popup.html
```

Zip it up for archiving with the command

```shell
VERSION=0.0.1
BUNDLE=${SOURCE}-chrome-ext-${VERSION}.zip
cd $TARGET_DIR
zip ${BUNDLE} *.js* *.json *.html *.css images/*
cd ..
mkdir archive
mv $TARGET_DIR/${BUNDLE} archive/
```

### Buddhist Person and Place Authority Databases

Thanks to Dharma Drum for creating the <a href='http://authority.dila.edu.tw/'
>Buddhist Studies Authority Database</a> and making the 
<a href='http://authority.dila.edu.tw/docs/open_content/download.php'
>Open Content<a> freely available (also at the
<a href='https://github.com/DILA-edu/Authority-Databases'
>Authority-Databases</a> Github project).

Download the Person ZIP file

```shell
SOURCE_ZIP=authority_person.2021-05.zip
curl -o data/${SOURCE_ZIP}  http://authority.dila.edu.tw/downloads/${SOURCE_ZIP}
cd data
unzip ${SOURCE_ZIP}
cd ..
```

Create a JSON bundle for the Person authority database:

```shell
TARGET_DIR=authority
mkdir $TARGET_DIR
SOURCE=person-authority
SOURCE_XML=Buddhist_Studies_Person_Authority.xml
TARGET_JSON=${SOURCE}.json
dart tools/parse_tei.dart \
  -s data/${SOURCE_XML} \
  -t ${TARGET_DIR}/${TARGET_JSON} \
  -l "person" \
  -n "DDBC Person Authority Database" \
  -x "Person Authority" \
  -a "Dharma Drum Buddhist College" \
  -y "Creative Commons Attribution-ShareAlike 3.0 Unported" \
  -h 10600002
```

TODO: Pinyin and aka indexes.

Download the Place ZIP file

```shell
SOURCE_ZIP=authority_place.2021-05.zip
curl -o data/${SOURCE_ZIP}  http://authority.dila.edu.tw/downloads/${SOURCE_ZIP}
cd data
unzip ${SOURCE_ZIP}
cd ..
```

Create a JSON bundle for the Place authority database:

```shell
SOURCE=place-authority
TARGET_DIR=authority
TARGET_JSON=${SOURCE}.json
SOURCE_XML=Buddhist_Studies_Place_Authority.xml
dart tools/parse_tei.dart \
  -s data/${SOURCE_XML} \
  -t ${TARGET_DIR}/${TARGET_JSON} \
  -l "place" \
  -n "DDBC Place Authority Database" \
  -x "Place Authority" \
  -a "Dharma Drum Buddhist College" \
  -y "Creative Commons Attribution-ShareAlike 3.0 Unported" \
  -h 10700002
```

The manifest:

```shell
cp  recipe/${TARGET_DIR}_manifest.json $TARGET_DIR/manifest.json
```

Config file:

```shell
cp recipe/${TARGET_DIR}_config.json $TARGET_DIR/config.json
```

Popup file

```shell
cp recipe/${TARGET_DIR}_popup.html $TARGET_DIR/popup.html
```

Add CSS styles:

```shell
cp ntireader-chrome-ext/styles.css $TARGET_DIR/
```

Zip it up for archiving with the command

```shell
VERSION=0.0.1
BUNDLE=${TARGET_DIR}-chrome-ext-${VERSION}.zip
cd $TARGET_DIR
zip ${BUNDLE} *.js* *.json *.html *.css
cd ..
mkdir archive
mv $TARGET_DIR/${BUNDLE} archive/
```
