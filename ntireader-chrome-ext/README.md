# Chinese-English Dictionary Browser Extension

## Using the Extension
The NTI Reader Chrome Extension is a Chinese-English Buddhist dictionary. It 
supports simplified and traditional chinese to English and pinyin lookup.
It also includes a base Chinese-English dictionary with many literary Chinese
and modern Chinese terms. The extension can do multiple term lookup and reverse
lookup of English terms. Common Buddhist terms can be found by Sanskrit, Pali,
Japanese, and Tibetan equivalent.

To install the extension, go to this link in the Chrome Web Store
https://chrome.google.com/webstore/detail/nti-reader-buddhist-dicti/iachdahjdmnhnbeojfpopajmilenhhbd 

Use it by selecting text on a page, right clicking, and selecting
Lookup with NTI Reader …

The extension is a multi-dictionary framework - currently includes the NTI
Reader and Humanistic Buddhism Glossary
It is like the ntireader.org web site but can be installed as a Chrome Extension
It can help you stay within the flow of a Chinese document, avoiding the need to
switch back and forth between pages. Try it out on web site like the University
of Oslo's multilingual corpus 
[Thesaurus Literaturae Buddhicae](https://www2.hf.uio.no/polyglotta/index.php).
For example,the 
[Aṣṭasāhasrikā Prajñāpāramitā](https://www2.hf.uio.no/polyglotta/index.php?page=volume&vid=435)
'Perfection of Wisdom in 8,000 Lines.' It may also be useful on
[cbeta.org](https://cbeta.org/) and the University of Tokyo's
[SAT](https://21dzk.l.u-tokyo.ac.jp/SAT/satdb2015.php) online version of the
Taishō Tripiṭaka, 
[Venerable Master Hsing Yun's Collected Writings](http://www.masterhsingyun.org/),
and the [Fo Guang Shan Dictionary of Buddhism](http://etext.fgs.org.tw/search/index.aspx),
a Chinese monolingual dicitonary.

Demo on Youtube
https://youtu.be/jtZSOtOanHQ


This page describes how to use the code as a Chrome browser extension.

Screenshots are shown below:

![](../drawings/ntireader-ext-context-menu.png?raw=true)

Select text and right click to bring up the menu.

![](../drawings/ntireader-ext-dialog.png?raw=true)

Click on the Lookup with NTI Reader ... menu item to see the dialog.

![](../drawings/ntireader-ext-reverse-english.png?raw=true)

You can do a reverse lookup with an English word.

![](../drawings/screenshot-multilingual-reverse.png?raw=true)

You can do reverse lookup with other languages, including Sanskrit, Pali,
Japanese, and Tibetan, for common Buddhist terms.

![](../drawings/ntireader-ext-reverse-tibetan.png?raw=true)

Here is an example with reverse lookup from Tibetan.

## Developers

You are welcome to download and work directly with the code.

### Compiling the code

Set your Dart SDK home directory in the environment variable

```shell
DART_HOME=[your dart home]
```

in the script `bin/make_nti_plugin.sh`

If you have installed Flutter, it may be somewhere like

```shell
DART_HOME=$HOME/flutter/bin/cache/dart-sdk
```

From the top level directory, run the build script with the command

```shell
bin/make_nti_plugin.sh
```

The zipped exension will be place in the `downloads` directory.

### Try it out

Make a convenient directory somewhere and copy the zipped extension to it:

```shell
mkdir tmp
cp downloads/ntireader-chrome-ext-0.0.5.zip
cd tmp
unzip ntireader-chrome-ext-0.0.5.zip
rm *.zip
cd ..
```

In developmenet deploy to the browser by loading this directory as a Chrome
extension in development mode.