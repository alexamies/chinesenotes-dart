### Chinese Translation of Concise Pali-English Dictionary

This page describes how to use the Chrome browser extension for the
[Chinese Translation of Concise Pali-English Dictionary](https://glossaries.dila.edu.tw/glossaries/PLC?locale=en)
which is Dama Bhikkhu: A Chinese Translation of A.P. Buddhadatta's
“Concise Pali-English Dictionary” : Digital Edition, which is in the public
domain. You can find out more about the dictionary at

https://glossaries.dila.edu.tw/glossaries/PLC

Thank you to the Digital Archive Section at Dharma Drum Institute of Liberal
Arts (DILA) for making the TEI file available.

Install the extension from the Chrome store.

Try it out on web site like the University of Oslo's multi-lingual corpus
[Thesaurus Literaturae Buddhicae](https://www2.hf.uio.no/polyglotta/index.php)

For example, the Aṣṭasāhasrikā Prajñāpāramitā
'Perfection of Wisdom in 8,000 Lines' at
https://www2.hf.uio.no/polyglotta/index.php?page=volume&vid=435

Right click on a Chinese, Tibetan, or Sanskrit term. You should see a context
menu that says, "Lookup in Mahāvyutpatti ..." Click it. A dialog should appear
with the details of the entry. A Youtube video demonstrating it is here

https://youtu.be/_RXTqXetQb8


Screenshots

![](../drawings/mahavyutpatti-chrome-ext-menu.png?raw=true)

![](../drawings/mahavyutpatti-chrome-ext-dialog.png?raw=true)

![](../drawings/mahavyutpatti-chrome-ext-tibetan.png?raw=true)

## Development

This section describes how to build and package the extension.

Prerequisites: Dart, Linux

Get the package dependencies

```shell
dart pub get
```

### Dictionary data

Mahavyutpatti dictionary is a historic Chinese-Tibetan-Sanskrit Buddhist 
dictionary. Download the data file from the DILA site and save it in the 
`data` directory.

```shell
mkdir data
cd data
curl -k -o mahavyutpatti.dila.tei.p5.xml.zip \
  https://glossaries.dila.edu.tw/data/mahavyutpatti.dila.tei.p5.xml.zip
unzip mahavyutpatti.dila.tei.p5.xml.zip
cd ..
```

### Compiling the code

From the top level directory run

```shell
bin/make_mahavyutpatti.sh 
```

### Try it out

In developmenet deploy to the browser by loading this directory as an unpacked
Chrome extension in development mode.