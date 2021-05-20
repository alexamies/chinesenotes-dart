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

It incorporates many TEI <a href='https://glossaries.dila.edu.tw/'
>glossary files</a> and Dharma Drum 
<a href='http://authority.dila.edu.tw/'
>Buddhist Studies Authority Database</a> files.
Thanks to Dharma Drum for making these freely available under a Creative
Commons license and providing the  
<a href='http://authority.dila.edu.tw/docs/open_content/download.php'
>files<a> for download (also at the
<a href='https://github.com/DILA-edu/Authority-Databases'
>Authority-Databases</a> Github project).

## Setup

1. Download or build the zip file using the instructions below. Put the zip file
in a folders, say `workbench`. Unzip it. 
2. In Chrome, go to Extensions | Manage Extensions and enable Developer Mode.
3. Click Load Unpacked. Select the directory that the extension is contained in.

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

Execute this shell command at the top-level project directory:

```shell
bin/make_workbench.sh
```

The bundle will be zipped up and moved to the `archive` directory.
