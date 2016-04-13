#!/usr/bin/env node

// call me from parent directory

var fs = require('fs');

require('coffee-script/register')
adabruMarkup = require('../js/core')

ReactDOMServer = require('react-dom/server')

// read file
testFile = (process.argv[2] != null) ? process.argv[2] : './markup/test.md'


document = fs.readFileSync(testFile, 'utf8')
rawhtml = ReactDOMServer.renderToStaticMarkup( adabruMarkup.parseAndPrint(document) )
prettyhtml = require("html").prettyPrint(rawhtml, {indent_size: 2})
console.log( prettyhtml )

// require('repl').start('node> ');return
