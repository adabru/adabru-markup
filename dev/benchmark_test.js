#!/usr/bin/env node

// call me from parent directory

// create parser from grammar file
require('child_process').execSync(`
  ../grammar/waxeye_fix/bin/waxeye -g javascript ../js/build ../grammar/adabru_markup.waxeye
`)

var fs = require('fs');
adabruMarkup = require('../js/core')


// read file
testFile = (process.argv[2] != null) ? process.argv[2] : './markup/benchmark.md'


document = fs.readFileSync(testFile, 'utf8')

var start = new Date()
for (i=0 ; i<10 ; i++) {
	ast = adabruMarkup.parseDocument(document)
}
var end = new Date()

console.log('Parsing time: ', end-start)

// require('repl').start('node> ');return
