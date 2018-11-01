React = require 'react'
ReactDOM = require 'react-dom'
ReactDOMServer = require 'react-dom/server'

parser = require './parser.ls'

require '../css/reset.css'
require '../css/core.styl'
require '../css/block.styl'

{span, nav, li, a, ol, ul, h1, h2, h3, p, div, br, strong, em, code, kbd, img, table, tbody, tr, th, td, iframe} = React.DOM

{AdabruTableofcontents, AdabruArticle} = require './toc.ls'
{AdabruFiletree} = require './filetree.ls'
{AdabruCodeContainer} = require './code.ls'
{AdabruSlides} = require './slides.ls'
{AdabruFactsheet} = require './factsheet.ls'
{AdabruFit} = require './span.ls'
{AdabruLinker} = require './linker.ls'

# debugging
window? <<< {React, ReactDOM, AdabruPage, AdabruTableofcontents, AdabruArticle, AdabruFiletree, AdabruCodeContainer, AdabruSlides, AdabruFactsheet, AdabruFit}

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
      parser.parseDocument document .catch(console.log).then (ast) ->
        parser.decorateTree ast
        fulfill @printDocument ast, domNode

  printDocument: (ast, domNode) ->
    printedTree = @printTree ast
    if not domNode? then printedTree else ReactDOM.render printedTree, domNode

  getChild: (ast, name) ->
    ast.children?.find (c) -> c.name == name
  printChild: (ast, name) ->
    @getChild(ast, name)?.children[0]
  printChildren: (ast) ->
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
            url: @printTree c.children.splice(0,1).0
            options: c.children.map (cc) -> cc.children.join('')
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
      case 'List_Unordered' then ul className:'ul',   @printChildren(ast)
      case 'List_Item' then li({},   @printChildren(ast))
      case 'List_Item_Paragraph' then p({},   @printChildren(ast))

      case 'Table' then table({}, tbody({}, @printChildren(ast)))
      case 'Table_Header' then tr({},   @printChildren(ast))
      case 'Table_Header_Item' then th {}, @printChildren(ast)
      case 'Table_Body' then   @printChildren(ast)
      case 'Table_Body_Row' then tr({},   @printChildren(ast))
      case 'Table_Body_Row_Item' then td do
        colSpan: if @getChild(ast,'Table_Colspan')? then that.children.0.length + 1 else 1
        @printChildren(ast)
      case 'Table_Colspan' then undefined

      case 'Info' then div({className: 'info'},   @printChildren(ast))
      case 'Warning' then div({className: 'warning'},   @printChildren(ast))

      case 'Factsheet' then React.createElement AdabruFactsheet,
        thing: if @getChild(ast, 'Factsheet_Thing')? then @printChildren that
        facts: if (c=@getChild ast, 'Factsheet_Facts')? then @printChildren c else []
      case 'Factsheet_Fact' then @printChildren ast

      case 'Html'
        options = @getChild ast, 'Html_Options'
        if options?
          ast.children = ast.children.filter (c) -> c isnt options
          options = options.children.0.split(' ').filter((x) -> x isnt '').reduce ((a,x) -> [k,o] = x.split '=' ; a[k] = o || true ; a), {}
        iframe(srcDoc: @printChildren(ast), className:'inline', height:options?.height, "[iframes disabled]")

      case 'Paragraph' then p({}, @printChildren(ast))
      case 'Newline' then br({})

      # spans

      case 'Rawurl'
        url = ast.children.join('')
        if /^http[s]:\/\// isnt url
          # relative
          (new URL url, "#{location.origin}/raw#{location.pathname}").href
        else url

      case 'Hover'
        span do
          className: 'hover_span'
          img do
            src: @printChild(ast, 'Link_Url')
          span do
            {}
            @printChildren @getChild(ast, 'Hover_Content')
      case 'Link_Inline' then a({href:@printChild(ast, 'Link_Url')}, @printChildren @getChild(ast, 'Link_Text') )
      case 'Link_Reference' then a({href: ast.linkUrl}, @printChild(ast, 'Link_Text'))
      case 'Link_Auto'
        url = ast.children.join('')
        a({href: url}, url)
      case 'Emphasis_Italic' then em({},   @printChildren(ast))
      case 'Emphasis_Bold' then strong({},   @printChildren(ast))
      case 'Image' then img({src: (@printTree @getChild ast, 'Rawurl'), alt: @printChild(ast, 'Image_Alt')})
      case 'Apielement' then span({className: 'apielement'},    @printChildren(ast))
      case 'Keystroke' then kbd({},   @printChildren(ast))
      case 'Key' then span({className: 'keystroke'}, ast.children[0])
      case 'Brand' then span({className: 'brand'}, ast.children[0])
      case 'Path' then span className: 'path', @printChildren ast
      case 'Code' then code({}, ast.children[0])
      case 'Terminal' then span({className: 'terminal'}, ast.children[0])
      case 'Fit' then React.createElement AdabruFit,
        children: @printChildren ast
      case 'Fit_Item' then span className: 'fititem', @printChildren ast
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

  printLinker: (domNode, args) ->
    ReactDOM.render React.createElement(AdabruLinker, args), domNode

exports <<<
  parseDocument: parser.parseDocument
  decorateTree: parser.decorateTree
  printDocument: adabruMarkup.printDocument.bind(adabruMarkup)
  parseAndPrint: adabruMarkup.parseAndPrint.bind(adabruMarkup)
  printLinker: adabruMarkup.printLinker
