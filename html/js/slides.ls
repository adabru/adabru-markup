ReactDOM = require 'react-dom'
React = require 'react'
{h2, div, section, button, span} = React.DOM

require '../css/slides.styl'

AdabruSlides = React.createClass do
  displayName: '_Slides'
  getDefaultProps: -> {
    slides: [
      [
        [h2({}, 'first slide'), span({}, 'slide-body')]
        [h2({}, 'second slide')]
      ]
      [
        [h2({}, 'third slide')]
      ]
    ]
  }
  getInitialState: -> {
    slideWidth: 100
    slideHeight: 100
    cursor:
      x: 0
      y: 0
  }
  componentDidMount: ->
    @setState do
      slideWidth: @refs['0-0'].offsetWidth + parseInt(@refs['0-0'].style['margin-right']||0)
      slideHeight: @refs['0-0'].offsetHeight + parseInt(@refs['0-0'].style['margin-bottom']||0)
      # slideWidth: @refs['0-0'].offsetWidth + parseInt($(@refs['0-0']).css('margin-right'))
      # slideHeight: @refs['0-0'].offsetHeight + parseInt($(@refs['0-0']).css('margin-bottom'))
  render: ->
    buildSlide = (element, x, y) ~>
      if not y?
        if element.length > 1
          section do
            key: 'x'+x
            className: 'multislide'
            [buildSlide(s, x, y) for s,y in element]
        else
          buildSlide(element[0], x, 0)
      else
        section do
          key: 'x'+x+'y'+y
          ref: x+'-'+y
          element.map (e,i) -> React.cloneElement e, {key: i}

    totalcount = @props.slides.reduce ((a,x) -> a+x.length), 0

    div do
      className: 'slidewrap'
      onKeyDown: @onKeydown
      tabIndex: 0
      id: @props.id
      div do
        className: 'slideplane'
        style: {'transform': 'translate(-'+@state.cursor.x*@state.slideWidth+'px,-'+@state.cursor.y*@state.slideHeight+'px)'}
        [buildSlide(s, x) for s,x in @props.slides]
      div do
        className: 'progress-div'
        span do
          className: 'progress-current'
          @state.cursor.x+1
        span do
          className: 'progress-total'
          '/'+@props.slides.length
      div do
        className: 'navigation-div'
        button do
          className: 'navigation-arrow navigation-up ' + if @state.cursor.y > 0 then 'enabled' else 'disabled'
          onClick: @up
        button do
          className: 'navigation-arrow navigation-down ' + if @state.cursor.y < @props.slides[@state.cursor.x].length-1 then 'enabled' else 'disabled'
          onClick: @down
        button do
          className: 'navigation-arrow navigation-left ' + if @state.cursor.x > 0 then 'enabled' else 'disabled'
          onClick: @left
        button do
          className: 'navigation-arrow navigation-right ' + if @state.cursor.x < @props.slides.length-1 then 'enabled' else 'disabled'
          onClick: @right

  # transitions
  right: -> (@setState {cursor: {x:@state.cursor.x+1, y:0}}) if @state.cursor.x < @props.slides.length - 1
  left: -> (@setState {cursor: {x:@state.cursor.x-1,y:0}}) if @state.cursor.x > 0
  down: -> (@setState {cursor: {x:@state.cursor.x,y:@state.cursor.y+1}}) if @state.cursor.y < @props.slides[@state.cursor.x].length - 1
  up: -> (@setState {cursor: {x:@state.cursor.x,y:@state.cursor.y-1}}) if @state.cursor.y > 0

  onKeydown: (e) ->
    switch e.keyCode
      case 37 then @left()
      case 38 then @up()
      case 39 then @right()
      case 40 then @down()
    if 37<=e.keyCode and e.keyCode<=40
      e.preventDefault()

Object.assign exports ? this, {
  AdabruSlides: AdabruSlides
}
