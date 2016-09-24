#!/usr/bin/env node

// call me from parent directory

// create parser from grammar file
// require('child_process').execSync(`
//   ./parser/generator.ls ./grammar/ab_markup.grammar -c ./html/js/build/ab_markup_grammar.json
// `)

var fs = require('fs');
require('coffee-script/register')
adabruMarkup = require('../html/js/build/adabrumarkup.js')


// read file
testFile = (process.argv[2] != null) ? process.argv[2] : './dev/markup/benchmark.md'


document = fs.readFileSync(testFile, 'utf8')

var start = new Date()
for (i=1 ; i<=10 ; i++) {
  console.log('Pass '+i+' of 10...')
  var time1 = new Date()
	ast = adabruMarkup.parseDocument(document)
  var time2 = new Date()
  console.log('                 '+(time2-time1)+' / '+Math.round((time2-start)/i));
}
var end = new Date()

console.log('Parsing time: ', end-start)

// require('repl').start('node> ');return
