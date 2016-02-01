#!/usr/bin/env node

// call me from parent directory

// create parser from grammar file
require('child_process').execSync(`
  ./bin/waxeye_bin/bin/waxeye -g javascript ../../js/build ./src/adabru_markup.waxeye
`)

var fs = require('fs');
adabruMarkup = require('../../../js/adabru-markup-core')


// read file
testFile = (process.argv[2] != null) ? process.argv[2] : './src/test.md'
document = fs.readFileSync(testFile, 'utf8')

ast = adabruMarkup.parseDocument(document)
printAST = function(ast, prefix) {
  if(typeof ast.type == 'undefined') {
    console.log(prefix,'| ',ast)
  } else {
    console.log(prefix,'→ ',ast.type)
    ast.children.forEach(c => printAST(c, prefix+'   '))
  }
}
printAST(ast,'')


// require('repl').start('node> ');return
