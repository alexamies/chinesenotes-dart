# Buddhist Multi-Dictionary Workbench

With the recipe given here you can create your own dictionary workbench 
combining multiple dictionaries on a web page without the need to run a web
server. It is a multi-dictionary, multilingual workbench with the following
souces:
 - NTI Reader base dictionary
 - NTI Reader Buddhist named entites
 - Fo Guang Shan Humanistic Buddhism Glossary
 - Mahavyutpatti
 - Soothill-Hodous
 - Karashima's Glosary of the Aṣṭasāhasrikā Prajñāpāramitā (Lokaksema)
 - Karashima's Glosary of the Dīrgha-āgama
 - Karashima's Glosary of Lotus Sūtra (Kumārajīva)
 - Karashima's Glosary of Lotus Sūtra (Dharmarakṣa)
 - DDBC Person Authority Database
 - DDBC Place Authority Database


It is shown in the screenshot below:

![](../drawings/combined-dictionaries-chrome-ext-mulit-multi-1280x800.png?raw=true)

This allows you to do lookup multiple terms at a single time with the results
from multiple dictionaries shown in the results.

It incorporates many TEI
[glossary files](https://glossaries.dila.edu.tw/) 
and Dharma Drum person and place entries in the
[Buddhist Studies Authority Database](http://authority.dila.edu.tw) files.
Thanks to Dharma Drum for making these freely available under a Creative
Commons license and providing the files for
[download](http://authority.dila.edu.tw/docs/open_content/download.php) and
also for the
[Authority-Databases Github project](https://github.com/DILA-edu/Authority-Databases).

## Setup

1. Download or build the zip file using the instructions below. 
2. Unzip it. 
3. In Chrome, go to **Extensions** | **Manage Extensions** and enable **Developer Mode**.
4. Click **Load Unpacked**. Select the directory that the extension is contained in.

## Use it

In Chrome, 

1. Go to Extensions
2. Select **Buddhist Multi-Dictionary Workbench**
3. Click the link “Open this page in a new tab”

You should see a screen like above.

## Developers

These instructions are intended for developers to build the Chrome extension.

TODO: Pinyin and aka indexes and not yet included, except for the NTI Reader
and HB Glossary files.

### Setup

This directory contains instructions for building new applications and browser
extensions.

Prequisites: Linux or compatible environment with Bash shell.

Set the Dart SDK home with the environment variable DART_HOME in the script
`bin/make_workbench.sh`. For example,

```shell
DART_HOME=$HOME/development/flutter/bin/cache/dart-sdk
```

Clone the NTI Reader project  to a higher level directory

```shell
git clone https://github.com/alexamies/buddhist-dictionary.git
```

### Building the Extension

Execute this shell command at the top-level project directory.

```shell
bin/make_workbench.sh
```

It is not well tested yet.
If you have problems, execute the commands one at a time. There is a known
issue in the format of the authority JSON files.

The bundle will be zipped up and moved to the `archive` directory.
