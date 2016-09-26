ReactDOM = require 'react-dom'
React = require 'react'
{nav, li, a, ul, h1, h2, h3, p, div, br, article} = React.DOM
require '@pleasetrythisathome/react.animate'
_ = require 'lodash'

if process.env.BROWSER?
  require '../css/toc.css'

AdabruTableofcontents = React.createClass
  displayName: '_Tableofcontents'
  getDefaultProps: -> {
      items: [{
            caption: 'some header', ui: 'luv', id: '1234'
            items: [{caption: 'some other header',id: '5678'}]
          }]
      onItemClick: (event) ->
        console.log 'onItemClick not assigned'
      highlightId: null
    }
  render: ->
    build = (item) => [
          li
            className: if item.id == @props.highlightId then 'highlight'
            onClick: (event) =>
              event.preventDefault()
              @props.onItemClick event, item.id
            item.caption
          ul
            style: if not item.items?.length > 0 then {'display': 'none'} else {}
            (build(childItem) for childItem in item.items) if item.items?
      ]

    nav
      x: ''
      ul
        x: ''
        build(childItem) for childItem in @props.items

  statics:
    extractItemsFrom: (mingledItems) ->
      buffer = [null, null, {items: []}, null, null]
      for item in mingledItems
        if item.type in ['h2', 'h3']
          level = parseInt item.type[1]
          newItem = {
              caption: item.props.children
              id: item.props.id
              items: []
            }
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

AdabruArticle = React.createClass
  displayName: '_Article'
  mixins: [React.Animate]
  getDefaultProps: ->
    items: [
      h1({id: 'a'}, 'uov')
      p({id: 'b'}, 'uocl')
      h2({id: 'c'}, 'ofgnf')
    ]
    scrollToCommand:
      id: 'b'
      time: (new Date).getTime()
    onScrolled: (id) ->
      console.log 'onScrolled not assigned'
  getInitialState: ->
    scrollTop: 0
  componentDidMount: ->
    # global scrolling
    window.document.addEventListener 'wheel', (event) =>
      if not event.ctrlKey
        event.preventDefault()
        @refs.scroll.scrollTop += event.deltaY
    # scroll to element defined in window.location.hash, after waiting a bit for document loading
    if window.location.hash then setTimeout (=> @scrollTo window.location.hash.slice 1), 200

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
    article
      ref: 'scroll'
      onScroll: (event) =>
        if event.target == @refs.scroll
          if @props.onScrolled?
            scrolledToItem = @props.items.find (item) => ReactDOM.findDOMNode(@refs[item.props.id]).getBoundingClientRect().top >= 0
            @props.onScrolled scrolledToItem.props.id
          @setState {scrollTop: event.target.scrollTop}
      @props.items.map (item) =>
        React.cloneElement(item, {key: item.props.id, ref: item.props.id, scrollToMe: => @scrollTo item.props.id})
  scrollTo: (id) ->
    if @refs[id]?
      @animate {scrollTop: @refs.scroll.scrollTop + ReactDOM.findDOMNode(@refs[id]).getBoundingClientRect().top}, 1000
    else
      console.warn 'There is no ref to a top-level element with id: "'+id+'"!'

Object.assign exports ? this,
  AdabruTableofcontents: AdabruTableofcontents
  AdabruArticle: AdabruArticle
