#!/usr/bin/env lsc

# helper functions
require! [util,tty,fs]
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
    s += "#{ast.name} #{if ast.status == 'success' then '✔' else '✘'} #{ast.start} #{ast.end} #{ast.lookAhead} "
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
  state = {pos: {"#{x_hash}":0, '':0}, hash:x_hash}
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
          case '\u001b[B'
            sub_hashes = Object.keys(memory).filter((k) -> k.startsWith(state.hash) && k != state.hash && +(k.substr(state.hash.length+1).match(/^([^,]+),/)[1]) == j)
            if sub_hashes.length > 0 then state.hash = sub_hashes.0
            return onkey ''
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
    log "#{bold '0-9 ← → BS'} move to character #{bold '↓ ↑'} change buffer\n"
    if (state.hash.match(/([^:]+)/g) || []).length is 0
      let j = state.pos[state.hash]
        hashes = Object.keys(memory).filter((k)->k.startsWith x_hash)
        log hashes.map((k,i)->if i == j then bold k else k).join('\n')
    else
      let j = state.pos[state.hash] then let [l,c] = line_and_col j, x = memory[state.hash].x
        stepDown = Object.keys(memory)
        .filter((k) -> k.startsWith(state.hash) && k != state.hash)
        .map((k) -> k.substr(state.hash.length).match(/([^,]+),([^:]+)/)[1,2])
        .filter((k) -> +k.0 == j)
        s = "#{bold j}: line #{bold l}, col #{bold c} #{f.2 x.slice j-4>?0, j}#{f.2 bold x[j]}#{f.2 x.substr j+1, 4}"
        s += "#{if stepDown.length>0 then " [↓ #{stepDown.0.0}:#{stepDown.0.1}#{if stepDown.length>1 then ", …#{stepDown.length - 1}" else ''}]" else ''}"
        log s.replace /\n/g, inv 'n'
        if memory[state.hash][j]? then for nt of memory[state.hash][j] then short_print memory[state.hash][j][nt], x
  {onkey, paint}

stack_screen = (stack) ->
  paint: ->
    print stack[*-3],1
    print stack[*-2],1
    print stack[*-1],1
  onkey: ->

stack_trace_screen = (stack_trace, repaint) ->
  {f,inv,bold} = colors
  state =
    pos: 0
    stack: []
    showLocal: false
  operator_map =
    'PACKRAT_NT':'🕮','FIRST_LETTER_NT':'🌔','FIRST_LETTER_ALT':'⎇','REGEX':'R','T':'T','PASS':'↺','PLUS':'+','STAR':'*','SEQ':'─','OPT':'?','VOID':':','NOT':'!','AND':'&','ALT':'|','NT':''
  paint = ->
    s = "#{bold '↑ ↓ → ←'} move in trace #{bold 'l'} toggle locals\n\n"
    symbols = state.stack.map ([f,x,pos,{params},local]) -> if f.name is 'NT' then params.0 else operator_map[f.name]
    last_symbol = symbols.pop!
    o = stack_trace[state.pos]
    s += "↘ "+symbols.join ' '
    s += ' ' + switch
      case not (o instanceof abpv1.Ast) then last_symbol
      case o.status == 'fail' then f.1 last_symbol
      case o.status == 'success' then f.2 last_symbol
      default then '⚠'
    s += '\n' + switch
      case (ast=o) instanceof abpv1.Ast
        u = "#{if ast.status == 'success' then f.2 '✔' else f.1 '✘'} #{ast.start} #{ast.end} #{ast.lookAhead} "
        t = state.stack[*-1].1.x.substring ast.start, ast.end
        t = if t.length < 60 then "#{f.2 t}" else "#{f.2 t.substr 0,25}…#{f.2 t.substr -25,25}"
        u += t.replace /\n/g, inv 'n'
        u += ""
        t = state.stack[*-1].1.x.substring ast.end, ast.lookAhead
        t = if t.length < 20 then "#{f.3 t}" else "#{f.3 t.substr 0,8}…#{f.3 t.substr -8,8}"
        u += t.replace /\n/g, inv 'n'
      default
        u = "↘ #{f.3 operator_map[o.0.name]}#{if o.0.name.endsWith 'NT' then f.3 o.3.params.0 else ''}"
        print_ops = ({func,node},nt=false) ->
          {params:p} = node
          precedence = ['REGEX','PLUS','STAR','OPT','VOID','NOT','AND','SEQ','ALT','FIRST_LETTER_ALT','PASS']
          switch func.name
            case 'NT', 'PACKRAT_NT', 'FIRST_LETTER_NT'
              if nt then print_ops(p.1 with node:p.1) else p.0
            case 'T' then (switch
              case util.isString p.0 then "'#{p.0}'"
              case util.isArray p.0
                "[" + p.0.map((cc) ->
                  switch
                    case cc == '^' then cc
                    case cc[0] == cc[1] then cc[0]
                    default then "#{cc[0]}-#{cc[1]}"
                ).join('') + "]"
              case p.0 is null then "."
              default then '⚠'
              ).replace /\n/g, inv 'n'
            case 'REGEX'
              # ['\\[','\\|','\\*','\\+','\\?','\\('].reduce ((a,x) -> a.replace new RegExp(x,'g'), x), p
              "#{(f.95 node.regex).replace(/\n/g, inv 'n').replace(/ /g, inv ' ')}"
            case 'STAR','PLUS','VOID','OPT','AND','NOT'
              c = print_ops p.0 with node:p.0
              if precedence.indexOf(func.name) < precedence.indexOf(p.0.func.name) then c = "(#c)"
              switch func.name
                case 'STAR' then "#c*"
                case 'PLUS' then "#c+"
                case 'VOID' then ":#c"
                case 'OPT' then "#c?"
                case 'AND' then "&#c"
                case 'NOT' then "!#c"
            case 'SEQ', 'ALT', 'FIRST_LETTER_ALT', 'PASS'
              cc = p.0.map (c) -> if precedence.indexOf(func.name) < precedence.indexOf(c.func.name) then "(#{print_ops c with node:c})" else print_ops c with node:c
              switch func.name
                case 'SEQ' then cc.join ' '
                case 'ALT', 'FIRST_LETTER_ALT' then cc.join ' | '
                case 'PASS' then cc.join ' ↺ '
            default then util.inspect p, {+colors,depth:1}
        u += "  " + print_ops {func:o.0, node:o.3}, o.0.name.endsWith 'NT'
        if state.showLocal then u += "\n#{util.inspect o.4, {+colors}}"
        u
    log s
  onkey = (key) ->
    i = j = state.pos
    stepLeft = ->
      if j is 0 then return false
      j--
      if stack_trace[j] instanceof abpv1.Ast
        k = 1 ; jj = j ; while k > 0 then if stack_trace[--jj] instanceof abpv1.Ast then k++ else k--
        state.stack.push stack_trace[jj]
      else then state.stack.pop!
      true
    stepRight = ->
      if j is stack_trace.length - 1 then return false
      if stack_trace[j] instanceof abpv1.Ast then state.stack.pop! else state.stack.push stack_trace[j]
      j++
      true
    switch key
      case '\u001b[A'
        sl = state.stack.length
        if sl > 0 then while sl <= state.stack.length and stepLeft! then
      case '\u001b[B'
        if stack_trace[j] instanceof abpv1.Ast then stepRight!
        sl = state.stack.length
        if sl > 2
          while sl <= state.stack.length and stepRight! then
          stepLeft!
      case '\u001b[C' then stepRight!
      case '\u001b[D' then stepLeft!
      case 'l' then != state.showLocal ; return repaint!
      case '\u001b[5~'
        sl = state.stack.length ; i = 1
        stepLeft! ; while sl != state.stack.length and stepLeft! then i++
        if sl != state.stack.length then while i-- > 0 then stepRight!
      case '\u001b[6~'
        sl = state.stack.length ; i = 1
        stepRight! ; while sl != state.stack.length and stepRight! then i++
        if sl != state.stack.length then while i-- > 0 then stepLeft!

    if i != j
      state.pos = j ; repaint!
  {paint, onkey}

inspect = (x, memory, stack, {running=false,stack_trace=null}) ->
  {bold} = colors
  @status =
    stacksize: 0
    starttime: new Date!.getTime!
    started: false
    running: running
    stack_trace: stack_trace
  @screen =
    paint: ->
      todo 'better suggestions here than just going through the buffer, e.g. some statistically trained suggestions'
    onkey: ->
  @istream = if process.stdin.isTTY? then process.stdin else new tty.ReadStream fs.openSync '/dev/tty', 'r'
  @paint = (screen=true) ~>
    try
      write '\u001b[0;0H\u001b[K' + "#{bold 's'} stack #{bold 'm'} memory#{if @status.stack_trace? then " #{bold 't'} stack trace" else ""}#{if @status.running then " #{bold 'c'} cancel parsing [stack #{stack.length}]" else ""}  #{bold 'Ctrl-C'} leave"
      if screen
        process.stdout.write '\u001b[2;0H\u001b[J'
        @screen.paint!
    catch e
      log e
  @start = ~>
    log "Press #{bold 'd'} to start interactive debugging"
    @istream
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
          case 't'
            if @status.stack_trace?
              @screen = stack_trace_screen @status.stack_trace, @paint
              @paint!
          case 'd'
            if not @status.started
              != @status.started
              if @status.running then @interval = setInterval (~> @paint false), 1000
              write '\u001b7\u001b[?47h'
              @paint!
          case 'c'
            if @status.running
              stop = new abpv1.Ast 'INSPECTOR_STOP'
              stop.status = 'fail'
              stack.unshift stop
              log 'parsing was canceled.'
          case '\u0003'
            @end!
            log '^C'
            process.exit!
          default @screen.onkey d
  @stopped = ~>
    @status.running = false
    if @interval? then clearInterval @interval
  @end = ~>
    if @interval? then clearInterval @interval
    @istream.removeListener 'data', @callback
    @istream.pause!
    if @istream != process.stdin then @istream.end!
    if @status.started then write '\u001b[?47l\u001b8'
  @

export debug_parse = (x, grammar, parser_options={}, {print_ast=true,stack_trace=false,small_block=true,force_debug=false}={}) ->
  (fulfill) <- new Promise _
  memory = {name:'inspector_memory'}
  stack = []
    ..name = 'inspector_stack'
  if stack_trace?
    stack_trace := []
    stack._pop = stack.pop ; stack.pop = -> x = stack._pop! ; stack_trace.push x ; x
    stack._push = stack.push ; stack.push = (...arg) -> stack_trace.push ...arg ; stack._push ...arg
  if small_block then parser_options.blocking_rate ?= 1e4
  inspect_inst = new inspect x, memory, stack, {+running,stack_trace}
  inspect_inst.start!
  ast <- abpv1.parse(x, grammar, Object.assign parser_options, {memory,stack}).catch(log).then _
  inspect_inst.stopped!
  if ast.status == 'fail'
    log 'parse failed'
    fulfill!
  else
    if not force_debug then inspect_inst.end!
    if print_ast then log printed_pruned_ast ast
    fulfill ast

printed_pruned_ast = (ast) ->
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
  short_print '',ast

# tests
if process.argv.1.endsWith 'inspector.ls'
  memory = {name:'abcd'}
  (ast) <- debug_parse('S ← [ab]', require('./abpv1.json'), {memory}).catch(log).then _
  log ast
