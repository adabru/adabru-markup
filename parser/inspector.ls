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
log = console.log
write = (s) -> process.stdout.write s
todo = (s) ->
  console.log '\u001b[33mTODO: '+s+'\u001b[39m'

abpv1 = require './abpv1.js'

memory_screen = (memory, x, repaint) ->
  x_hash = ''+util.hash x
  {f,inv,bold} = colors
  line_lengths = (x.split '\n').map (s)->s.length
  line_and_col = (pos) ->
    for len,i in line_lengths
      if pos < len then return [i,pos] else pos -= len+1
  short_print = (ast, x, indent=0) ->
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
      short_print c, x, indent+1
  state = {pos: {"#{x_hash}":1, '':0}, hash:x_hash}
  onkey = (d) ->
    i = j = state.pos[state.hash]
    switch (state.hash.match(/([^:]+)/g) || []).length
      case 0
        hashes = Object.keys(memory).filter((k)->k.startsWith x_hash)
        switch d
          case '\u001b[B' then state.hash = hashes[j] ; return onkey ''
          case '\u001b[C' then j++
          case '\u001b[D' then j--
        j = (j >? 0) <? hashes.length-1
        if d == '' or i != j
          state.pos[state.hash] = j
          repaint!
      default
        switch d
          case '\u001b[A'
            matches = state.hash.match /^(.+),[^,:]+,[^,:]+:[^:]+$|()/
            state.hash = matches[1] || matches[2] ; print state.hash ; return onkey ''
          case '\u001b[B' then log 'down'
          case '\u001b[C' then j++
          case '\u001b[D' then j--
          case '0','1','2','3','4','5','6','7','8','9' then j = (j+d) .|. 0
          case '\u007f'
            s = ''+j
            j = if s.length<=1 then 0 else 0 .|. s.substr 0, s.length-1
        x = memory[state.hash].x
        j = (j >? 0) <? x.length-1
        if d == '' or i != j
          state.pos[state.hash] = j
          repaint!
  paint = ->
    key = colors.bold
    log "#{key '0-9 ← → BS'} move to character #{key 'Ctrl-C'} leave\n"
    if (state.hash.match(/([^:]+)/g) || []).length is 0
      let j = state.pos[state.hash]
        hashes = Object.keys(memory).filter((k)->k.startsWith x_hash)
        log hashes.map((k,i)->if i == j then bold k else k).join('\n')
    else
      let j = state.pos[state.hash] then let [l,c] = line_and_col j, x = memory[state.hash].x
        log "#{bold j}: line #{bold l}, col #{bold c} #{f.2 x.slice j-4>?0, j}#{f.2 bold x.substr j, 1}#{f.2 x.substr j+1, 4}".replace /\n/g, inv 'n'
        if memory[state.hash][j]? then for nt of memory[state.hash][j] then short_print memory[state.hash][j][nt], x
  {onkey, paint}

stack_screen = (stack) ->
  paint: ->
    print stack[*-3],1
    print stack[*-2],1
    print stack[*-1],1
  onkey: (->)

inspect = (x, memory, stack, isRunning=false) ->
  @status =
    stacksize: 0
    starttime: new Date!.getTime!
  @screen =
    paint: ->
      todo 'better suggestions here than just going through the buffer, e.g. some statistically trained suggestions'
    onkey: ->
  @paint = (screen=true) ~>
    let key = colors.bold
      write '\u001b[0;0H\u001b[K' + "#{key 's'} stack #{key 'm'} memory #{if isRunning then "#{key 'c'} cancel parsing [stack #{stack.length}]" else ""}"
      if screen
        process.stdout.write '\u001b[2;0H\u001b[J'
        @screen.paint!
  @start = ~>
    # write '\u001b[?47h'
    (fulfill) <~ new Promise _
    if isRunning then @interval = setInterval (~> @paint false), 1000
    process.stdin
      ..setEncoding 'utf8'
      ..setRawMode true
      ..resume!
      ..on 'data', @callback=(d) ~>
        switch d
          case 's'
            @screen = stack_screen stack, @paint
            @paint!
          case 'm'
            @screen = memory_screen memory, x, @paint
            @paint!
          case 'c'
            if isRunning
              stop = new abpv1.Ast 'INSPECTOR_STOP'
              stop.status = 'fail'
              stack.unshift stop
              log 'parsing was canceled.'
          case '\u0003'
            process.stdin.removeListener 'data', @callback
            clearInterval @interval
            log '^C'
            process.exit!
          default @screen.onkey d
    @paint!
  @end = ~>
    if @interval? then clearInterval @interval
    process.stdin.removeListener 'data', @callback
    # write '\u001b[?47l'
    process.stdin.pause!
  @

export debug_parse = (x, grammar, parser_options={}) ->
  (fulfill) <- new Promise _
  memory = {name:'inspector_memory'}
  stack = []
    ..name = 'inspector_stack'
  inspect_inst = new inspect x, memory, stack, true
  inspect_inst.start!
  ast <- abpv1.parse(x, grammar, Object.assign parser_options, {memory,stack}).then _
  inspect_inst.end!
  inspect_post x, memory, stack, ast
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

inspect_post = (x, memory, stack, ast) ->
  (fulfill) <- new Promise _
  if ast.status == 'fail'
    new inspect(x, memory, stack).start! # startAt:'memory'
  else
    print_pruned_ast ast
    fulfill ast
