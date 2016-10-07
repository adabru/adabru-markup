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
{AdabruCodeContainer} = require './code.ls'
{AdabruSlides} = require './slides.ls'

if process.env.BROWSER?
  require '../css/reset.css'
  require '../css/core.css'
  require '../css/block.css'
  require '../css/span.css'

AdabruPage = React.createClass do
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
      div do
        id: 'adabruPage'
        React.createElement( AdabruTableofcontents,
          items: AdabruTableofcontents.extractItemsFrom(@props.topItems)
          onItemClick: (event,id) ~>
            window.history.replaceState(null, null, window.location.origin + window.location.pathname + window.location.search + '#'+id)
            @setState {clicked: {id: id, time: (new Date).getTime()}}
          highlightId: @state.shownSection
        )
        art
    else
      div do
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
    @visit do
      ast
      (ast) ~>
        ast.children?.some((c) -> not c.name?) and ast.children?.length > 1
      (ast) ~>
        for i in [ast.children.length-1 to 1]
          if ast.children[i].name == undefined and ast.children[i-1].name == undefined
            ast.children[i-1] += ast.children.splice(i,1)


    # link-references
    @store.linkReference = {}

    @visit(
      ast
      (ast) ~>
        ast.name == 'Linknote'
      (ast) ~>
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
      ast.children.map (c,i) ~>
        t = @printTree c
        if React.isValidElement t
          React.cloneElement t, {key: i}
        else
          t

  unknownAST: (ast) ->
    console.warn 'Nonterminal "'+ast.name+'" is not known!'

  printTree: (ast) ->
    switch ast.name
      case 'Document'
        React.createElement( AdabruPage, {
          showTOC: @getChild(ast, 'Tableofcontents')?
          topItems: @getChild(ast, 'Paperroll')
            .children.map @printTree, @
            .filter (c) ~> c?
            .map((c,i) ~> React.cloneElement(c, {id: (c.props.id ? '')+'_'+i, ref: i}))
        })

      # blocks

      case 'Slides'
        React.createElement( AdabruSlides, {
          id: @printChild(ast, 'Slides_Id')
          slides: ast.children
            .filter (c) ~> c.name != 'Slides_Id'
            .map (c) ~>
              switch c.name
                case 'Slides_Multislide'
                  [single.children.map(@printTree,@) for single in c.children]
                case 'Slides_Item'
                  [c.children.map(@printTree,@)]
                default
                  @unknownAST c
        })

      case 'Header_L1', 'Header_L2', 'Header_L3'
        level = ast.name[ast.name.length-1]
        processedChildren = @printChildren ast
        [h1,h2,h3][level-1](
          id: ReactDOMServer .renderToStaticMarkup(div({},processedChildren)) .replace(/<.*?>(.*?)<.*?>/g, '$1').replace(/ /g,'_')
          processedChildren
        )

      case 'Codeblock'
        React.createElement( AdabruCodeContainer, {
          syntax: @printChild(ast, 'Codelanguage')
          import: if (c=@getChild(ast, 'Codeimport'))?
            c.children.map (cc) ->
              if cc.name != 'Codeimport_Option' then console.log 'warning: "Codeimport_Option" expected but got '+cc.name
              cc.children.join('')
          content: if (c=@getChild(ast, 'Codeinline'))?
            c.children.join('')
        })

      case 'Linknote' then undefined

      case 'Filetree'
        React.createElement( AdabruFiletree, {
          basepath: @printChild(ast, 'Filetree_Basepath')
          autolink: @getChild(ast, 'Filetree_Is_Auto_Link')?
          children: @getChild(ast, 'Filetree_Root').children.map(@printTree,@)
        })
      case 'Filetree_Item' then {
        file: @printChild(ast, 'Filetree_Item_File')
        description: if (c=@getChild ast, 'Filetree_Item_Description')? then @printChildren c
        children: if (c=@getChild(ast, 'Filetree_Item_Children'))? then c.children.map(@printTree,@) else []
      }

      case 'List_Ordered' then ol({}, @printChildren(ast))
      case 'List_Unordered' then ul({},   @printChildren(ast))
      case 'List_Item' then li({},   @printChildren(ast))
      case 'List_Item_Paragraph' then p({},   @printChildren(ast))

      case 'Table' then table({}, tbody({}, @printChildren(ast)))
      case 'Table_Header' then tr({},   @printChildren(ast))
      case 'Table_Header_Item' then th({},   @printChildren(ast))
      case 'Table_Body' then   @printChildren(ast)
      case 'Table_Body_Row' then tr({},   @printChildren(ast))
      case 'Table_Body_Row_Item' then td({},   @printChildren(ast))

      case 'Info' then div({className: 'info'},   @printChildren(ast))
      case 'Warning' then div({className: 'warning'},   @printChildren(ast))

      case 'Paragraph' then p({},   @printChildren(ast))
      case 'Newline' then br({})

      # spans

      case 'Hover'
        span do
          className: 'hover_span'
          img do
            src: @printChild(ast, 'Link_Url')
          span do
            {}
            @printChildren @getChild(ast, 'Hover_Content')
      case 'Link_Inline' then a({href:@printChild(ast, 'Link_Url')}, @printChildren @getChild(ast, 'Link_Text') )
      case 'Link_Reference'
        text = @printChild(ast, 'Link_Text')
        a({href: @store.linkReference[text]}, text)
      case 'Link_Auto'
        url = ast.children.join('')
        a({href: url}, url)
      case 'Emphasis_Italic' then em({},   @printChildren(ast))
      case 'Emphasis_Bold' then strong({},   @printChildren(ast))
      case 'Image' then img({src: @printChild(ast, 'Image_Url'), alt: @printChild(ast, 'Image_Alt')})
      case 'Apielement' then span({className: 'apielement'},    @printChildren(ast))
      case 'Keystroke' then kbd({},   @printChildren(ast))
      case 'Key' then span({className: 'keystroke'}, ast.children[0])
      case 'Brand' then span({className: 'brand'}, ast.children[0])
      case 'Path' then span({className: 'path'}, ast.children[0])
      case 'Code' then code({}, ast.children[0])
      case 'Terminal' then span({className: 'terminal'}, ast.children[0])
      case 'Iframe' then iframe({
        src: ast.children.join('')
        onLoad: (e) ->
          {width,height} = e.target.contentDocument.body.getBoundingClientRect()
          e.target.style.height = height
          e.target.style.width = width
      })
      case 'Info_Span' then span({className: 'info'},   @printChildren(ast))
      case 'Warning_Span' then span({className: 'warning'},   @printChildren(ast))
      case undefined then ast
      default then @unknownAST ast

Object.assign exports ? this, {
  parseDocument: adabruMarkup.parseDocument.bind(adabruMarkup)
  decorateTree: adabruMarkup.decorateTree.bind(adabruMarkup)
  printDocument: adabruMarkup.printDocument.bind(adabruMarkup)
  parseAndPrint: adabruMarkup.parseAndPrint.bind(adabruMarkup)
}

if window? then Object.assign window, {React, ReactDOM, abpv1, grammar: ab_markup_grammar
  ,AdabruPage, AdabruTableofcontents, AdabruArticle, AdabruFiletree, AdabruCodeContainer, AdabruSlides}
