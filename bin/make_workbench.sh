#! /usr/bin/bash
echo 'Making the Buddhist multi-dictionary workbench'
DART_HOME=$HOME/development/flutter/bin/cache/dart-sdk
NTI_READER_HOME=../buddhist-dictionary
TARGET_DIR=workbench-chrome-ext
CNOTES_DART_HOME=$PWD

# Compile the Dart code with the JavaScript placed in the extension directory
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/main.dart.js web/main.dart
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/serviceworker_ext.dart.js web/serviceworker_ext.dart
$DART_HOME/bin/dart2js --csp -o $TARGET_DIR/content.dart.js web/content.dart

# Download the TEI files and place them in the `data` directory:
if [[ ! -d $TARGET_DIR ]]; then
  mkdir $TARGET_DIR
fi
if [[ ! -d data ]]; then
  mkdir data
fi

# Copy the NTI Reader and HB Glossary files
cd $NTI_READER_HOME
bin/make_downloads.sh
python3 bin/tsv2json.py "data/dictionary/fgs_mwe.txt" fgs_mwe.json \
  "Fo Guang Shan Glossary of Humnastic Buddhism" "HB Glossary" "FGS" "Copyright Fo Guang Shan"
python3 bin/tsv2json.py "data/dictionary/fgs_mwe.txt" \
  "${CNOTES_DART_HOME}/${TARGET_DIR}/fgs_mwe.json" \
  "Fo Guang Shan Glossary of Humnastic Buddhism" "HB Glossary" "FGS" "Copyright Fo Guang Shan"
cd $CNOTES_DART_HOME
cp $NTI_READER_HOME/downloads/ntireader_words.json $TARGET_DIR/
cp $NTI_READER_HOME/downloads/buddhist_named_entities.json $TARGET_DIR/

# TEI glossary files

# Generate the Mahavyutpatti JSON file
SOURCE=mahavyutpatti
SOURCE_ZIP=mahavyutpatti.dila.tei.p5.xml.zip
SOURCE_XML=mahavyutpatti.dila.tei.p5.xml
curl -k -o data/${SOURCE_ZIP}  https://glossaries.dila.edu.tw/data/${SOURCE_ZIP}
unzip data/${SOURCE_ZIP}
TARGET_JSON=${SOURCE}.json
dart tools/parse_tei.dart \
  -s 'data/mahavyutpatti.dila.tei.p5.xml' \
  -t "${TARGET_DIR}/${SOURCE_XML}" \
  -l "sanskrit" \
  -n "Mahāvyutpatti Sanskrit-Tibetan-Chinese dictionary" \
  -x "Mahāvyutpatti" \
  -a "" \
  -y "Public domain" \
  -h "10000002"

SOURCE=soothill-hodous
SOURCE_ZIP=${SOURCE}.ddbc.tei.p5.xml.zip
curl -k -o data/${SOURCE_ZIP}  https://glossaries.dila.edu.tw/data/${SOURCE_ZIP}
unzip data/${SOURCE_ZIP}
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

SOURCE=lokaksema
SOURCE_ZIP=${SOURCE}.dila.tei.p5.xml.zip
curl -k -o data/${SOURCE_ZIP}  https://glossaries.dila.edu.tw/data/${SOURCE_ZIP}
unzip data/${SOURCE_ZIP}
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

SOURCE_ZIP=Study_Dirgha-agama_language.xml.zip
curl -k -o data/${SOURCE_ZIP}  https://glossaries.dila.edu.tw/data/${SOURCE_ZIP}
unzip data/${SOURCE_ZIP}
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

SOURCE_ZIP=kumarajiva.dila.tei.p5.xml.zip
curl -k -o data/${SOURCE_ZIP}  https://glossaries.dila.edu.tw/data/${SOURCE_ZIP}
unzip data/${SOURCE_ZIP}
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

SOURCE_ZIP=dharmaraksa.dila.tei.p5.xml.zip
curl -k -o data/${SOURCE_ZIP}  https://glossaries.dila.edu.tw/data/${SOURCE_ZIP}
unzip data/${SOURCE_ZIP}
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

# Person authority database:
SOURCE_ZIP=authority_person.2021-05.zip
curl -o data/${SOURCE_ZIP}  http://authority.dila.edu.tw/downloads/${SOURCE_ZIP}
unzip data/${SOURCE_ZIP}
TARGET_DIR=authority
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

# Place authority database
SOURCE_ZIP=authority_place.2021-05.zip
curl -o data/${SOURCE_ZIP}  http://authority.dila.edu.tw/downloads/${SOURCE_ZIP}
unzip data/${SOURCE_ZIP}
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


# Add image files for icon images and CSS styles with the commands:
mkdir $TARGET_DIR/images
cp ntireader-chrome-ext/styles.css $TARGET_DIR/
cp ntireader-chrome-ext/images/icon16.png $TARGET_DIR/images/
cp ntireader-chrome-ext/images/icon32.png $TARGET_DIR/images/
cp ntireader-chrome-ext/images/icon48.png $TARGET_DIR/images/
cp ntireader-chrome-ext/images/icon128.png $TARGET_DIR/images/

# Copy related files
cp workbench/config.json $TARGET_DIR/
cp workbench/popup.html $TARGET_DIR/

VERSION=0.0.1
BUNDLE=${SOURCE}-chrome-ext-${VERSION}.zip
zip -r ${BUNDLE} $TARGET_DIR/
if [[ ! -d $TARGET_DIR ]]; then
  mkdir archive
fi
mv ${BUNDLE} archive/
