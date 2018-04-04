#!/usr/bin/env lsc

help = -> console.log '''


  \u001b[1musage\u001b[0m: server [options]

      --bind, -b <ip>            listen on address ip (default 127.0.7.1)
      --port, -p <port>          listen on port port  (default 7000)
      --dir, -d <directory>      serve files contained in directory
      --help

  \u001b[1mExamples\u001b[0m
  ch.ls ./test/a* ./test/b* -s 'some keywords'

  '''
if process.argv.2 in ["-h", "help", "-help", "--help", void] then return help!

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

hostname = args.bind ? args.b ? '127.0.7.1'
port = args.port ? args.p ? 7000
serverroot = path.dirname process.argv.1
docroot = args.dir ? args.d ? '.'
cacheroot = args.cache ? "#docroot/.adabru_markup/cache"

try fs.mkdirSync "#docroot/.adabru_markup" catch e then
try fs.mkdirSync cacheroot catch e then
try ignore = new RegExp fs.readFileSync("#docroot/.adabru_markup/ignore", "utf8").split("\n").filter((r)->r isnt '').map((r)->"(^#r)").join("|")
catch e then ignore = /^$/

filetree = (buildFileTree = (p) ->
  if fs.statSync(p).isDirectory!
    name: path.basename p
    children: [buildFileTree "#p/#f" for f in fs.readdirSync(p).filter (f) -> not (ignore? and ignore.test "#p/#f")]
  else
    name: path.basename p) docroot
 |> omitEmpty = (f) -> if not f.children? then f else
    {f.name, children:f.children.map(omitEmpty).filter((c)->not (c.children?.length == 0))}
flattenTree = ((f,base) -> _p="#base/#{f.name}" ; if f.children? then flatten [flattenTree c,_p for c in f.children] else [_p])
allfiles = flattenTree filetree, path.dirname docroot

searcher = search_machine!

# only parsed files are cached (no images, scripts, …)
_cache = {}
cache = (filepath) ->
  cachepath = "#cacheroot/#{path.basename filepath}##{hash filepath}"
  try cachepath_mtime = fs.statSync(cachepath).mtime.getTime! catch e then cachepath_mtime = 0
  switch
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
        s.push _cache[filepath].content = d ; s.push null ; fs.writeFile cachepath, d, (->)
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
  # route
  {pathname, query} = url.parse req.url, true
  p = decodeURI pathname
  r = RegExp
  not_found = -> res.writeHead 404 ; res.end "file #p not found!"
  serv_err = (e) ->
    console.error e
    res.statusCode = 500 ; res.end "server error, sorry!"
  pipe_stream = (contenttype, build_stream) ->
    try
      # implicit header
      res.statusCode = 200 ; res.setHeader 'Content-Type', "#contenttype; charset=utf-8"
      build_stream!
        ..on 'error', (e) -> if e.code is 'ENOENT' then not_found! else serv_err e
        ..pipe res
    catch e then serv_err e

  switch
    | '/aaa' is p
      res.writeHead 200, {'Content-Type': 'text/html; charset=utf-8'}
      res.end('Du!')
    | '/search' is p
      res.writeHead 200, {'Content-Type': 'application/json; charset=utf-8'}
      if not query.q? then return res.end JSON.stringify []
      findings = []
      f <- searcher.search query.q, _
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
    | '/app.js' is p
      pipe_stream 'application/javascript', (-> fs.createReadStream "#serverroot/build/adabrumarkup.js")
    | '/.adabru_markup/style.styl' is p
      pipe_stream 'text/css', (-> cache "#docroot#p")
    | r('^/raw/') .test p
      contenttypes = {'.js':'application/javascript', '.css':'text/css', '.styl':'text/css', '.svg':'image/svg+xml', '.png':'image/png', '.jpg':'image/jpg'}
      pipe_stream contenttypes[path.extname p], (-> fs.createReadStream "#docroot#{p.substr 4}")
    | r('^/api/v0.1/') .test p
      pipe_stream 'application/json', (-> cache "#docroot#{p.substr 9}")
    | _
      node = p.split('/').filter((f) -> f isnt '').reduce(((a,x) -> a?.children?.find((c) -> c.name is x)), filetree)
      switch
        | node?.children?
          # folder
          res.writeHead 200, {'Content-Type': 'text/html; charset=utf-8'}
          s = """
            <head>
              <script src=\"/app.js\"></script>
              <title>🖼</title>
              <link rel="stylesheet" type="text/css" href="/.adabru_markup/style.styl" />
            </head>
            <div id='app'>
            <script>
              adabruMarkup.printLinker(document.querySelector('\#app'), #{JSON.stringify filetree:node.children, baseurl:p.substr(1), searchurl:'/search'})
            </script>"""
          res.end s
        | node?.name?
          # file
          res.writeHead 200, {'Content-Type': 'text/html; charset=utf-8'}
          s = """
            <head>
              <script src=\"/app.js\"></script>
              <link rel="stylesheet" type="text/css" href="/.adabru_markup/style.styl" />
            </head>
            <div id='app'>
            <script>
              var filepath = '/api/v0.1#p'
              fetch(filepath, {method: 'get'}).then( r => r.text() ).then( data => {
                adabruMarkup.printDocument(adabruMarkup.decorateTree(JSON.parse(data)), document.querySelector('\#app'))
              })
            </script>"""
          res.end s
        | _ => not_found!

server.listen port, hostname, -> console.log "Server running at http://#{hostname}:#{port}/"
