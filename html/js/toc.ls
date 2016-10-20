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
    transformOrigin: 0
    mouse_y: 0
    ui_state: [0]
  componentDidMount: ->
    # global scrolling
    window.document.addEventListener 'wheel', (event) ~>
      if not event.ctrlKey
        event.preventDefault()
        @setState scrollTop: @state.scrollTop + (event.deltaY * [1,5,1][@state.ui_state.0]) >? 0 <? @refs.blocks.clientHeight - @refs.scroll.clientHeight
    # global key handling
    window.document.addEventListener 'keydown', (event) ~>
      if event.code is "KeyD" and @state.ui_state.0 is 0
        @setState do
          scrollTop: @refs.scroll.scrollTop
          ui_state: [1,@state.mouse_y]
    window.document.addEventListener 'keyup', (event) ~>
      if event.code is "KeyD"
        @setState ui_state: [0]
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
    #
    #  states
    #  (0) normal scrolling / normal mousemove
    #  (1) zoomed, mouse in crater
    #  (2) zoomed, mouse freed
    #
    #  zoomed
    #    point p ∊ [0, H] on pane, y ∊ [0, h] value in view, transform anchor a, scrollTop sT ∊ [0, H-h], mouse position my ∊ [0, h]
    #    y(p,s,a,sT) = s * (p - a) + a - sT
    #
    p = (propname) ~> [@state[propname],nextState[propname]]
    switch nextState.ui_state.0
      case 0
        [m0,m1] = p 'mouse_y' ; if m0 isnt m1 and m1 isnt -1
          for item in @props.items
            d = ReactDOM.findDOMNode(@refs[item.props.id]) ; r = d.getBoundingClientRect! ; if r.top <= m1 <= r.bottom then break
          @refs['pilcrow']
            ..style.top = d.offsetTop + +window.getComputedStyle(d, null).getPropertyValue('padding-top').slice(0,-2)
            ..href = "\##{d.id}"
        [s0,s1] = [@refs.scroll.scrollTop, nextState.scrollTop] ; if s0 != s1
          @noscroll = Date.now! ; @refs.scroll.scrollTop = nextState.scrollTop
      case 1
        [m0,m1] = p 'mouse_y' ; switch
          case nextState.ui_state.1 is -1, m1 is -1 then @setState ui_state: [1,m1]
          case Math.abs(nextState.ui_state.1 - m1) > 10 then @setState ui_state: [2]
        [s0,s1] = [@refs.scroll.scrollTop, nextState.scrollTop] ; if s0 != s1
          @noscroll = Date.now! ; @refs.scroll.scrollTop = nextState.scrollTop
        #  - y(p=0, sT=0) = 0
        #  - y(p=H, sT=H-h) = h
        #  - sT const
        # → with linear interpolation a = sT / (H-h) * H
        let {scrollTop:sT, mouse_y:my, transformOrigin:a} = nextState, h = @refs.scroll.clientHeight, H = @refs.blocks.clientHeight, s = 0.25
          _a = sT / (H - h) * H
          @setState transformOrigin:_a
          if a isnt _a then @refs.blocks.style.transformOrigin = "50% #{_a}px"
      case 2
        #  - a = sT + my
        #  - my, y(0) const
        # → with CAS a' == (a*s - a + my + sT)/s, sT' == -(my*(s - 1) - a*s + a - sT)/s
        let {scrollTop:sT, mouse_y:my, transformOrigin:a} = nextState, h = @refs.scroll.clientHeight, H = @refs.blocks.clientHeight, s = 0.25
          # limiting sT
          # y(0,s,a,sT_min) = 0   →   sT_min = s * -a + a
          # y(H,s,a,sT_max) = h   →   sT_max = s * (H - a) + a - h
          sT = sT >? s*-a + a <? s * (H - a) + a - h
          y = (p,s,a,sT) -> s * (p - a) + a - sT
          _a  = (a*s - a + my + sT)/s
          _sT = -(my*(s - 1) - a*s + a - sT)/s
          _sT = Math.round _sT
          _a = Math.round _a
          @setState scrollTop:_sT, transformOrigin:_a
          # orig = @refs.blocks.style.display ; @refs.blocks.style.display = "none"
          [a0,a1] = [+(/^[^ ]* ([0-9.]*)px/.exec(@refs.blocks.style.transformOrigin)?.1 ? 0), nextState.transformOrigin] ; if a0 != a1
            @refs.blocks.style.transformOrigin = "50% #{_a}px"
          [s0,s1] = [@refs.scroll.scrollTop, nextState.scrollTop] ; if s0 != s1
            @noscroll = Date.now! ; @refs.scroll.scrollTop = nextState.scrollTop
    if _.isEqual(@props, nextProps) and (@state.ui_state.0 is 0) == (nextState.ui_state.0 is 0)
      false
    else
      true
  render: ->
    article do
      ref: 'scroll'
      className: 'article_scroll'
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
        className: "blocks " + if @state.ui_state.0 in [1 2] then "distant_view" else ""
        @props.items.map (item) ~>
          props = {key: item.props.id, ref: item.props.id}
          if typeof item.type is not 'string' then props.scrollToMe = ~> @scrollTo item.props.id
          React.cloneElement item, props
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

exports <<<
  AdabruTableofcontents: AdabruTableofcontents
  AdabruArticle: AdabruArticle
