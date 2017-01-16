#!/usr/bin/env lsc

require! [http,fs,util,url,path,stream]
require! [minimist, stylus]
adabruMarkup = require './core.ls'
{absh} = require '../../search/absh.ls'
{search_machine} = require '../../search/search.ls'

log = console.log
print = (s) -> log util.inspect s, {+colors}
flatten = (arr) -> [].concat.apply [], arr
repl = (context={}) -> Object.assign require('repl').start('node> ').context, context
hash = (s) -> hash = 0 ; (for i from 0 to s.length-1 then hash  = (((hash .<<. 5) - hash) + s.charCodeAt i) .|. 0) ; hash
args = minimist process.argv.slice(2), {}
colors = let e = ((e1,e2,s) --> "\u001b[#{e1}m#{s}\u001b[#{e2}m")
    b = [] ; for i in [0 to 7] then b[i]=e("4#i","49") ; for i in [100 to 107] then b[i]=e(i,"49")
    f = [] ; for i in [0 to 7] then f[i]=e("3#i","39") ; for i in [90 to 97] then f[i]=e(i,"39")
    {f,b,inv:e('07','27'), pos:e('27','07'), bold:e('01',22), dim:e('02',22), reset:e('00','00')}

hostname = args.host ? args.h ? '127.0.0.1'
port = args.port ? args.p ? 5555
serverroot = path.dirname process.argv.1
docroot = args.dir ? args.d ? '.'

try fs.mkdirSync "#docroot/.adabru_markup" catch e then
try fs.mkdirSync "#docroot/.adabru_markup/cache" catch e then
try ignore = new RegExp fs.readFileSync("#docroot/.adabru_markup/ignore", "utf8").split("\n").filter((r)->r isnt '').map((r)->"(^#r)").join("|")
catch e then ignore = /^$/

filetree = (buildFileTree = (p) ->
  if fs.statSync(p).isDirectory!
    name: path.basename p
    children: [buildFileTree "#p/#f" for f in fs.readdirSync(p).filter (f) -> not (ignore? and ignore.test "#p/#f")]
  else
    name: path.basename p) docroot
flattenTree = ((f,base) -> _p="#base/#{f.name}" ; if f.children? then flatten [flattenTree c,_p for c in f.children] else [_p])
allfiles = flattenTree filetree, path.dirname docroot

searcher = search_machine!

route = (href) ->
  request = url.parse href, true
  p = unescape request.pathname
  switch
    case p is '/' then p = '' ; request.localpath = docroot
    case p is '/adabrumarkup.js' then request.localpath = "#serverroot/build#p" ; request.query.download = true
    case p.startsWith '/.adabru_markup' then  request.query.download = true ; fallthrough
    default then request.localpath = "#docroot#p"
  {p,lp:request.localpath,q:request.query}

_cache = {}
cache = (filepath) ->
  cachepath = "#docroot/.adabru_markup/cache/#{path.basename filepath}##{hash filepath}"
  try cachepath_mtime = fs.statSync(cachepath).mtime.getTime! catch e then cachepath_mtime = 0
  switch
    case filepath is /\.(js|css|png|svg|jpg|java|c|m|sage)$/
      fs.createReadStream filepath
    case _cache[filepath]?.timestamp > fs.statSync(filepath).mtime.getTime!
      s = new stream.Readable {read:(->)} ; s.push _cache[filepath].content ; s.push null ; s
    case  cachepath_mtime > fs.statSync(filepath).mtime.getTime!
      buf = ""
      s = fs.createReadStream(cachepath)
        ..on 'data', (d) -> buf += d
        ..on 'end', (d) -> _cache[filepath] = timestamp: new Date!.getTime!, content: buf
      s
    default
      s = new stream.Readable {read:(->)}
      writeAndStore = (d) ->
        s.push _cache[filepath].content = d ; s.push null ; fs.writeFile "#docroot/.adabru_markup/cache/#{path.basename filepath}##{hash filepath}", d
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
              writeAndStore css
            default
              # markup
              start = new Date!.getTime!
              termination_beat = setInterval do
                (-> log "parsing #{colors.bold path.basename filepath} since #{new Date!.getTime! - start}ms ...")
                5000
              ast <- adabruMarkup.parseDocument filecontent .then _
              clearInterval termination_beat
              end = new Date!.getTime!
              log "#{colors.bold path.basename filepath} parsed in in #{end - start}ms"
              adabruMarkup.decorateTree ast
              writeAndStore JSON.stringify ast
      s

for f in allfiles
  let buf = "", f=f
    cache f
      ..on 'data' (d) -> buf += d
      ..on 'end', ->
        try searcher.addDocument f.slice(docroot.length),JSON.parse buf
        catch e then log "#{colors.bold path.basename f} could not be parsed properly"

server = http.createServer (req, res) ->
  {p,lp,q} = route req.url
  (err, stats) <- fs.stat lp, _
  switch
    case p is "/aaa"
      res.writeHead 200, {'Content-Type': 'text/html; charset=utf-8'}
      res.end('Du!')
    case p is "/search"
      res.writeHead 200, {'Content-Type': 'application/json; charset=utf-8'}
      expr = Object.keys(q).0
      if not expr? then return res.end JSON.stringify []
      findings = []
      f <- searcher.search expr, _
      if f? then findings ++= f ; findings.length < 1000
      else
        filtered_findings = []
        for i from 0 to 10
          max_weight = 0 ; found = void
          for f,j in findings then (if f.weight > max_weight then [max_weight,found]=[f.weight,j])
          if found? then filtered_findings.push findings.splice(found,1).0 else break
        for f,i in filtered_findings
          filtered_findings[i] = searcher.beefed f
        res.end JSON.stringify filtered_findings
    case err?
      res.writeHead 404 ; res.end!
    case stats.isDirectory!
      res.writeHead 200, {'Content-Type': 'text/html; charset=utf-8'}
      sub_tree = if p is '' then filetree else p.slice(1).split('/').reduce ((a,x)->a .= children.find (c) -> c.name is x), filetree
      s = """
        <head>
          <script src=\"/adabrumarkup.js\"></script>
          <title>🖼</title>
          <link rel="stylesheet" type="text/css" href="/.adabru_markup/style.styl" />
        </head>
        <div id='app'>
        <script>
          adabruMarkup.printLinker(document.querySelector('\#app'), #{JSON.stringify filetree:sub_tree.children, baseurl:p, searchurl:'/search'})
        </script>"""
      res.end s
    case stats.isFile! and q.download?
      contenttypes = {'.js':'application/javascript', '.css':'text/css', '.styl':'text/css', '.svg':'image/svg+xml', '.png':'image/png', '.jpg':'image/jpg'}
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
            adabruMarkup.printDocument(adabruMarkup.decorateTree(JSON.parse(data)), document.querySelector('\#app'))
          })
        </script>"""
      res.end s
    default
      res.writeHead 500 ; res.end!

server.listen port, hostname, -> console.log "Server running at http://#{hostname}:#{port}/"
