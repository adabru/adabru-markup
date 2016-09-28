#!/usr/bin/env lsc

# helper functions
require! [util]
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

abpv1 = require './abpv1.js'

export inspect_memory = (memory, x) ->
  (fulfill, reject) <- new Promise _
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
  process.stdin
    ..setEncoding 'utf8'
    ..setRawMode true
    ..on 'data', callback=(d) ->
      i = state.pos
      switch d
        case '\u0003' then process.stdin ; ..removeListener 'data',callback ; ..pause! ; fulfill!
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


inspect_start = (x, memory, stack) ->
  interval = setInterval ->
    log 'stacksize: '+stack.length
  ,1000
  process.stdin
    ..setEncoding 'utf8'
    ..setRawMode true
    ..on 'data', callback=(d) ->
      switch d
        case 's'
          print stack[*-3],1
          print stack[*-2],1
          print stack[*-1],1
        case 'm'
          process.stdin.removeListener 'data', callback
          clearInterval interval
          <- inspect_memory(memory,x).then _
          process.stdin
            ..on 'data', callback
            ..resume!
        case 'c'
          stack.unshift new abpv1.Ast 'INSPECTOR_STOP'
          # print stack[0],1
        case '\u0003'
          process.stdin.removeListener 'data', callback
          clearInterval interval
          log '^C'
          process.exit!

inspect_end = ->
  process.stdin.pause!

export debug_parse = (x, grammar, parser_options={}) ->
  (fulfill) <- new Promise _
  memory = {name:'inspector_memory'}
  stack = []
    ..name = 'inspector_stack'
  inspect_start x, memory, stack
  ast <- abpv1.parse(x, grammar, Object.assign parser_options, {memory,stack}).then _
  inspect_end!
  inspect_post x, memory, ast
    ..then fulfill

print_pruned_ast = (ast) ->
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

inspect_post = (x, memory, ast) ->
  (fulfill) <- new Promise
  if ast.status == 'fail'
    inspect_memory memory[util.hash s], s
      ..then fulfill
  else
    print_pruned_ast ast
    fulfill!
