# adabru-markup

Markup-language based on Parsing Expression Grammar, autogenerated multipass packrat-parser, and librarybindings


# Installation

### bower

```sh
bower install adabru/adabru-markup
```

### npm

```sh
npm install adabru/adabru-markup
```

### manually

Downloading zip from <https://github.com/adabru/adabru-markup> and extracting.

# Usage

### bower + manual

```html
<script src="./bower_components/adabru-markup/js/build/adabrumarkup.js"></script>

<body>
  <div id='app'>
  </div>
</body>

<script>
  fetch('markup/path/to/file.md, {method: 'get'}).then( r => r.text() ).then( data => {
      adabruMarkup.parseAndPrintDocument(data, document.querySelector('#app'))
  })
</script>
```

# Development

```
git clone git://github.com/adabru/adabru-markup
cd adabru-markup
npm install
webpack --watch --devtool sourcemap
```
To start test server `localhost:133`:
```
./dev/start_dev.sh
```
