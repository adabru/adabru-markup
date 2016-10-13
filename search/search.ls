#!/usr/bin/env lsc

require! [util,fs,path,repl]
require! [minimist]

log = console.log
print = (o, d=10) -> console.log util.inspect o, {colors: true, depth: d}
flatten = (arr) -> [].concat.apply [], arr
glob = (pattern) ->
  if '*' in pattern then
    [_, dir, f0] = pattern is /^(.*)\/(.*?)\*$/
    try fs.readdirSync(dir).filter((f)->f.startsWith f0).map((f)->"#dir/#f")
    catch err then log "problem with directory #dir"
  else [pattern]
{absh} = require './absh.ls'

help = ->
  console.log '''


  \u001b[1musage\u001b[0m: search FILES

      -s <expr>   search in FILES for <expression>
      -c <file>   write compiled parser to <file>, if <file>
                  is not given, it is written to stdout
      -d          enter debug mode even on success
      --help

  \u001b[1mExamples\u001b[0m
  search.ls ./test/a* ./test/b* -s 'some keywords'

  '''

# show help
argv = minimist process.argv.slice(2), {}
if argv.help or argv._.length == 0
  help!
  return

# wildcards
files = flatten [glob p for p in argv._]
documents = [JSON.parse fs.readFileSync f, 'utf-8' for f in files]

# concordance
conc = build_concordance documents
function build_concordance(documents)
  # date spelling nonterminals position
  conc = {}
  linearized = []
  for d in documents
    linearized.push l=[]
    visit = (ast, nt, date) ->
      if util.isString ast
        for s in ast.split ' '
          _s = s.replace(/[-_{}\n]/g '').toLowerCase!
          l.push {_s, s, nt, date}
      else
        [visit c, "#nt #{ast.name}", date for c in ast.children]
    visit d, '', {}
  flatten linearized

# search
function search(expr, conc, callback)
  # edit distance 1: /cat/ becomes /(c?.?at)|(ca?.?t)|(cat?.?)/
  regex = ["(#{expr.slice 0,i}?.?#{expr.slice i})" for i from 1 to expr.length]
  # letter swaps: /cat/ becomes /(.ct)|(c.a)/
  regex ++= ["(#{expr.slice 0,i-1}.#{expr[i-1]}#{expr.slice i+1})" for i from 1 to expr.length-1]
  regex = new RegExp regex.join '|'
  for w in conc
    if regex.test w._s then callback w
  regex

if process.argv.1.endsWith 'search.ls'
  s = (exp) -> search exp, conc, log
  absh {s} ; return
