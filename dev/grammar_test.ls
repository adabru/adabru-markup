#!/usr/bin/env lsc

# this script must be called from parent directory

require! [fs,child_process]

log = console.log
args = process.argv.slice 2

process.on('SIGINT',
  (a) -> console.log 'asd'; process.exit!)

# compile files
for f in fs.readdirSync('./parser').filter((x)->x is /\.ls$/)
  f = "./parser/"+(f is /(.*)\.ls/)[1]
  if fs.statSync("#f.ls").mtime.getTime! > fs.statSync("#f.js").mtime.getTime!
    child_process.execSync "lsc -c #f.ls", encoding:'utf-8',stdio:'inherit'

# select file to parse
file = switch args.0
  case '--create-oracle', '--verify' then './grammar/informal_spec'
  case void then './dev/grammar_test.data'
  default then args.0

# create fresh grammar
child_process.execSync "node ./parser/generator.js ./grammar/ab_markup.grammar -d -c ./html/js/build/ab_markup_grammar.json -i #file", encoding:'utf-8',stdio:'inherit'

# parse
abpv1 = require '../parser/abpv1.js'
grammar = require '../html/js/build/ab_markup_grammar.json'
input = fs.readFileSync file, {encoding: 'utf8'}
ast <- abpv1.parse(input,grammar).then _
parse_result = JSON.stringify ast

# after parse
switch args.0
  case '--create-oracle'
    fs.writeFileSync './dev/grammar_test.oracle', parse_result
  case '--verify'
    oracle = fs.readFileSync './dev/grammar_test.oracle', {encoding: 'utf8'}
    log if oracle is JSON.stringify abpv1.parse input,grammar then 'Everything as oracle says' else 'Attention, does not match with oracle'
