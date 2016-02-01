#!/usr/bin/env node

// call me from parent directory

var fs = require('fs');

adabruMarkup = require('../../../js/adabru-markup-core')

// read file
testFile = (process.argv[2] != null) ? process.argv[2] : './src/test.md'


document = fs.readFileSync(testFile, 'utf8')
rawhtml = adabruMarkup.parseAndPrint(document)
prettyhtml = require("html").prettyPrint(rawhtml, {indent_size: 2})
console.log( prettyhtml )

// require('repl').start('node> ');return
