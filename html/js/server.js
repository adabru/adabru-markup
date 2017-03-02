// Generated by LiveScript 1.5.0
(function(){
  var http, fs, util, url, path, stream, minimist, stylus, adabruMarkup, absh, search_machine, log, print, flatten, repl, hash, args, colors, hostname, ref$, port, serverroot, docroot, e, ignore, filetree, buildFileTree, flattenTree, allfiles, searcher, route, _cache, cache, i$, len$, f, server;
  http = require('http');
  fs = require('fs');
  util = require('util');
  url = require('url');
  path = require('path');
  stream = require('stream');
  minimist = require('minimist');
  stylus = require('stylus');
  adabruMarkup = require('./core.ls');
  absh = require('../../search/absh.ls').absh;
  search_machine = require('../../search/search.ls').search_machine;
  log = console.log;
  print = function(s){
    return log(util.inspect(s, {
      colors: true
    }));
  };
  flatten = function(arr){
    return [].concat.apply([], arr);
  };
  repl = function(context){
    context == null && (context = {});
    return Object.assign(require('repl').start('node> ').context, context);
  };
  hash = function(s){
    var hash, i$, to$, i;
    hash = 0;
    for (i$ = 0, to$ = s.length - 1; i$ <= to$; ++i$) {
      i = i$;
      hash = ((hash << 5) - hash) + s.charCodeAt(i) | 0;
    }
    return hash;
  };
  args = minimist(process.argv.slice(2), {});
  colors = (function(e){
    var b, i$, ref$, len$, i, j$, ref1$, len1$, f;
    b = [];
    for (i$ = 0, len$ = (ref$ = [0, 1, 2, 3, 4, 5, 6, 7]).length; i$ < len$; ++i$) {
      i = ref$[i$];
      b[i] = e("4" + i, "49");
      for (j$ = 0, len1$ = (ref1$ = [100, 101, 102, 103, 104, 105, 106, 107]).length; j$ < len1$; ++j$) {
        i = ref1$[j$];
        b[i] = e(i, "49");
      }
    }
    f = [];
    for (i$ = 0, len$ = (ref$ = [0, 1, 2, 3, 4, 5, 6, 7]).length; i$ < len$; ++i$) {
      i = ref$[i$];
      f[i] = e("3" + i, "39");
      for (j$ = 0, len1$ = (ref1$ = [90, 91, 92, 93, 94, 95, 96, 97]).length; j$ < len1$; ++j$) {
        i = ref1$[j$];
        f[i] = e(i, "39");
      }
    }
    return {
      f: f,
      b: b,
      inv: e('07', '27'),
      pos: e('27', '07'),
      bold: e('01', 22),
      dim: e('02', 22),
      reset: e('00', '00')
    };
  }.call(this, curry$(function(e1, e2, s){
    return "\u001b[" + e1 + "m" + s + "\u001b[" + e2 + "m";
  })));
  hostname = (ref$ = args.host) != null
    ? ref$
    : (ref$ = args.h) != null ? ref$ : '127.0.0.1';
  port = (ref$ = args.port) != null
    ? ref$
    : (ref$ = args.p) != null ? ref$ : 5555;
  serverroot = path.dirname(process.argv[1]);
  docroot = (ref$ = args.dir) != null
    ? ref$
    : (ref$ = args.d) != null ? ref$ : '.';
  try {
    fs.mkdirSync(docroot + "/.adabru_markup");
  } catch (e$) {
    e = e$;
  }
  try {
    fs.mkdirSync(docroot + "/.adabru_markup/cache");
  } catch (e$) {
    e = e$;
  }
  try {
    ignore = new RegExp(fs.readFileSync(docroot + "/.adabru_markup/ignore", "utf8").split("\n").filter(function(r){
      return r !== '';
    }).map(function(r){
      return "(^" + r + ")";
    }).join("|"));
  } catch (e$) {
    e = e$;
    ignore = /^$/;
  }
  filetree = (buildFileTree = function(p){
    var f;
    if (fs.statSync(p).isDirectory()) {
      return {
        name: path.basename(p),
        children: (function(){
          var i$, ref$, len$, results$ = [];
          for (i$ = 0, len$ = (ref$ = fs.readdirSync(p).filter(fn$)).length; i$ < len$; ++i$) {
            f = ref$[i$];
            results$.push(buildFileTree(p + "/" + f));
          }
          return results$;
          function fn$(f){
            return !(ignore != null && ignore.test(p + "/" + f));
          }
        }())
      };
    } else {
      return {
        name: path.basename(p)
      };
    }
  })(docroot);
  flattenTree = function(f, base){
    var _p, c;
    _p = base + "/" + f.name;
    if (f.children != null) {
      return flatten((function(){
        var i$, ref$, len$, results$ = [];
        for (i$ = 0, len$ = (ref$ = f.children).length; i$ < len$; ++i$) {
          c = ref$[i$];
          results$.push(flattenTree(c, _p));
        }
        return results$;
      }()));
    } else {
      return [_p];
    }
  };
  allfiles = flattenTree(filetree, path.dirname(docroot));
  searcher = search_machine();
  route = function(href){
    var request, p;
    request = url.parse(href, true);
    p = unescape(request.pathname);
    switch (false) {
    case p !== '/':
      p = '';
      request.localpath = docroot;
      break;
    case p !== '/adabrumarkup.js':
      request.localpath = serverroot + "/build" + p;
      request.query.download = true;
      break;
    case !p.startsWith('/.adabru_markup'):
      request.query.download = true;
      // fallthrough
    default:
      request.localpath = docroot + "" + p;
    }
    return {
      p: p,
      lp: request.localpath,
      q: request.query
    };
  };
  _cache = {};
  cache = function(filepath){
    var cachepath, cachepath_mtime, e, ref$, s, buf, x$, writeAndStore, filecontent, y$;
    cachepath = docroot + "/.adabru_markup/cache/" + path.basename(filepath) + "#" + hash(filepath);
    try {
      cachepath_mtime = fs.statSync(cachepath).mtime.getTime();
    } catch (e$) {
      e = e$;
      cachepath_mtime = 0;
    }
    switch (false) {
    case !/\.(js|css|png|svg|jpg|java|c|m|sage)$/.test(filepath):
      return fs.createReadStream(filepath);
    case !(((ref$ = _cache[filepath]) != null ? ref$.timestamp : void 8) > fs.statSync(filepath).mtime.getTime()):
      s = new stream.Readable({
        read: function(){}
      });
      s.push(_cache[filepath].content);
      s.push(null);
      return s;
    case !(cachepath_mtime > fs.statSync(filepath).mtime.getTime()):
      buf = "";
      x$ = s = fs.createReadStream(cachepath);
      x$.on('data', function(d){
        return buf += d;
      });
      x$.on('end', function(d){
        return _cache[filepath] = {
          timestamp: new Date().getTime(),
          content: buf
        };
      });
      return s;
    default:
      s = new stream.Readable({
        read: function(){}
      });
      writeAndStore = function(d){
        s.push(_cache[filepath].content = d);
        s.push(null);
        return fs.writeFile(docroot + "/.adabru_markup/cache/" + path.basename(filepath) + "#" + hash(filepath), d);
      };
      filecontent = '';
      y$ = fs.createReadStream(filepath);
      y$.on('error', function(){
        return s.emit('error', new Error("error reading file " + filepath));
      });
      y$.on('readable', function(){
        var chunk, results$ = [];
        while (chunk = this.read()) {
          results$.push(filecontent += chunk);
        }
        return results$;
      });
      y$.on('end', function(){
        var start, termination_beat;
        _cache[filepath] = {
          timestamp: new Date().getTime()
        };
        switch (false) {
        case !/\.styl$/.test(filepath):
          return stylus.render(filecontent, function(err, css){
            if (err != null) {
              s.emit('error', err);
            }
            return writeAndStore(css);
          });
        default:
          start = new Date().getTime();
          termination_beat = setInterval(function(){
            return log("parsing " + colors.bold(path.basename(filepath)) + " since " + (new Date().getTime() - start) + "ms ...");
          }, 5000);
          return adabruMarkup.parseDocument(filecontent).then(function(ast){
            var end;
            clearInterval(termination_beat);
            end = new Date().getTime();
            log(colors.bold(path.basename(filepath)) + " parsed in in " + (end - start) + "ms");
            adabruMarkup.decorateTree(ast);
            return writeAndStore(JSON.stringify(ast));
          });
        }
      });
      return s;
    }
  };
  for (i$ = 0, len$ = allfiles.length; i$ < len$; ++i$) {
    f = allfiles[i$];
    (fn$.call(this, "", f));
  }
  server = http.createServer(function(req, res){
    var ref$, p, lp, q;
    ref$ = route(req.url), p = ref$.p, lp = ref$.lp, q = ref$.q;
    return fs.stat(lp, function(err, stats){
      var expr, findings, sub_tree, s, contenttypes, x$;
      switch (false) {
      case p !== "/aaa":
        res.writeHead(200, {
          'Content-Type': 'text/html; charset=utf-8'
        });
        return res.end('Du!');
      case p !== "/search":
        res.writeHead(200, {
          'Content-Type': 'application/json; charset=utf-8'
        });
        expr = Object.keys(q)[0];
        if (expr == null) {
          return res.end(JSON.stringify([]));
        }
        findings = [];
        return searcher.search(expr, function(f){
          var filtered_findings, i$, i, max_weight, found, j$, len$, j, ref$;
          if (f != null) {
            findings = findings.concat(f);
            return findings.length < 1000;
          } else {
            filtered_findings = [];
            for (i$ = 0; i$ <= 10; ++i$) {
              i = i$;
              max_weight = 0;
              found = void 8;
              for (j$ = 0, len$ = findings.length; j$ < len$; ++j$) {
                j = j$;
                f = findings[j$];
                if (f.weight > max_weight) {
                  ref$ = [f.weight, j], max_weight = ref$[0], found = ref$[1];
                }
              }
              if (found != null) {
                filtered_findings.push(findings.splice(found, 1)[0]);
              } else {
                break;
              }
            }
            for (i$ = 0, len$ = filtered_findings.length; i$ < len$; ++i$) {
              i = i$;
              f = filtered_findings[i$];
              filtered_findings[i] = searcher.beefed(f);
            }
            return res.end(JSON.stringify(filtered_findings));
          }
        });
      case err == null:
        res.writeHead(404);
        return res.end();
      case !stats.isDirectory():
        res.writeHead(200, {
          'Content-Type': 'text/html; charset=utf-8'
        });
        sub_tree = p === ''
          ? filetree
          : p.slice(1).split('/').reduce(function(a, x){
            return a = a.children.find(function(c){
              return c.name === x;
            });
          }, filetree);
        s = "<head>\n  <script src=\"/adabrumarkup.js\"></script>\n  <title>🖼</title>\n  <link rel=\"stylesheet\" type=\"text/css\" href=\"/.adabru_markup/style.styl\" />\n</head>\n<div id='app'>\n<script>\n  adabruMarkup.printLinker(document.querySelector('#app'), " + JSON.stringify({
          filetree: sub_tree.children,
          baseurl: p,
          searchurl: '/search'
        }) + ")\n</script>";
        return res.end(s);
      case !(stats.isFile() && q.download != null):
        contenttypes = {
          '.js': 'application/javascript',
          '.css': 'text/css',
          '.styl': 'text/css',
          '.svg': 'image/svg+xml',
          '.png': 'image/png',
          '.jpg': 'image/jpg'
        };
        res.writeHead(200, {
          'Content-Type': contenttypes[path.extname(lp)] + "; charset=utf-8"
        });
        x$ = cache(lp);
        x$.on('error', function(){
          res.writeHead(404);
          return res.end();
        });
        x$.pipe(res);
        return x$;
        break;
      case !stats.isFile():
        res.writeHead(200, {
          'Content-Type': 'text/html; charset=utf-8'
        });
        s = "<head>\n  <script src=\"/adabrumarkup.js\"></script>\n  <link rel=\"stylesheet\" type=\"text/css\" href=\"/.adabru_markup/style.styl\" />\n</head>\n<div id='app'>\n<script>\n  var filepath = '" + p + "?download'\n  fetch(filepath, {method: 'get'}).then( r => r.text() ).then( data => {\n    adabruMarkup.printDocument(adabruMarkup.decorateTree(JSON.parse(data)), document.querySelector('#app'))\n  })\n</script>";
        return res.end(s);
      default:
        res.writeHead(500);
        return res.end();
      }
    });
  });
  server.listen(port, hostname, function(){
    return console.log("Server running at http://" + hostname + ":" + port + "/");
  });
  function curry$(f, bound){
    var context,
    _curry = function(args) {
      return f.length > 1 ? function(){
        var params = args ? args.concat() : [];
        context = bound ? context || this : this;
        return params.push.apply(params, arguments) <
            f.length && arguments.length ?
          _curry.call(context, params) : f.apply(context, params);
      } : f;
    };
    return _curry();
  }
  function fn$(buf, f){
    var x$;
    x$ = cache(f);
    x$.on('data', function(d){
      return buf += d;
    });
    x$.on('end', function(){
      var e;
      try {
        return searcher.addDocument(f.slice(docroot.length), JSON.parse(buf));
      } catch (e$) {
        e = e$;
        return log(colors.bold(path.basename(f)) + " could not be parsed properly");
      }
    });
  }
}).call(this);
