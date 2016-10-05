#!/usr/bin/env lsc

require! [http,fs]

hostname = '127.0.0.1'
port = 5555

server = http.createServer (req, res) ->
  switch req.url
    case "/"
      res.writeHead(200, {'Content-Type': 'text/html'})
      res.end('<meta charset="utf-8"> Hallo <img src="./bbb.jpg"/>')
      break
    case "/aaa"
      res.writeHead(200, {'Content-Type': 'text/html'})
      res.end('<meta charset="utf-8"> Du!')
      break
    default
      fs.createReadStream(".#{req.url}")
        ..on 'error', ->
          res.writeHead 404
          res.end!
        ..on 'open', ->
          res.writeHead 200, {'Content-Type': 'application/javascript'}
        ..pipe res

server.listen port, hostname, -> console.log "Server running at http://#{hostname}:#{port}/"
