#!/usr/bin/env lsc

# this script must be called from parent directory

require! [fs,child_process]

log = console.log

args = process.argv.slice 2
if args.0 != '--create-oracle'
  child_process.execSync 'node ./parser/generator.js ./grammar/ab_markup.grammar -d -c ./html/js/build/ab_markup_grammar.json -i ./grammar/informal_spec', encoding:'utf-8',stdio:'inherit'

abpv1 = require '../parser/abpv1.js'
grammar = require '../html/js/build/ab_markup_grammar.json'
input = fs.readFileSync './grammar/informal_spec', {encoding: 'utf8'}

parse_result = JSON.stringify abpv1.parse input,grammar
if args.0 == '--create-oracle'
  fs.writeFileSync './dev/grammar_test.oracle', parse_result
else
  oracle = fs.readFileSync './dev/grammar_test.oracle', {encoding: 'utf8'}
  log if oracle is JSON.stringify abpv1.parse input,grammar then 'Everything as oracle says' else 'Attention, does not match with oracle'
