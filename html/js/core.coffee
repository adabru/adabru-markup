React = require 'react'
ReactDOM = require 'react-dom'
ReactDOMServer = require 'react-dom/server'
ab_markup_grammar = require './build/ab_markup_grammar.json'
abpv1 = require '../../parser/abpv1.js'
#
#
{span, nav, li, a, ol, ul, h1, h2, h3, p, div, br, strong, em, code, kbd, img, table, tbody, tr, th, td, iframe} = React.DOM

{AdabruTableofcontents, AdabruArticle} = require './toc.ls'
{AdabruFiletree} = require './filetree.ls'
{AdabruCodeContainer} = require './code.coffee'
{AdabruSlides} = require './slides.coffee'

if process.env.BROWSER?
  require '../css/core.css'
  require '../css/block.css'
  require '../css/span.css'

AdabruPage = React.createClass
  displayName: '_Page'
  getDefaultProps: -> {
    showTOC: true
    topItems: [
      h1({id: 'a'}, 'uov')
      p({id: 'b'}, 'uocl')
      h2({id: 'c'}, 'ofgnf')
      h3({id: 'd'}, 'oo')
    ]
  }
  getInitialState: -> {
    clicked:
      id: null
      time: 0
    shownSection: 77
  }
  render: ->
    art = React.createElement( AdabruArticle,
      items: @props.topItems
      scrollToCommand: @state.clicked
      onScrolled: @onScrolled
    )

    if @props.showTOC
      div
        id: 'adabruPage'
        React.createElement( AdabruTableofcontents,
          items: AdabruTableofcontents.extractItemsFrom(@props.topItems)
          onItemClick: (event,id) =>
            window.history.replaceState(null, null, window.location.origin + window.location.pathname + window.location.search + '#'+id)
            @setState {clicked: {id: id, time: (new Date).getTime()}}
          highlightId: @state.shownSection
        )
        art
    else
      div
        id: 'adabruPage'
        art
  onScrolled: (id) ->
    @setState {shownSection: AdabruTableofcontents.parentSectionFor(id, @props.topItems)}


adabruMarkup =
  parseAndPrint: (document, domNode) ->
    new Promise (fulfill) ->
      @parseDocument document .catch(console.log).then (ast) ->
        @decorateTree ast
        fulfill @printDocument ast, domNode

  parseDocument: (document, startNT='Document') ->
    abpv1.parse document, ab_markup_grammar, {startNT:startNT}

  printDocument: (ast, domNode) ->
    printedTree = @printTree ast
    if not domNode? then printedTree else ReactDOM.render printedTree, domNode

  decorateTree: (ast) ->
    @store = {}

    # merge strings
    @visit(
      ast
      (ast) =>
        ast.children?.some((c) -> c.name == undefined) and ast.children?.length > 1
      (ast) =>
        for i in [ast.children.length-1 .. 1]
          if ast.children[i].name == undefined and ast.children[i-1].name == undefined
            ast.children[i-1] += ast.children.splice(i,1)
    )


    # link-references
    @store.linkReference = {}

    @visit(
      ast
      (ast) =>
        ast.name == 'Linknote'
      (ast) =>
        @store.linkReference[@printChild(ast, 'Link_Text')] = @printChild(ast, 'Link_Url')
    )

    ast

  # tree utility-functions
  visit: (ast, filter, action) ->
    if filter(ast) then action(ast)
    if ast.children? then ast.children.forEach((child) -> adabruMarkup.visit(child, filter, action))

  getChild: (ast, name) ->
    ast.children?.find (c) -> c.name == name
  printChild: (ast, name) ->
    @getChild(ast, name)?.children[0]
  printChildren: (ast) ->
    if ast.children.length == 1
      @printTree(ast.children[0])
    else
      ast.children.map (c,i) =>
        t = @printTree c
        if React.isValidElement t
          React.cloneElement t, {key: i}
        else
          t

  unknownAST: (ast) ->
    console.warn 'Nonterminal "'+ast.name+'" is not known!'

  printTree: (ast) ->
    switch ast.name
      when 'Document'
        React.createElement( AdabruPage, {
          showTOC: @getChild(ast, 'Tableofcontents')?
          topItems: @getChild(ast, 'Paperroll')
            .children.map @printTree, @
            .filter (c) => c?
            .map((c,i) => React.cloneElement(c, {id: (c.props.id ? '')+'_'+i, ref: i}))
        })

      # blocks

      when 'Slides'
        React.createElement( AdabruSlides, {
          id: @printChild(ast, 'Slides_Id')
          slides: ast.children
            .filter (c) => c.name != 'Slides_Id'
            .map (c) =>
              switch c.name
                when 'Slides_Multislide'
                  single.children.map(@printTree,@) for single in c.children
                when 'Slides_Item'
                  [c.children.map(@printTree,@)]
                else
                  @unknownAST c
        })

      when 'Header_L1', 'Header_L2', 'Header_L3'
        level = ast.name[ast.name.length-1]
        processedChildren = @printChildren ast
        [h1,h2,h3][level-1](
          id: ReactDOMServer .renderToStaticMarkup(div({},processedChildren)) .replace(/<.*?>(.*?)<.*?>/g, '$1').replace(/ /g,'_')
          processedChildren
        )

      when 'Codeblock'
        React.createElement( AdabruCodeContainer, {
          syntax: @printChild(ast, 'Codelanguage')
          import: if (c=@getChild(ast, 'Codeimport'))?
            c.children.map (cc) ->
              if cc.name != 'Codeimport_Option' then console.log 'warning: "Codeimport_Option" expected but got '+cc.name
              cc.children.join('')
          content: if (c=@getChild(ast, 'Codeinline'))?
            c.children.join('')
        })

      when 'Linknote' then undefined

      when 'Filetree'
        React.createElement( AdabruFiletree, {
          basepath: @printChild(ast, 'Filetree_Basepath')
          autolink: @getChild(ast, 'Filetree_Is_Auto_Link')?
          children: @getChild(ast, 'Filetree_Root').children.map(@printTree,@)
        })
      when 'Filetree_Item' then {
        file: @printChild(ast, 'Filetree_Item_File')
        description: @printChild(ast, 'Filetree_Item_Description')
        children: if (c=@getChild(ast, 'Filetree_Item_Children'))? then c.children.map(@printTree,@) else []
      }

      when 'List_Ordered' then ol({}, @printChildren(ast))
      when 'List_Unordered' then ul({},   @printChildren(ast))
      when 'List_Item' then li({},   @printChildren(ast))
      when 'List_Item_Paragraph' then p({},   @printChildren(ast))

      when 'Table' then table({}, tbody({}, @printChildren(ast)))
      when 'Table_Header' then tr({},   @printChildren(ast))
      when 'Table_Header_Item' then th({},   @printChildren(ast))
      when 'Table_Body' then   @printChildren(ast)
      when 'Table_Body_Row' then tr({},   @printChildren(ast))
      when 'Table_Body_Row_Item' then td({},   @printChildren(ast))

      when 'Info' then div({className: 'info'},   @printChildren(ast))
      when 'Warning' then div({className: 'warning'},   @printChildren(ast))

      when 'Paragraph' then p({},   @printChildren(ast))
      when 'Newline' then br({})

      # spans

      when 'Hover'
        span
          className: 'hover_span'
          img
            src: @printChild(ast, 'Link_Url')
          span
            x: ''
            @printChildren @getChild(ast, 'Hover_Content')
      when 'Link_Inline' then a({href:@printChild(ast, 'Link_Url')}, @printChildren @getChild(ast, 'Link_Text') )
      when 'Link_Reference'
        text = @printChild(ast, 'Link_Text')
        a({href: @store.linkReference[text]}, text)
      when 'Link_Auto'
        url = ast.children.join('')
        a({href: url}, url)
      when 'Emphasis_Italic' then em({},   @printChildren(ast))
      when 'Emphasis_Bold' then strong({},   @printChildren(ast))
      when 'Image' then img({src: @printChild(ast, 'Image_Url'), alt: @printChild(ast, 'Image_Alt')})
      when 'Apielement' then span({className: 'apielement'},    @printChildren(ast))
      when 'Keystroke' then kbd({},   @printChildren(ast))
      when 'Key' then span({className: 'keystroke'}, ast.children[0])
      when 'Brand' then span({className: 'brand'}, ast.children[0])
      when 'Path' then span({className: 'path'}, ast.children[0])
      when 'Code' then code({}, ast.children[0])
      when 'Iframe' then iframe({
        src: ast.children.join('')
        onLoad: (e) ->
          {width,height} = e.target.contentDocument.body.getBoundingClientRect()
          e.target.style.height = height
          e.target.style.width = width
      })
      when undefined then ast
      else @unknownAST ast

Object.assign exports ? this, {
  parseDocument: adabruMarkup.parseDocument.bind(adabruMarkup)
  decorateTree: adabruMarkup.decorateTree.bind(adabruMarkup)
  printDocument: adabruMarkup.printDocument.bind(adabruMarkup)
  parseAndPrint: adabruMarkup.parseAndPrint.bind(adabruMarkup)
}

if window? then Object.assign window, {React, ReactDOM, abpv1, grammar: ab_markup_grammar
  ,AdabruPage, AdabruTableofcontents, AdabruArticle, AdabruFiletree, AdabruCodeContainer, AdabruSlides}
