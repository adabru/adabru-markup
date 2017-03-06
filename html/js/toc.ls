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
      buffer = let o={items: [items: []]} then [null, null, o, o.items.0, null]
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
  # setting scrollTop causes onScroll which is problematic
  # see http://stackoverflow.com/questions/27512641
  noscroll: 0
  getDefaultProps: ->
    items:
      h1({id: 'a'}, 'uov')
      p({id: 'b'}, 'uocl')
      h2({id: 'c'}, 'ofgnf')
    scrollToCommand:
      id: 'b'
      time: Date.now!
    onScrolled: (id) ->
      console.log 'onScrolled not assigned'
  getInitialState: ->
    scrollTop: 0
    lastScrollTime: 0
    transformOrigin: 0
    mouse_y: 0
    ui_state: 0
  componentDidMount: ->
    # global scrolling
    window.document.addEventListener 'wheel', (event) ~>
      if not event.ctrlKey
        event.preventDefault()
        let t = @state.lastScrollTime, n = Date.now!
          @setState lastScrollTime: n
          # Chrome: filter out buggy monster scrolls after changing virtual desktops
          if n - t > 1000
            @setState lastScrollTime: n
          else
            @setState do
              lastScrollTime: n
              scrollTop: @state.scrollTop + (event.deltaY * [1,5][@state.ui_state]) >? 0 <? @refs.blocks.clientHeight - @refs.scroll.clientHeight
    # global key handling
    window.document.addEventListener 'keydown', (event) ~>
      if event.code is "KeyD" and @state.ui_state is 0
        @setState do
          scrollTop: @refs.scroll.scrollTop
          ui_state: 1
    window.document.addEventListener 'keyup', (event) ~>
      if event.code is "KeyD"
        @setState ui_state: 0
    # scroll to element defined in window.location.hash, after waiting a bit for document loading
    if (h=window.location.hash)?
      if h.startsWith '#:'
        index = /#:[0-9]*:([0-9]*)/.exec(h)?.1
        if index? then setTimeout (~> @scrollTo +index), 200
      else
        setTimeout (~> @scrollTo h.slice 1), 200
    #

    window.document.title = @props.items.find((i) -> i.type is "h1").props.children.0 ? "🖼"
  componentWillReceiveProps: (nextProps) ->
    if nextProps.scrollToCommand.time > @props.scrollToCommand.time
      @scrollTo nextProps.scrollToCommand.id
  shouldComponentUpdate: (nextProps,nextState) ->
    # not update on mouse event (lags)
    #
    #  states
    #  (0) normal scrolling / normal mousemove
    #  (1) zoomed
    #
    #  zoomed
    #    point p ∊ [0, H] on pane, y ∊ [0, h] value in view, transform anchor a, scrollTop sT ∊ [0, H-h], scale s
    #    y(p,s,a,sT) = s * (p - a) + a - sT
    #
    p = (propname) ~> [@state[propname],nextState[propname]]
    switch nextState.ui_state
      case 0
        [m0,m1] = p 'mouse_y' ; if m0 isnt m1 and m1 isnt -1
          for item in @props.items
            d = ReactDOM.findDOMNode(@refs[item.props.id]) ; r = d.getBoundingClientRect! ; if r.top <= m1 <= r.bottom then break
          @refs['pilcrow']
            ..style.top = d.offsetTop + (+window.getComputedStyle(d, null).getPropertyValue('padding-top').slice(0,-2))
            ..href = "\##{d.id}"
        [s0,s1] = [@refs.scroll.scrollTop, nextState.scrollTop] ; if s0 != s1
          @noscroll = Date.now! ; @refs.scroll.scrollTop = nextState.scrollTop
      case 1
        [s0,s1] = [@refs.scroll.scrollTop, nextState.scrollTop] ; if s0 != s1
          @noscroll = Date.now! ; @refs.scroll.scrollTop = nextState.scrollTop
        #  - y(p=h/2, sT=0) = h/2
        #  - y(p=H-h/2, sT=H-h) = h/2
        #  - sT const
        #    sT = 0   → a = h/2
        #    sT = H-h → a = H - h/2
        let {scrollTop:sT, mouse_y:my, transformOrigin:a} = nextState, h = @refs.scroll.clientHeight, H = @refs.blocks.clientHeight, s = 0.25
          # linear interpolation:
          _a = sT + h/2
          @setState transformOrigin:_a
          if a isnt _a
            @refs.blocks.style.transformOrigin = "50% #{_a}px"
    if _.isEqual(@props, nextProps) and @state.ui_state == nextState.ui_state
      false
    else
      true
  render: ->
    article do
      className:  if @state.ui_state is 1 then "distant_view" else ""
      div do
        ref: 'scroll'
        className: "article_scroll"
        onMouseMove: (e) ~> @setState mouse_y: e.pageY
        onMouseLeave: ~> @setState mouse_y: -1
        onScroll: (event) ~>
          if event.target == @refs.scroll
            event.preventDefault!
            if @props.onScrolled?
              viewport_height = ReactDOM.findDOMNode(this).getBoundingClientRect!.height
              for item in @props.items
                rect = ReactDOM.findDOMNode(@refs[item.props.id]).getBoundingClientRect!
                view_height = (rect.bottom <? viewport_height) - (rect.top >? 0)
                if view_height > (last_view_height ? 0)
                  scrolledToItem = item
                  last_view_height = view_height
              if scrolledToItem? then @props.onScrolled scrolledToItem.props.id
            if Math.abs(Date.now! - @noscroll) > 100
              @setState {scrollTop: event.target.scrollTop}
        a do
          className: 'pilcrow'
          ref: 'pilcrow'
          '¶'
        div do
          ref: 'blocks'
          className: "blocks"
          @props.items.map (item) ~>
            props = {key: item.props.id, ref: item.props.id}
            if typeof item.type is not 'string' then props.scrollToMe = ~> @scrollTo item.props.id
            React.cloneElement item, props
      div do
        className: 'zoom_guide'
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
      @animate {scrollTop: @refs.scroll.scrollTop + element.getBoundingClientRect().top - 50 >? 0}, 500

exports <<<
  AdabruTableofcontents: AdabruTableofcontents
  AdabruArticle: AdabruArticle
