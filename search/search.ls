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
        if s isnt ""
          _s = s.replace(/[-_{}\n]/g '').toLowerCase!
          linearized.push {_s, s, i_ast:prefix, nt, date, filename:name, i:linearized.length}
    else
      [visit c, "#{prefix}:#i", "#{(true:"" false:"#nt ")[nt is '']}#{ast.name}", date for c,i in ast.children]
  visit tree, '', '', {}
  linearized

function search(rich_query, conc, callback)
  # create regex for each keyword
  expr = []
  for e in rich_query
    e .= replace(/[-_{}\n]/g '').toLowerCase!
    if e.length > 3
      # edit distance 1: /cat/ becomes /(c?.?at)|(ca?.?t)|(cat?.?)/
      regex = ["(#{e.slice 0,i}?.?#{e.slice i})" for i from 1 to e.length]
      # letter swaps: /cat/ becomes /(.ct)|(c.a)/
      regex ++= ["(#{e.slice 0,i-1}#{e[i]}#{e[i-1]}#{e.slice i+1})" for i from 1 til e.length]
      expr ++= new RegExp regex.join '|'
    else
      expr ++= new RegExp e.replace /([\.()])/g, "\\$1"

  # linear search on concordance
  #
  # best single result per halfframe
  # best combined result for frame
  #
  #  ┌───────────────┐
  #  │               │
  #          └     ✔ ┴ ─ ─ ─ ┴ ─ ─ ─ ┴ ─ ─ ─ ┴ ─ ─ ─
  # → no callback
  #
  #          ┌───────────────┐
  #          │               │
  #          └     ✔ ┴ ✔     ┴ ─ ─ ─ ┴ ─ ─ ─ ┴ ─ ─ ─
  # → callback
  #
  #                  ┌───────────────┐
  #                  │               │
  #          └     ✔ ┴ ✔     ┴       ┴ ─ ─ ─ ┴ ─ ─ ─
  # → callback
  #
  #                          ┌───────────────┐
  #                          │               │
  #          └     ✔ ┴ ✔     ┴       ┴       ┴ ─ ─ ─
  # → no callback

  halfframe = 30

  :search for name,lin of conc
    halfframe_winner = []
    frame_winner = []
    :halfframe for hf from 0 to Math.floor lin.length / halfframe
      # best single matches in half of a frame
      for w_i from hf*halfframe til (hf+1)*halfframe <? lin.length
        w = lin[w_i]
        :keyword for regex,i in expr
          if regex.test w._s
            w.weight = weight w, rich_query[i]
            if (halfframe_winner[hf]?[i]?.weight ? 0) < w.weight
              (halfframe_winner[hf] ?= [])[i] = w
              break keyword # prevent same match for two keywords

      # end of halfframe

      if hf is 0 and lin.length > halfframe then continue

      # best frame (= 2 halfframes) tuple result
      f = hf-1
      for i from 0 til rich_query.length
        if not halfframe_winner[hf-1]?[i]? and not halfframe_winner[hf]?[i]?
          continue halfframe # the i-th keyword misses in both halfframes
      :combination for a from 0 til 2**rich_query.length
        sum = 0
        x = []
        for i from 0 til rich_query.length
          if i is 0 and frame_winner[f-1]?.a is 2**rich_query.length - 1
            continue # same as in previous frame
          w = halfframe_winner[if 1 .&. (a .>>. i) then hf else hf-1]?[i]
          if not w? then continue combination
          sum += w.weight
          x ++= w.i
        tuple_weight = Math.floor sum * distance_weight x, 2*halfframe
        if (frame_winner[f]?.tuple_weight ? 0) < tuple_weight
          frame_winner[f] = {a, tuple_weight}
      if frame_winner[f]?
        keywords = []
        for i from 0 til rich_query.length
          keywords ++= halfframe_winner[if 1 .&. (frame_winner[f].a .>>. i) then f+1 else f][i].i
        if not callback {keywords, filename:name, weight:frame_winner[f].tuple_weight}
          break search

  # end of search
  callback null

  expr

function distance_weight(x, frame)
  x.sort (i,j) -> i - j
  factor = 1
  for i from 0 til x.length-1
    d = x[i+1] - x[i] - 1
    factor *= 0.8 * (d - frame)**2 / frame**2 + 0.2
  factor

function weight(finding, reference)
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
  levenshtein_distance = levenshtein reference, finding.s

  nt_weights = 'Header_L1':3 'Header_L2':2.5 'Header_L3':2 'Fit_Item':0.5 'Factsheet_Thing':1.5
  nt_multiplier = finding.nt.split(' ').reduce ((a,x) -> if nt_weights[x]? then a * that else a), 1

  (100 - 6 * levenshtein_distance >? 1) * nt_multiplier

function beefed(finding, conc)
  lin = conc[finding.filename]
  context_ranges = finding.keywords.slice!.sort((i,j) -> i - j).map((i) -> [i-5 >? 0, i+5 <? lin.length])
    .reduce(([...as,a],r) ->
      switch
        case not a? then [r]
        case a[1] >= r[0]-1 then [...as,[a[0],r[1]]]
        default then [...as,a,r]
    , [])
  context = []
  for r in context_ranges
    context ++= lin.slice r.0, r.1
  {} <<< finding <<< {context}

function parse_query(query)
  query.split ' '

function search_machine(callback=((f) -> log f ; true))
  new
    @conc = {}
    @search = (query, _callback=callback) -> search parse_query(query), @conc, _callback
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
  pretty_print = (s) ->
    log "#{bold s.weight} #{s.context.map((cs) -> if cs.i in s.keywords then bold f.3 cs.s else f.3 cs.s) .join ' '} in #{dim path.basename s.filename}"
    true
  if argv.s?
    found = []
    log "searching with #{f.1 sm.search that, ->false}"
    sm.search that, (found) -> if found? then pretty_print sm.beefed found
    return log "\n"

  log "\naccess search machine with \u001b[1msm\u001b[0m" ; absh {sm} ; return
