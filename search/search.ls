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

function build_concordance(name,tree)
  # date spelling nonterminals position
  linearized = []
  visit = (ast, prefix, nt, date) ->
    if util.isString ast
      for s in ast.split /[ \n]/
        _s = s.replace(/[-_{}\n]/g '').toLowerCase!
        linearized.push {_s, s, i_ast:prefix, nt, date, filename:name, i:linearized.length}
    else
      [visit c, "#{prefix}:#i", "#{(true:"" false:"#nt ")[nt is '']}#{ast.name}", date for c,i in ast.children]
  visit tree, '', '', {}
  linearized

function search(expr, conc, callback)
  expr .= replace(/[-_{}\n]/g '').toLowerCase!
  if expr.length > 3
    # edit distance 1: /cat/ becomes /(c?.?at)|(ca?.?t)|(cat?.?)/
    regex = ["(#{expr.slice 0,i}?.?#{expr.slice i})" for i from 1 to expr.length]
    # letter swaps: /cat/ becomes /(.ct)|(c.a)/
    regex ++= ["(#{expr.slice 0,i-1}#{expr[i]}#{expr[i-1]}#{expr.slice i+1})" for i from 1 to expr.length-1]
    regex = new RegExp regex.join '|'
  else
    regex = new RegExp expr.replace /([\.()])/g, "\\$1"
  if (->
    for name,lin of conc
      for w in lin
        if regex.test w._s
          if not callback w
            callback null ; return false
    true)! then callback null
  regex

function weight(finding, expr)
  levenshtein = (s,t) ->
    switch; case s == t then return 0 ;case s == '' then return t.length ;case t == '' then return s.length
    [v0,v1] = [[0 to t.length] []]
    for i from 0 to s.length-1 then
      v1[0] = i+1
      for j from 0 to t.length-1
        cost = if s[i] == t[j] then 0 else 1
        v1[j+1] =   v1[j]+1   <?   v0[j+1]+1   <?   v0[j]+cost
      v0 = v1.slice!
    v1[t.length]
  levenshtein_distance = levenshtein expr, finding.s

  nt_weights = 'Header_L1':3 'Header_L2':2.5 'Header_L3':2 'Fit_Item':0.5 'Factsheet_Thing':1.5
  nt_multiplier = finding.nt.split(' ').reduce ((a,x) -> if nt_weights[x]? then a * that else a), 1

  (100 - 6 * levenshtein_distance >? 1) * nt_multiplier

function beefed(finding, conc)
  context = conc[finding.filename].slice (0 >? finding.i-5), finding.i
  context ++= [null]
  context ++= conc[finding.filename].slice finding.i+1, finding.i+6
  {} <<< finding <<< {context}


function search_machine(callback=((f) -> log f ; true))
  new
    @conc = {}
    @search = (expr, _callback=callback) -> search expr, @conc, _callback
    @addDocument = (name,tree) -> @conc[name] = build_concordance name,tree
    @weight = weight
    @beefed = (f) -> beefed f, @conc

exports <<< {search_machine}

if process.argv.1.endsWith 'search.ls'
  help = -> console.log '''


    \u001b[1musage\u001b[0m: search FILES

        -s <expr>   search in FILES for <expression>
        --help

    \u001b[1mExamples\u001b[0m
    search.ls ./test/a* ./test/b* -s 'some keywords'

    '''
  if process.argv.2 in ["-h", "help", "-help", "--help", void] then return help!

  argv = minimist process.argv.slice(2), {}

  # wildcards
  files = flatten [glob p for p in argv._]

  # setup search machine
  sm = search_machine!
  for f in files
    log "adding \u001b[1m#{f}\u001b[0m to concordance..."
    sm.addDocument f, JSON.parse fs.readFileSync f, "utf8"
  log "concordance has #{Object .keys(sm.conc) .map((i)->sm.conc[i].length) .reduce((a,x) -> a+x)} entries\n"

  # execute search
  colors = let e = ((e1,e2,s) --> "\u001b[#{e1}m#{s}\u001b[#{e2}m")
      b = [] ; for i in [0 to 7] then b[i]=e("4#i","49") ; for i in [100 to 107] then b[i]=e(i,"49")
      f = [] ; for i in [0 to 7] then f[i]=e("3#i","39") ; for i in [90 to 97] then f[i]=e(i,"39")
      {f,b,inv:e('07','27'), pos:e('27','07'), bold:e('01',22), dim:e('02',22), reset:e('00','00')}
  {dim,f,bold} = colors
  pretty_print = (weight, s) ->
    log "#{bold weight} #{s.context.map((cs) -> if cs? then f.3 cs.s else bold f.3 s.s) .join ' '} in #{dim path.basename s.filename} at #{dim s.i}"
    true
  if argv.s?
    found = []
    log "searching with #{f.1 sm.search that, ->false}"
    sm.search that, (s) -> if not s? then false else pretty_print (sm.weight s, argv.s), (sm.beefed s)
    return log "\n"

  log "\naccess search machine with \u001b[1msm\u001b[0m" ; absh {sm} ; return
