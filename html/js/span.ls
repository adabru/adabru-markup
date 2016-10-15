require! [react]
{span} = react.DOM

if process.env.BROWSER?
  require '../css/span.styl'

AdabruFit = react.createClass do
  displayName: '_Fit'
  getInitialState: -> holdon: false, hover: false
  render: ->
    span do
      className: 'fit' + if @state.hover or @state.holdon then ' active' else ''
      onMouseEnter: ~>
        @setState hover: true
        if not @state.holdon
          @setState holdon: true
          setTimeout (~> @setState holdon: false), 1000
      onMouseLeave: ~>
        @setState hover: false
      @props.children

exports <<< {AdabruFit}
