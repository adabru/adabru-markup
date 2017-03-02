#!/usr/bin/env lsc

require! [fs,util,vm]
require! [livescript]

log = console.log
print = (o) -> console.log util.inspect o,{+colors}
write = (s) -> process.stdout.write s
flatten = (arr) -> [].concat.apply [], arr
absh = (o) ->
  buf = {}
  history =
    filename: "#{process.env.HOME}/.livescript_repl.history"
    entries: []
    pos: -1
  try history.entries = fs.readFileSync(history.filename, 'utf8').split '\n' catch e then
  global <<< o
  process.stdin
    ..setEncoding 'utf8'
    ..setRawMode true
    ..resume!
    ..on 'data', callback=(d) ->
      moveTo = (newPos, oldPos=buf.pos) ->
        let X0=oldPos+2, X1=newPos+2, C=process.stdout.columns
          if (dx = (X1%C)-(X0%C)) > 0 then write '\u001b[C'.repeat dx else write '\u001b[D'.repeat -dx
          if (dy = ~~(X1/C)-~~(X0/C)) > 0 then write '\u001b[B'.repeat dy else write '\u001b[A'.repeat -dy
          # print [oldPos,newPos,dx,dy,C]
        newPos
      fixCursor = (pos) ->
        if (pos+2) % process.stdout.columns is 0
          write ' \u001b[D'
      paintBuf = (x0,x1) -> moveTo 0,x0 ; write "\u001b[J#{buf.content}" ; fixCursor buf.content.length ; moveTo x1, buf.content.length
      switch d
        case '\u001b[5~' then
        case '\u001b[6~' then
        case '\u001b[A'
          pos = history.entries.slice!.reverse!.findIndex (x,i) -> i > history.pos and x.startsWith buf.content.slice 0,buf.pos
          if pos isnt -1
            history.pos = pos
            buf.content = history.entries[*-pos-1]
            paintBuf buf.pos,buf.pos
        case '\u001b[B'
          let H = history.entries.length
            pos = history.entries.findIndex (x,i) -> i > (H - 1 - history.pos) and x.startsWith buf.content.slice 0,buf.pos
            if pos isnt -1
              history.pos = pos = H-1 - pos
              buf.content = history.entries[*-pos-1]
              paintBuf buf.pos,buf.pos
        case '\u001b[C' then buf.pos = moveTo buf.pos+1 <? buf.content.length
        case '\u001b[D' then buf.pos = moveTo buf.pos-1 >? 0
        case '\u001b[H' then buf.pos = moveTo 0
        case '\u001b[F' then buf.pos = moveTo buf.content.length
        case '\u001b[3~'
          buf.content = "#{buf.content.slice 0,buf.pos}#{buf.content.slice buf.pos+1}"
          paintBuf buf.pos,buf.pos
        case '\u007f'
          buf.content = "#{buf.content.slice 0,(buf.pos-1)>?0}#{buf.content.slice buf.pos}"
          paintBuf buf.pos, buf.pos=buf.pos-1>?0
        case '\r'
          try
            write '\n'
            c = livescript.compile buf.content, {+bare, -header}
            global.require = require
            print vm.runInThisContext c
          catch e then log e
          if history.entries[*-1] isnt buf.content then history.entries.push buf.content
          history.pos = -1
          buf := content:'', pos:0 ; write "> "
        case '\t'
          [_,token] = buf.content.slice(0,buf.pos) is / *(.*)$/
          if (token is /(.*?)\.([^.]*)$/)? then [_,o0,o1] = token is /(.*?)\.([^.]*)$/
                                           else [_,o0,o1] = "global.#token" is /(.*?)\.([^.]*)$/
          try
            o = o0
            p = []
            try loop
              p.unshift Object.getOwnPropertyNames(vm.runInThisContext livescript.compile "#o", {+bare, -header}).filter((x) -> x.startsWith o1).sort!
              o += ".__proto__"
            catch e then
            p_flat = flatten p
            switch
              case p_flat.length is 1
                callback p_flat.0.slice o1.length
              case p_flat.length > 1
                for _p in p
                  maxlen = _p.reduce ((a,x) -> a >? x.length), 0
                  cols = Math.floor (process.stdout.columns+2) / (maxlen+2)
                  rows = []
                  let cs = cols, l = _p.length then while l > 0 then $ = Math.ceil l / cs-- ; l -= $ ; rows.push $
                  write '\n'
                  r = c = 0
                  for i from 0 to _p.length - 1
                    s = _p[r+rows.slice(0,c).reduce(((a,x)->a+x),0)]
                    write "#s#{{true:'\n',false:' '.repeat maxlen - s.length + 2}[c is cols-1]}"
                    if ++c is cols then [r,c] = [r+1,0]
                  write "\n"
                write "\n> " ; paintBuf 0,buf.pos
                longestprefix = ''
                if p_flat.every((x)->x.startsWith p_flat.0) then longestprefix = p_flat.0
                else
                  while longestprefix isnt p_flat.0 and p_flat.every((x)->x.startsWith longestprefix)
                    longestprefix = p_flat.0.slice 0,longestprefix.length+1
                  longestprefix .= slice 0,-1
                callback longestprefix.slice o1.length
          catch e
            log e
            void
        case '\u0003'
          log '^C'
          if buf.content.length > 0
            buf := content:'', pos:0 ; write "> "
            history.pos = -1
          else
            process.stdin
              ..pause!
              ..setRawMode false
              ..removeListener 'data', callback
          try fs.writeFileSync history.filename, history.entries.join '\n'
        default
          buf.content = "#{buf.content.slice 0,buf.pos}#d#{buf.content.slice buf.pos}"
          paintBuf buf.pos, buf.pos += d.length
          # print d
  log "Node #{process.version} Livescript v#{livescript.VERSION}"
  buf := content:'', pos:0 ; write "> "



exports <<< {absh}

if process.argv.1.endsWith 'absh.ls'
  help = -> console.log '''


    livescript repl implementation

    terminal usage: \u001b[1mabsh.ls\u001b[0m
    JS usage: \u001b[1mrequire("absh")(context)\u001b[0m

    '''
  if process.argv.2 in ["-h", "help", "-help", "--help"] then return help!

  i = 2
  let j = 3
    absh {j}
