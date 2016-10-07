ReactDOM = require 'react-dom'
React = require 'react'
{li, div, a, span, ul} = React.DOM

AdabruFiletreeItem = React.createClass do
  displayName: '_FiletreeItem'
  getDefaultProps: ->
    prefix: '/'
    autolink: true
  render: ->
    li do
      {}
      div do
        {}
        a do
          className: 'filename'
          href: if @props.autolink then @props.prefix + @props.file
          span do
            {}
            @props.file
        span do
          className: 'filedescription'
          @props.description
      ul do
        style: if @props.children.length > 0 then {} else {display: 'none'}
        [React.createElement(
          AdabruFiletreeItem
          Object.assign {}, childProps, {'prefix': @props.prefix+@props.file, 'key':i}, @props{autolink}
        ) for childProps,i in @props.children]



AdabruFiletree = React.createClass do
  displayName: '_Filetree'
  getDefaultProps: ->
    basepath: '/path/'
    autolink: true
    children:
      * file: 'someDirectory/'
        description: 'some description'
        children:
          * file: 'some.file'
            description: 'some other file'
            children: []
          ...
      ...
  render: ->
    div do
      id: @props.id
      className: 'filetree'
      ul do
        {}
        [React.createElement(
          AdabruFiletreeItem
          Object.assign {}, childProps, {'prefix': @props.basepath, 'key':i}, @props{autolink}
        ) for childProps,i in @props.children]

Object.assign exports ? this,
  AdabruFiletree: AdabruFiletree
