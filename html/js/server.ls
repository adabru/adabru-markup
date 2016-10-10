#!/usr/bin/env lsc

require! [http,fs,util,url,path,stream]
require! [minimist, stylus]
adabruMarkup = require './core.ls'

log = console.log
print = (s) -> log util.inspect s, {+colors}
repl = (context={}) -> Object.assign require('repl').start('node> ').context, context
args = minimist process.argv.slice(2), {}

hostname = '127.0.0.1'
port = args.port ? args.p ? 5555
serverroot = path.dirname process.argv.1
docroot = args.dir ? args.d ? '.'

route = (href) ->
  request = url.parse href, true
  p = unescape request.pathname
  switch
    case p is '/' then request.localpath = docroot ; p = '/.'
    case p is '/adabrumarkup.js' then request.localpath = "#serverroot/build#p" ; request.query.download = true
    case p.startsWith '/.adabru_markup' then  request.query.download = true ; fallthrough
    default then request.localpath = "#docroot#p"
  {p,lp:request.localpath,q:request.query}

_cache = {}
cache = (filepath) ->
  switch
    case filepath is /\.(js|css)$/
      fs.createReadStream filepath
    default
      s = new stream.Readable {read:(->)}
      if _cache[filepath]?.timestamp > fs.statSync(filepath).mtime.getTime!
        s.push _cache[filepath].content ; s.push null
      else
        filecontent = ''
        fs.createReadStream filepath
          ..on 'error', -> s.emit 'error', new Error "error reading file #filepath"
          ..on 'readable', ->
            while chunk = @read! then filecontent += chunk
          ..on 'end', ->
            _cache[filepath] = timestamp: new Date!.getTime!
            switch
              case filepath is /\.styl$/
                # stylus
                (err, css) <- stylus.render filecontent, _
                if err? then s.emit 'error', err
                s.push _cache[filepath].content = css ; s.push null
              default
                # markup
                start = new Date!.getTime!
                ast <- adabruMarkup.parseDocument filecontent .then _
                end = new Date!.getTime!
                log "\u001b[01m#{path.basename filepath}\u001b[22m parsed in in #{end - start}ms"
                adabruMarkup.decorateTree ast
                s.push _cache[filepath].content = JSON.stringify ast ; s.push null
      s

server = http.createServer (req, res) ->
  {p,lp,q} = route req.url
  (err, stats) <- fs.stat lp, _
  switch
    case p is "/aaa"
      res.writeHead 200, {'Content-Type': 'text/html; charset=utf-8'}
      res.end('Du!')
    case err?
      res.writeHead 404 ; res.end!
    case stats.isDirectory!
      res.writeHead 200, {'Content-Type': 'text/html; charset=utf-8'}
      files = fs.readdirSync lp
      s = files.map((f)->if fs.statSync("#lp/#f").isDirectory! then "<a href='#p/#f'>#f/</a></br>" else "<a href='#p/#f'>#f</a></br>").join ''
      res.end s
    case stats.isFile! and q.download?
      contenttypes = {'.js':'application/javascript', '.css':'text/css', '.styl':'text/css'}
      res.writeHead 200, {'Content-Type': "#{contenttypes[path.extname lp]}; charset=utf-8"}
      cache lp
        ..on 'error', -> res.writeHead 404 ; res.end!
        ..pipe res
    case stats.isFile!
      res.writeHead 200, {'Content-Type': 'text/html; charset=utf-8'}
      s = """
        <head>
          <script src=\"/adabrumarkup.js\"></script>
          <link rel="stylesheet" type="text/css" href="/.adabru_markup/style.styl" />
        </head>
        <div id='app'>
        <script>
          var filepath = '#p?download'
          fetch(filepath, {method: 'get'}).then( r => r.text() ).then( data => {
            adabruMarkup.printDocument(JSON.parse(data), document.querySelector('\#app'))
          })
        </script>"""
      res.end s
    default
      res.writeHead 500 ; res.end!

server.listen port, hostname, -> console.log "Server running at http://#{hostname}:#{port}/"
