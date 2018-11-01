
ab_markup_grammar = require './build/ab_markup_grammar.json'
abp = require 'adabru-parser'

# debugging
window? <<< {abp, grammar: ab_markup_grammar}

export do
  parseDocument: (document, startNT='Document') ->
    abp.parse document, ab_markup_grammar, {startNT:startNT}

  decorateTree: (ast) ->
    visit = (ast, filter, action) ->
      if filter(ast) then action(ast)
      if ast.children? then ast.children.forEach((child) -> visit(child, filter, action))

    # merge strings
    visit do
      ast
      (ast) ->
        ast.children?.some((c) -> not c.name?) and ast.children?.length > 1
      (ast) ->
        for i in [ast.children.length-1 to 1]
          if ast.children[i].name == undefined and ast.children[i-1].name == undefined
            ast.children[i-1] += ast.children.splice(i,1)

    # link-references
    linkReference = {}
    printChild = (ast, name) ->
      ast.children?.find((c) -> c.name == name)?.children[0]
    visit do
      ast
      (ast) ~>
        ast.name == 'Linknote'
      (ast) ~>
        linkReference[printChild(ast, 'Link_Text')] = printChild(ast, 'Link_Url')
    visit do
      ast
      (ast) ~>
        ast.name == 'Link_Reference'
      (ast) ~>
        ast.linkUrl = linkReference[printChild(ast, 'Link_Text')]

    ast
