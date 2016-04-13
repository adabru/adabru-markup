#!/usr/bin/env node

// call me from parent directory

// create parser from grammar file
require('child_process').execSync(`
  ../grammar/waxeye_fix/bin/waxeye -g javascript ../js/build ../grammar/adabru_markup.waxeye
`)

var fs = require('fs')
require('coffee-script/register')
adabruMarkup = require('../js/core')

// read file
testFile = (process.argv[2] != null) ? process.argv[2] : './markup/test.md'
document = fs.readFileSync(testFile, 'utf8')

ast = adabruMarkup.parseDocument(document)

if(process.argv[3] == '-json') {
  console.log(JSON.stringify(ast))
} else {
  printAST = function(ast, prefix) {
    if(typeof ast.type == 'undefined') {
      console.log(prefix,'| ',ast)
    } else {
      console.log(prefix,'→ ',ast.type)
      ast.children.forEach(c => printAST(c, prefix+'   '))
    }
  }
  printAST(ast,'')
}


// require('repl').start('node> ');return
