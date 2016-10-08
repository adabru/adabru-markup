ReactDOM = require 'react-dom'
React = require 'react'
{div, h1, ul, li} = React.DOM

if process.env.BROWSER?
  require '../css/factsheet.css'

AdabruFactsheet = React.createClass do
  displayName: '_Factsheet'
  getDefaultProps: ->
    thing: 'Jack the Ripper'
    facts:
      * 'dangerous'
      * 'lives in London'
  render: ->
    div do
      className: 'factsheet'
      h1 {}, @props.thing
      ul do
        {}
        [li key:i, f for f,i in @props.facts]

Object.assign exports ? this, {AdabruFactsheet}
