# Mahāvyutpatti Sanskrit-Tibetan-Chinese Budhist Dictionary Browser Extension

This page describes how to use the Chrome browser extension.

Mahāvyutpatti is a historic dictionary compiled in the Song dynasty for
translation of Buddhist texts to Tibetan.

Install the extension from the Chrome store

Try it out on web site like the University of Oslo's multi-lingual corpus
[Thesaurus Literaturae Buddhicae](https://www2.hf.uio.no/polyglotta/index.php)

For example, the Aṣṭasāhasrikā Prajñāpāramitā
'Perfection of Wisdom in 8,000 Lines' at
https://www2.hf.uio.no/polyglotta/index.php?page=volume&vid=435

Right click on a Chinese, Tibetan, or Sanskrit term. You should see a context
menu that says, "Lookup in Mahāvyutpatti ..." Click it. A dialog should appear
with the details of the entry.

## Development

This section describes how to build and package the extension.

Prerequisites: Dart, Linux

### Compiling the code

From the top level directory run

```shell
bin/make_mahavyutpatti.sh 
```

### Try it out

In developmenet deploy to the browser by loading this directory as an unpacked
Chrome extension in development mode.