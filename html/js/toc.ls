ReactDOM = require 'react-dom'
React = require 'react'
{nav, li, a, ul, h1, h2, h3, p, div, br, article} = React.DOM
require '@pleasetrythisathome/react.animate'
_ = require 'lodash'

if process.env.BROWSER?
  require '../css/toc.css'


AdabruTableofcontents = React.createClass do
  displayName: '_Tableofcontents'
  getDefaultProps: ->
    items:
      * caption: 'some header', ui: 'luv', id: '1234'
        items:
          * caption: 'some other header',id: '5678'
          ...
      ...
    onItemClick: (event) ->
      console.log 'onItemClick not assigned'
    highlightId: null
  render: ->
    build = (item,i) ~>
      * * li do
            key: i
            className: if item.id == @props.highlightId then 'highlight'
            onClick: (event) ~>
              event.preventDefault!
              console.log item.id
              @props.onItemClick event, item.id
            item.caption
        * if item.items?.length > 0
            ul {key:i+'_ul'}, [build childItem,i for childItem,i in item.items]
          else
            ul {key:i+'_ul',style:{'display': 'none'}}

    nav do
      {}
      ul do
        {}
        if @props.items? then [build childItem,i for childItem,i in @props.items]

  statics:
    extractItemsFrom: (mingledItems) ->
      buffer = [null, null, {items: []}, null, null]
      for item in mingledItems
        if item.type in ['h2', 'h3']
          level = parseInt item.type[1]
          newItem =
            caption: item.props.children
            id: item.props.id
            items: []
          buffer[level].items.push newItem
          buffer[level+1] = newItem
      buffer[2].items
    parentSectionFor: (id, mingledItems) ->
      parentId = null
      for item in mingledItems
        if item.type in ['h2', 'h3']
          parentId = item.props.id
        if item.props.id == id
          break
      parentId

AdabruArticle = React.createClass do
  displayName: '_Article'
  mixins: [React.Animate]
  getDefaultProps: ->
    items:
      h1({id: 'a'}, 'uov')
      p({id: 'b'}, 'uocl')
      h2({id: 'c'}, 'ofgnf')
    scrollToCommand:
      id: 'b'
      time: (new Date).getTime()
    onScrolled: (id) ->
      console.log 'onScrolled not assigned'
  getInitialState: ->
    scrollTop: 0
  componentDidMount: ->
    # global scrolling
    window.document.addEventListener 'wheel', (event) ~>
      if not event.ctrlKey
        event.preventDefault()
        @refs.scroll.scrollTop += event.deltaY
    # scroll to element defined in window.location.hash, after waiting a bit for document loading
    if window.location.hash then setTimeout (~> @scrollTo window.location.hash.slice 1), 200
  componentWillReceiveProps: (nextProps) ->
    if nextProps.scrollToCommand.time > @props.scrollToCommand.time
      @scrollTo nextProps.scrollToCommand.id
  shouldComponentUpdate: (nextProps,nextState) ->
    if _.isEqual(@props.items, nextProps.items) and _.isEqual(@props.onScrolled, nextProps.onScrolled)
      if @refs.scroll.scrollTop != nextState.scrollTop
        @refs.scroll.scrollTop = nextState.scrollTop
      false
    else
      true
  render: ->
    article do
      ref: 'scroll'
      onScroll: (event) ~>
        if event.target == @refs.scroll
          if @props.onScrolled?
            scrolledToItem = @props.items.find (item) ~> @refs[item.props.id].getBoundingClientRect().top >= 0
            @props.onScrolled scrolledToItem.props.id
          @setState {scrollTop: event.target.scrollTop}
      @props.items.map (item) ~>
        props = {key: item.props.id, ref: item.props.id}
        if not typeof item.type is 'string' then props.scrollToMe = ~> @scrollTo item.props.id
        React.cloneElement item, props
  scrollTo: (id) ->
    if @refs[id]?
      @animate {scrollTop: @refs.scroll.scrollTop + @refs[id].getBoundingClientRect().top}, 500
    else
      console.warn 'There is no ref to a top-level element with id: "'+id+'"! So no scrolling to it'

Object.assign exports ? this,
  AdabruTableofcontents: AdabruTableofcontents
  AdabruArticle: AdabruArticle
