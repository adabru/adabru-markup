ReactDOM = require 'react-dom'
React = require 'react'
$ = require 'jquery'
{h2, div, section, button, span} = React.DOM

if process.env.BROWSER?
  require '../css/slides.css'

AdabruSlides = React.createClass
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
    @setState
      slideWidth: @refs['0-0'].clientWidth + parseInt($(@refs['0-0']).css('margin-right'))
      slideHeight: @refs['0-0'].clientHeight + parseInt($(@refs['0-0']).css('margin-bottom'))
  render: ->
    buildSlide = (element, x, y) =>
      if not y?
        if element.length > 1
          section
            key: 'x'+x
            className: 'multislide'
            buildSlide(s, x, y) for s,y in element
        else
          buildSlide(element[0], x, 0)
      else
        section
          key: 'x'+x+'y'+y
          ref: x+'-'+y
          element.map (e,i) -> React.cloneElement e, {key: i}

    totalcount = @props.slides.reduce ((a,x) -> a+x.length), 0

    div
      className: 'slidewrap'
      onKeyDown: @onKeydown
      tabIndex: 0
      id: @props.id
      div
        className: 'slideplane'
        style: {'transform': 'translate(-'+@state.cursor.x*@state.slideWidth+'px,-'+@state.cursor.y*@state.slideHeight+'px)'}
        buildSlide(s, x) for s,x in @props.slides
      div
        className: 'progress-div'
        span
          className: 'progress-current'
          @state.cursor.x+1
        span
          className: 'progress-total'
          '/'+@props.slides.length
      div
        className: 'navigation-div'
        button
          className: 'navigation-arrow navigation-up ' + if @state.cursor.y > 0 then 'enabled' else 'disabled'
          onClick: @up
        button
          className: 'navigation-arrow navigation-down ' + if @state.cursor.y < @props.slides[@state.cursor.x].length-1 then 'enabled' else 'disabled'
          onClick: @down
        button
          className: 'navigation-arrow navigation-left ' + if @state.cursor.x > 0 then 'enabled' else 'disabled'
          onClick: @left
        button
          className: 'navigation-arrow navigation-right ' + if @state.cursor.x < @props.slides.length-1 then 'enabled' else 'disabled'
          onClick: @right

  # transitions
  right: -> (@setState {cursor: {x:@state.cursor.x+1, y:0}}) if @state.cursor.x < @props.slides.length - 1
  left: -> (@setState {cursor: {x:@state.cursor.x-1,y:0}}) if @state.cursor.x > 0
  down: -> (@setState {cursor: {x:@state.cursor.x,y:@state.cursor.y+1}}) if @state.cursor.y < @props.slides[@state.cursor.x].length - 1
  up: -> (@setState {cursor: {x:@state.cursor.x,y:@state.cursor.y-1}}) if @state.cursor.y > 0

  onKeydown: (e) ->
    switch e.keyCode
      when 37 then @left()
      when 38 then @up()
      when 39 then @right()
      when 40 then @down()
    if 37<=e.keyCode and e.keyCode<=40
      e.preventDefault()

Object.assign exports ? this, {
  AdabruSlides: AdabruSlides
}
