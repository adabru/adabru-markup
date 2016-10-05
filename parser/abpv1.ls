# Thanks to Orlando Hill

util = require 'util'
print = (o, d=10) ->
  console.log util.inspect o, {colors: true, depth: d}
todo = (s) ->
  console.log '\u001b[33mTODO: '+s+'\u001b[39m'
util.hash = (s) ->
  hash = 0
  for i from 0 to s.length-1
    hash  = (((hash .<<. 5) - hash) + s.charCodeAt i) .|. 0
  hash
util.flatten = (arr) -> [].concat.apply [], arr

export class Ast
  (@name, @start, @end=start, @lookAhead=start, @status, @children=[]) ->

adabru_v1_parser = new
  @terminal = function T({x}, pos, c)
    ast = new Ast '_T', pos
    pass = switch
      case util.isString c
        for i from 0 to c.length-1
          if c[i++] != x[pos++] then break
        c[i-1] == x[pos-1]
      case util.isArray c # char class
        pos++ < x.length
        and if c[0] == '^' then (c.slice 1).every ((cc) -> not (cc[0] <= x[pos-1] <= cc[1]))
                       else c.some ((cc) -> cc[0] <= x[pos-1] <= cc[1])
      case c is null # any
        pos++ < x.length
    ast.lookAhead = pos
    if !pass
      ast.status = 'fail'
    else
      ast.status = 'success'
      ast.end = ast.lookAhead
    return ast

  @nonterminal = !function NT(x, pos, sym, child, [_call,c_ast])
    if not c_ast? then _call child.func, x, pos, ...child.params
    else
      ast = (new Ast sym) `Object.assign` c_ast{status, start, end, lookAhead}
      if c_ast.status == 'success' then ast.children = [c_ast]
      return ast

  @alternative = !function ALT(x, pos, children, [_call,c_ast,_local], i=0, ast=new Ast '_ALT', pos)
    if not c_ast?
      _call children[i].func, x, pos, ...children[i].params
    else
      ast.lookAhead >?= c_ast.lookAhead
      switch c_ast.status
        case 'success'
          ast{status, end} = c_ast
          ast.children = [c_ast]
          return ast
        case 'fail'
          if i < children.length-1
            _local i+1, ast
          else
            ast.status = 'fail'
            return ast

  @sequence = !function SEQ(x, pos, children, [_call,c_ast,_local], ast=new Ast '_SEQ',pos)
    if not c_ast?
      _call children[ast.children.length].func, x, ast.end, ...children[ast.children.length].params
    else
      ast.lookAhead >?= c_ast.lookAhead
      switch c_ast.status
        case 'success'
          ast.children ++= c_ast
          ast{end} = c_ast
          _local ast
          if ast.children.length == children.length
            ast.status = 'success'
            return ast
        case 'fail'
          ast.status = 'fail'
          return ast

  @optional = !function OPT(x, pos, child, [_call, c_ast])
    if not c_ast? then _call child.func, x, pos, ...child.params
    else
      ast = new Ast '_OPT', pos, pos, c_ast.lookAhead, 'success'
      if c_ast.status == 'success'
        ast{end} = c_ast
        ast.children = [c_ast]
      return ast

  @star = !function STAR(x, pos, child, [_call, c_ast, _local], ast=new Ast '_STAR',pos,,,'success')
    if not c_ast? then _call child.func, x, pos, ...child.params
    else
      ast{lookAhead} = c_ast
      switch c_ast.status
        case 'success'
          ast{end} = c_ast
          ast.children ++= c_ast
          _local ast
          _call child.func, x, ast.end, ...child.params
        case 'fail'
          return ast

  @plus = ~!function PLUS(x, pos, child, [_call, c_ast])
    if not c_ast? then _call @star, x, pos, child
    else
      c_ast.name = '_PLUS'
      if c_ast.status == 'success' and c_ast.children.length == 0
        c_ast.status = 'fail'
        c_ast.end = pos
      return c_ast

  @and = !function AND(x, pos, child, [_call, c_ast])
    if not c_ast? then _call child.func, x, pos, ...child.params
    else then return new Ast '_AND', pos, pos, c_ast.lookAhead, c_ast.status, [c_ast]

  @not = !function NOT(x, pos, child, [_call, c_ast])
    if not c_ast? then _call child.func, x, pos, ...child.params
    else return new Ast '_NOT', pos, pos, c_ast.lookAhead, {'fail':'success', 'success':'fail'}[c_ast.status], [c_ast]

  @void = !function VOID(x, pos, child, [_call, c_ast])
    if not c_ast? then _call child.func, x, pos, ...child.params
    else then return new Ast '_VOID', pos, c_ast.end, c_ast.lookAhead, c_ast.status, [c_ast]

  @multipass = !function PASS({x,x_hash}, pos, children, [_call,c_ast,_local], first_ast)
    switch
      case not c_ast?
        _call children[0].func, {x,x_hash}, pos, ...children[0].params
      case not first_ast? and c_ast.status == 'fail'
        return new Ast '_PASS',pos,c_ast.end,c_ast.lookAhead,c_ast.status,[c_ast]
      case not first_ast? and c_ast.status == 'success'
        flatten = (x, ast) -->
          switch ast.name
            case '_T' then x.substring ast.start, ast.end
            case '_VOID' then ''
            default then (ast.children.map flatten x).join ''
        _local first_ast = new Ast '_PASS',pos,c_ast.end,c_ast.lookAhead,c_ast.status,[c_ast]
        first_ast.x = flatten x,c_ast
        first_ast.x_hash = x_hash+",#{pos},#{c_ast.end}:"+util.hash first_ast.x
        _call children[1].func, {first_ast.x,first_ast.x_hash}, 0, ...children[1].params
      case first_ast? and c_ast?
        first_ast
          ..children = [c_ast]
          ..status = c_ast.status
        return first_ast

  i = 0
  @parse = (stack) ~>
    _call = (func, {x,x_hash}, pos, ...params) !-> stack.push [func,  {x,x_hash}, pos, params, []]
    _local = (...s) -> stack[*-1][4] = s
    new Promise (fulfill, reject) ->
      parse_loop = ->
        while i++ < 10000
          if stack[0] instanceof Ast then return fulfill stack[0]
          if stack[*-1] instanceof Ast then ast = stack.pop! else ast = void
          last = stack[*-1]
          res = last.0 last.1, last.2, ...last.3, [_call,ast,_local], ...last.4
          if res? then stack[*-1] = res
        i := 0
        setTimeout parse_loop
      parse_loop!


bind_grammar = (grammar, impl) ->
  visit = (node) ->
    switch
      # node has one child
      case node.params[0]?.func?
        visit node.params[0]
      # node has multiple children
      case node.params[0]?[0]?.func?
        node.params[0].map visit
      case node.func is 'nonterminal'
        let nt = node.params[0]
          if grammar[nt]?
            node.params = [nt, grammar[nt]]
          else
            print "attention, nonterminal <#nt> is not defined"
            node.params = [{func:->{status:'fail'}, params:[]}]
    # replace function name with function reference
    node.func = impl[node.func]
  for symbol of grammar
    visit grammar[symbol]

decorate_parser = (parser, {
  memory={},
  first_letter_map=null
}={}) ->
  # packrat parser + multipass
  parser._nonterminal ?= parser.nonterminal
  parser.nonterminal = parser._nonterminal
  let nt = parser.nonterminal
    if first_letter_map? then parser.nonterminal = !function FIRST_LETTER_NT({x,x_hash}, pos, sym, child, [_call,c_ast])
      switch
        case c_ast?
          return c_ast
        case not first_letter_map[sym].some ((interval) -> interval[0] <= x.charCodeAt(pos) <= interval[1])
          return new Ast sym,pos,pos,pos+1,'fail'
        default
          _call nt, {x,x_hash}, pos, sym, child
  let nt = parser.nonterminal
    parser.nonterminal = !function PACKRAT_NT({x,x_hash}, pos, sym, child, [_call,c_ast])
      memory[x_hash] ?= {x}
      memory[x_hash][pos] ?= {}
      switch
        case memory[x_hash][pos][sym]? then return memory[x_hash][pos][sym]
        case c_ast? then return memory[x_hash][pos][sym]=c_ast
        default then _call nt, {x,x_hash}, pos, sym, child
  parser

export parse = (x, grammar, options={}) ->
  (fulfill, reject) <- new Promise _
  options := {memory:{},startNT:Object.keys(grammar)[0],stack:[]} `Object.assign` options

  # clone grammar for further processing
  grammar := JSON.parse JSON.stringify grammar

  # optimization: retrieve first letter ranges of NTs
  min = 0x0000
  max = 0xffff
  _ = {}
  _'¬' = (ccs) -> ccs.reduce(
    ([a,left],cc) ->
      if left < cc[0] then [a ++ [[left,cc[0]-1]], cc[1]+1] else [a, cc[1]+1]
    , [[],min]) |> ([a,left]) -> if left < max then a ++ [[left,max]] else a
  _'∪' = (...ccs) -> (ccs |> util.flatten).sort( (s,t)->s[0]>t[0] ).reduce(
    ([...as,a],cc) ->
      switch
        case not a? then [cc]
        case a[1] >= cc[0]-1 then [...as,[a[0],a[1]>?cc[1]]]
        default then [...as,a,cc]
    , [])
  _'∩' = (...ccs) -> _'¬' _'∪' ...(ccs.map _'¬')
  first_letter = (grammar,memory,{func,params:[p, ...ps]}) -->
    switch func
      case 'terminal'
        x:switch
          case util.isString p                then [[p.charCodeAt(0), p.charCodeAt(0)]]
          case util.isArray p and p[0] == '^' then _'¬' _'∪' (p.slice 1).map (cc) -> [cc.charCodeAt(0),cc.charCodeAt(1)]
          case util.isArray p                 then _'∪' p.map (cc) -> [cc.charCodeAt(0),cc.charCodeAt(1)]
          case p is null                      then [[min,max]]
        ε:[]
      case 'alternative'
        p.map(first_letter grammar,memory).reduce (a,b) ->
          x: a.x `_'∪'` b.x
          ε: a.ε `_'∪'` b.ε
        ,{x:[],ε:[]}
      case 'sequence'
        p.reduce (a,child) ->
          if a.stop then a else
            b = first_letter grammar,memory,child
            x: a.x `_'∪'` (a.ε `_'∩'` b.x)
            ε: a.ε `_'∩'` b.ε
            stop: b.ε.length == 0
        ,{x:[],ε:[[min,max]]}
      case 'and'
        a = first_letter grammar,memory,p
        return
          x:[]
          ε: a.x `_'∪'` a.ε
      case 'not'
        a = first_letter grammar,memory,p
        return
          x:[]
          ε: _'¬' (a.x `_'∪'` a.ε)
      case 'optional','star'
        a = first_letter grammar,memory,p
        return
          x:a.x
          ε:[[min,max]]
      case 'void','plus'
        first_letter grammar,memory,p
      case 'multipass'
        first_letter grammar,memory,p[0]
      case 'nonterminal'
        memory[p] ? memory[p]=first_letter grammar,memory,grammar[p]
  first_letter_map = {}
  for k of grammar
    first_letter_map[k] ?= first_letter grammar,first_letter_map,grammar[k]
  for k of first_letter_map
    first_letter_map[k] = first_letter_map[k].x ++ first_letter_map[k].ε

  # add synthetic nonterminal to grammar
  grammar._start = {func: 'nonterminal', params: [options.startNT]}

  # link parsing functions to grammar, enable parser features
  options.first_letter_map = first_letter_map
  parser = adabru_v1_parser
  parser = decorate_parser parser, options
  bind_grammar grammar, parser
  node = grammar._start

  # technical parsing
  options.stack.push [node.func, {x,x_hash:util.hash(x)}, 0, node.params, []]
  ast <- parser.parse(options.stack).then _
  if ast.end != x.length then ast.status = 'fail' ; ast.error = 'did not capture whole input'
  if ast.status == 'fail' then return fulfill ast
  # postprocess ast, result is of form {name:'S', children:['adf', {name:'A', children:…}, '[a-z]']}
  pruned = (x, ast) -->
    switch ast.name
      case '_T'
        [x.substring ast.start, ast.end]
      case '_VOID'
        []
      case '_ALT', '_SEQ', '_VOID', '_AND', '_NOT', '_OPT', '_STAR', '_PLUS', '_NT'
        # concat all pruned children
        res = []
        for element in util.flatten(ast.children.map pruned x)
          switch
            case util.isString res[res.length-1] and util.isString element
              res[res.length-1] += element
            case element != ''
              res ++= element
        res
      case '_PASS'
        pruned ast.x, ast.children[0]
      default # nonterminal
        if grammar[ast.name].flags?.pruned
          pruned x, ast.children[0]
        else
          * name: ast.name
            children: pruned x, ast.children[0]
  return fulfill pruned x,ast
