ReactDOM = require 'react-dom'
React = require 'react'
{li, div, a, span, ul} = React.DOM

AdabruFiletreeItem = React.createClass
  displayName: '_Filetree'
  getDefaultProps: -> {
      prefix: '/'
    }
  render: ->
    li
      x: ''
      div
        x: ''
        a
          className: 'filename'
          href: @props.prefix + @props.file
          span
            x: ''
            @props.file
        span
          className: 'filedescription'
          @props.description
      ul
        style: if @props.children.length > 0 then {} else {display: 'none'}
        React.createElement(
          AdabruFiletreeItem
          Object.assign({}, childProps, {'prefix': @props.prefix+@props.file, 'key': childProps.file})
        ) for childProps in @props.children



AdabruFiletree = React.createClass
  displayName: '_Filetree'
  getDefaultProps: -> {
      basepath: '/path/'
      children: [
        {
          file: 'someDirectory/'
          description: 'some description'
          children: [
            {
              file: 'some.file'
              description: 'some other file'
              children: []
            }
          ]
        }
      ]
    }

  render: ->
    div
      id: @props.id
      className: 'filetree'
      ul
        x: ''
        React.createElement(
          AdabruFiletreeItem
          Object.assign({}, childProps, {'prefix': @props.basepath, 'key': childProps.file})
        ) for childProps in @props.children

Object.assign exports ? this,
  AdabruFiletree: AdabruFiletree
