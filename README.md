# adabru-markup

Markup-language based on Parsing Expression Grammar, autogenerated multipass packrat-parser, and librarybindings


## Installation

### bower

└▪bower install adabru/adabru-markup↵

### npm

└▪npm install adabru/adabru-markup↵

### manually

Downloading zip from https://github.com/adabru/adabru-markup and extracting.

## Usage

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

## Development

### Setup

└▪git clone git://github.com/adabru/adabru-markup↵
└▪cd adabru-markup↵
└▪npm install↵
- compiling livescript for faster parsing when they are used
  └▪lsc -c ./parser/*.ls↵
└▪./parser/generator.ls ./grammar/ab_markup.grammar -c ./html/js/build/ab_markup_grammar.json↵
└▪webpack --config ./html/webpack.config.js --watch --devtool sourcemap↵

- prepare tests
└▪chmod +x ./dev/*ls ./dev/*sh↵
└▪./dev/grammar_test.ls --create-oracle↵

### Testing

- start test server on 'localhost:133'
  └▪./dev/start_dev.sh↵

- grammar modification
  └▪./dev/grammar_test.ls↵

- benchmarks
  └▪./dev/benchmark_test.js↵
