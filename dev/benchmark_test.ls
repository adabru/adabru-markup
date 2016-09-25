#!/usr/bin/env lsc

# call me from parent directory

require! [child_process,fs]

child_process.execSync 'node ./parser/generator.js ./grammar/ab_markup.grammar -c ./html/js/build/ab_markup_grammar.json'

abpv1 = require '../parser/abpv1.js'
grammar = require '../html/js/build/ab_markup_grammar.json'
document = fs.readFileSync (process.argv[2] ? './dev/benchmark_test.data'), 'utf8'

start = new Date!
for i from 1 to 10
  console.log 'Pass '+i+' of 10...'
  time1 = new Date!
  ast = abpv1.parse document,grammar
  time2 = new Date!
  console.log '                 '+(time2 - time1)+' / '+Math.round (time2 - start)/i
end = new Date!

console.log 'Parsing time: ', end - start
