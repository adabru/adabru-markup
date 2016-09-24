#!/usr/bin/env lsc

# helper functions
require! [util, fs, path]
repl = (context={}) ->
  Object.assign require('repl').start('node> ').context, context
util.hash = (s) ->
  hash = 0
  for i from 0 to s.length-1
    hash  = (((hash .<<. 5) - hash) + s.charCodeAt i) .|. 0
  hash
print = (o, d=10) ->
  console.log util.inspect o, {colors: true, depth: d}
colors = (->
  esc = (e1,e2,s) --> "\u001b[#{e1}m#{s}\u001b[#{e2}m"
  b = []
  b[0 to 7] = [esc("4#i","49") for i from 0 to 7]
  b[100 to 107] = [esc("10#i","49") for i from 0 to 7]
  f = []
  f[0 to 7] = [esc("3#i","39") for i from 0 to 7]
  f[90 to 97] = [esc("9#i","39") for i from 0 to 7]
  [inv,pos] = [esc('07','27'),esc('27','07')]
  [bold,dim,reset] = [esc('01',22),esc('02',22),esc('00','00')]
  {f,b,inv,pos,bold,dim,reset})!
error = (s) ->
  console.log '\u001b[1m\u001b[31m'+s+'\u001b[39m\u001b[0m'
log = (s, newline=true) ->
  if newline then console.log s else process.stdout.write s
todo = (s) ->
  console.log '\u001b[33mTODO: '+s+'\u001b[39m'
get_stdin = ->
  res = ''
  new Promise (resolve) ->
    stdin = process.stdin
    stdin.setEncoding 'utf8'
    stdin.on 'readable', ->
      while chunk = stdin.read! then res += chunk
    stdin.on 'end', ->
      resolve res
check_file = (file_path, isok, isempty, iswrong) ->
  if not file_path? then return isempty!
  try
    fs.accessSync file_path
    isok!
  catch
    levenshtein = (s,t) -> # edit distance
      switch
        case s == t then return 0
        case s == '' then return t.length
        case t == '' then return s.length

      v0 = [0 to t.length]
      v1 = []
      for i from 0 to s.length-1
        v1[0] = i+1
        for j from 0 to t.length-1
          cost = if s[i] == t[j] then 0 else 1
          v1[j+1] =   v1[j]+1   <?   v0[j+1]+1   <?   v0[j]+cost
        v0 = v1.slice!
      v1[t.length]
    fuzzy_files = fs.readdirSync path.dirname file_path
    let base = path.basename file_path
      suggestion = fuzzy_files.reduce (a,f) ->
        let dist = levenshtein f, base
          if a[1] < dist then a else [f,dist]
      if suggestion[1] <= base.length/2 then iswrong suggestion[0] else iswrong!
help = ->
  console.log '''


  \u001b[1musage\u001b[0m: abpv1 apple_banana.grammar OPTIONS

      -i <file>   parse <file> with specified grammar
                  or stdin if <file> is not given
      --nt <nt>   start with nonterminal <nt>, only
                  used when option -i is specified
                  defaults to first given rule in grammar
      -c <file>   write compiled parser to <file>, if <file>
                  is not given, it is written to stdout
      --help
  '''

# show help
argv = require('minimist') process.argv.slice(2), {}
if argv.help
  help!
  return

# read grammar file
input = check_file argv._[0],
  ->
    fs.readFileSync argv._[0], {encoding: 'utf8'}
  ->
    error 'no grammar file specified'
    help!
    false
  (suggestion) ->
    error "grammar file '#{argv._[0]}' does not exist"
    if suggestion? then log "did you mean '#{colors.bold suggestion}'?"
    help!
    false
if not input then return

# parse  grammar
abpv1_grammar = require './abpv1.json'
abpv1 = require './abpv1.ls'
memory = {name: 'memory'}
inspect_parse = (ast, memory, x) ->
  {f,inv,bold} = colors
  line_lengths = (x.split '\n').map (s)->s.length
  line_and_col = (pos) ->
    for len,i in line_lengths
      if pos < len then return [i,pos] else pos -= len+1
  todo 'better suggestions here than just going through the buffer, e.g. some statistically trained suggestions'
  log '<number>+<Enter> move to character OR <Enter> leave'
  short_print = (ast, indent=0) ->
    s = ' '.repeat indent
    s += "#{}#{ast.name} #{if ast.status == 'success' then '✔' else '✘'} #{ast.start} #{ast.end} #{ast.lookAhead} "
    t = x.substring ast.start, ast.end
    t = if t.length < 60 then "#{f.2 t}" else "#{f.2 t.substr 0,25}…#{f.2 t.substr -25,25}"
    s += t.replace /\n/g, inv 'n'
    s += ""
    t = x.substring ast.end, ast.lookAhead
    t = if t.length < 20 then "#{f.3 t}" else "#{f.3 t.substr 0,8}…#{f.3 t.substr -8,8}"
    s += t.replace /\n/g, inv 'n'
    log s
    if ast.status == 'fail' then for c in ast.children
      short_print c, indent+1
  state = {pos: 1}
  process.stdin.setEncoding 'utf8'
  process.stdin.setRawMode true
  process.stdin.on 'data', (d) ->
    i = state.pos
    switch d
      case '\u0003' then process.exit!
      case '\u001b[D' then state.pos--
      case '\u001b[C' then state.pos++
      case '0','1','2','3','4','5','6','7','8','9' then state.pos = (state.pos+d) .|. 0
      case '\u007f'
        s = ''+state.pos
        state.pos = if s.length<=1 then 0 else 0 .|. s.substr 0, s.length-1
      case '\r' then process.stdin.pause!
    state.pos = (state.pos >? 0) <? x.length-1
    if i != state.pos
      let [l,c] = line_and_col state.pos
        log "#{bold state.pos}: line #{bold l}, col #{bold c} #{f.2 x.slice state.pos-4>?0, state.pos}#{f.2 bold x.substr state.pos, 1}#{f.2 x.substr state.pos+1, 4}".replace /\n/g, inv 'n'
      if memory[state.pos]? then for nt of memory[state.pos] then short_print memory[state.pos][nt]
ast = abpv1.parse input, abpv1_grammar, {memory:memory}
if ast.status == 'fail'
  error 'failed to parse grammar.'
  if not argv.d? then
    log 'use option -d to see more information'
  else
    inspect_parse ast, memory[util.hash input], input
  return

# build grammar from raw ast
grammar = {}
to_grammar = (ast) ->
  switch ast.name
    case 'PASS' then func: 'multipass', params:[ast.children.map to_grammar]
    case 'ALT' then func: 'alternative', params:[ast.children.map to_grammar]
    case 'SEQ' then func: 'sequence', params:[ast.children.map to_grammar]
    case 'AND' then func: 'and', params: [to_grammar ast.children[0]]
    case 'NOT' then func: 'not', params: [to_grammar ast.children[0]]
    case 'VOID' then func: 'void', params: [to_grammar ast.children[0]]
    case 'OPT' then func: 'optional', params: [to_grammar ast.children[0]]
    case 'STAR' then func: 'star', params: [to_grammar ast.children[0]]
    case 'PLUS' then func: 'plus', params: [to_grammar ast.children[0]]
    case 'NT' then func: 'nonterminal', params: [ast.children[0]]
    case 'T'
      func: 'terminal'
      params: switch ast.children[0][0]
          case '.' then [null]
          case '\''
            t = ast.children[0].substr 1, ast.children[0].length-2
            specials = '\\b':'\b', '\\f':'\f', '\\n':'\n', '\\O':'\O', '\\r':'\r', '\\t':'\t', '\\v':'\v', '\\\'':'\'', '\\\\':'\\'
            for k of specials then t = t.replace k, specials[k]
            [t]
          case '['
            specials = '\\b':'\b', '\\f':'\f', '\\n':'\n', '\\O':'\O', '\\r':'\r', '\\t':'\t', '\\v':'\v', '\\]':']', '\\\\':'\\'
            t = ast.children[0].substr 1, ast.children[0].length-2
            for k of specials then t = t.replace k, specials[k]
            res = []
            i = 0
            if t[i] == '^' then res ++= t[i++]
            while i < t.length then switch
              case t[i+1] == '-' then res ++= t[i]+t[(i+=3)-1]
              default then res ++= t[i]+t[i++]
            [res]
for rule in ast.children
  flags = {}
  nt = rule.children[0].children[0]
  if rule.children[1] == '↖' then flags.pruned = true
  grammar[nt] = flags: flags
  grammar[nt]{func, params} = to_grammar rule.children[2]

# parse/interpret user specified input with fresh grammar
promise = switch argv.i
  case true
    get_stdin!
  case void then
  default
    check_file argv.i,
      -> new Promise (fulfill, reject) ->
        fs.readFile argv.i, 'utf8', (err, res) ->
          if err then reject err else fulfill res
      ->
      (suggestion) !->
        error "input file '#{argv.i}' does not exist"
        if suggestion? then log "did you mean '#{colors.bold suggestion}'?"
promise?.then (s) ->
  memory = {}
  ast = abpv1.parse s, grammar, if argv.nt? then {startNT:argv.nt,memory:memory} else {memory:memory}
  if ast.status == 'fail'
    inspect_parse ast, memory[util.hash s], s
  else
    {f,b,inv,dim} = colors
    short_print = (prefix, ast) ->
      if util.isString ast
        s = (b.100 f.92 ast).replace(/\n/g, inv 'n')
      else
        s = f.3 ast.name
        abbr = ast.name.substr 0,2
        prefix += (dim f.3 abbr) + ' '
        if ast.children.length == 1
          s += ' ' + short_print prefix, ast.children.0
        else then for c in ast.children
          s += '\n' + prefix + (short_print prefix, c)
        s
    log short_print '',ast

# write parser to file
switch argv.c
  case true then log JSON.stringify grammar
  case void then
  default
    fs.writeFileSync argv.c, JSON.stringify grammar
    log "written file '#{colors.bold that}'"
