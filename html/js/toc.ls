ReactDOM = require 'react-dom'
React = require 'react'
{nav, li, a, ul, h1, h2, h3, p, div, br, article, span} = React.DOM
require '@pleasetrythisathome/react.animate'
_ = require 'lodash'

if process.env.BROWSER?
  require '../css/toc.styl'


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
    distant_view: false
    distant_view_nomouse: false
    cached_dom_props:
      scroll_height: 0
      blocks_height: 0
  componentDidMount: ->
    # global scrolling
    window.document.addEventListener 'wheel', (event) ~>
      if not event.ctrlKey
        event.preventDefault()
        # if not @state.distant_view
        @setState scrollTop: @state.scrollTop + event.deltaY >? 0 <? @refs.blocks.clientHeight - @refs.scroll.clientHeight
    # global key handling
    window.document.addEventListener 'keydown', (event) ~>
      if event.code is "KeyD" and not @state.distant_view
        @setState do
          scrollTop: @refs.scroll.scrollTop
          distant_view: true
          distant_view_nomouse: true
          cached_dom_props:
            scroll_height: @refs.scroll.getBoundingClientRect!.height
            blocks_height: @refs.blocks.clientHeight
    window.document.addEventListener 'keyup', (event) ~>
      if event.code is "KeyD"
        @setState distant_view:false
    # scroll to element defined in window.location.hash, after waiting a bit for document loading
    if (h=window.location.hash)?
      if h.startsWith '#:'
        index = /#:[0-9]*:([0-9]*)/.exec(h)?.1
        if index? then setTimeout (~> @scrollTo +index), 200
      else
        setTimeout (~> @scrollTo h.slice 1), 200
  componentWillReceiveProps: (nextProps) ->
    if nextProps.scrollToCommand.time > @props.scrollToCommand.time
      @scrollTo nextProps.scrollToCommand.id
  shouldComponentUpdate: (nextProps,nextState) ->
    # not update on mouse event (lags)
    needs_scroll = @refs.scroll.scrollTop != nextState.scrollTop
    switch
      case nextState.distant_view and (@state.distant_view_nomouse and not nextState.distant_view_nomouse)
        @animate {scrollTop: nextState.scrollTop}, 200
      case nextState.distant_view and ((not @state.distant_view) or needs_scroll)
        let sT = nextState.scrollTop, sH = nextState.cached_dom_props.scroll_height, bH = nextState.cached_dom_props.blocks_height
          @refs.blocks.style.transformOrigin = "50% #{sT / (bH- sH) * bH}px"
        fallthrough
      case needs_scroll
        @refs.scroll.scrollTop = nextState.scrollTop
    if _.isEqual(@props, nextProps) and _.isEqual(@state{distant_view}, nextState{distant_view})
      false
    else
      true
  render: ->
    article do
      ref: 'scroll'
      onMouseMove: @mouseMoved
      onScroll: (event) ~>
        if event.target == @refs.scroll
          if @props.onScrolled?
            viewport_height = ReactDOM.findDOMNode(this).getBoundingClientRect!.height
            for item in @props.items
              rect = ReactDOM.findDOMNode(@refs[item.props.id]).getBoundingClientRect!
              view_height = (rect.bottom <? viewport_height) - (rect.top >? 0)
              if view_height > (last_view_height ? 0)
                scrolledToItem = item
                last_view_height = view_height
            @props.onScrolled scrolledToItem.props.id
          @setState {scrollTop: event.target.scrollTop}
      a do
        className: 'pilcrow'
        ref: 'pilcrow'
        '¶'
      div do
        ref: 'blocks'
        className: if @state.distant_view then "distant_view" else ""
        @props.items.map (item) ~>
          props = {key: item.props.id, ref: item.props.id}
          if typeof item.type is not 'string' then props.scrollToMe = ~> @scrollTo item.props.id
          React.cloneElement item, props
  mouseMoved: (e) ->
    if @state.distant_view
      scroll_height = @refs.scroll.getBoundingClientRect!.height
      blocks_height = @refs.blocks.clientHeight
      scrollTop = (e.pageY / scroll_height) * (blocks_height - scroll_height)
      @setState do
        scrollTop: scrollTop
        distant_view_nomouse: false
        cached_dom_props: {scroll_height, blocks_height}
    else
      for item in @props.items
        d = ReactDOM.findDOMNode(@refs[item.props.id]) ; r = d.getBoundingClientRect! ; if r.top <= e.pageY <= r.bottom then break
      @refs['pilcrow'].style.top = d.offsetTop + +window.getComputedStyle(d, null).getPropertyValue('padding-top').slice(0,-2)
      @refs['pilcrow'].href = "\##{d.id}"
  scrollTo: (idOrIndex) ->
    element = switch
      case "string" is typeof idOrIndex and @refs[idOrIndex]?
        ReactDOM.findDOMNode(@refs[idOrIndex])
      case "string" is typeof idOrIndex and not @refs[idOrIndex]?
        console.warn 'There is no ref to a top-level element with id: "'+idOrIndex+'"! So no scrolling to it'
      case "number" is typeof idOrIndex
        ReactDOM.findDOMNode(@refs['blocks']).children[idOrIndex]
      default console.warn 'scrollTo accepts an id or an index'
    if element?
      @animate {scrollTop: @refs.scroll.scrollTop + element.getBoundingClientRect().top}, 500

Object.assign exports ? this,
  AdabruTableofcontents: AdabruTableofcontents
  AdabruArticle: AdabruArticle
