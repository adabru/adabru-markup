#!/usr/bin/env lsc

# call me from parent directory

require! [child_process,fs]

# compile files
for f in fs.readdirSync('./parser').filter((x)->x is /\.ls$/)
  f = "./parser/"+(f is /(.*)\.ls/)[1]
  if fs.statSync("#f.ls").mtime.getTime! > fs.statSync("#f.js").mtime.getTime!
    child_process.execSync "lsc -c #f.ls", encoding:'utf-8',stdio:'inherit'

child_process.execSync 'node ./parser/generator.js ./grammar/ab_markup.grammar -c ./html/js/build/ab_markup_grammar.json'

abpv1 = require '../parser/abpv1.js'
grammar = require '../html/js/build/ab_markup_grammar.json'
document = fs.readFileSync (process.argv[2] ? './dev/benchmark_test.data'), 'utf8'

start = new Date!
pass = (i) ->
  if i<=10
    console.log 'Pass '+i+' of 10...'
    time1 = new Date!
    ast <- abpv1.parse(document,grammar).then _
    time2 = new Date!
    console.log '                 '+(time2 - time1)+' / '+Math.round (time2 - start)/i
    pass i+1
  else
    end = new Date!
    console.log 'Parsing time: ', end - start
pass 1
