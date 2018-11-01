ReactDOM = require 'react-dom'
React = require 'react'
hljs = require 'highlight.js'
{div, code, span, pre, textarea, button} = React.DOM

require 'highlight.js/styles/xcode.css'
require '../css/code.styl'

# container for async loading as suggested here:
# http://andrewhfarmer.com/react-ajax-best-practices/
AdabruCodeContainer = React.createClass do
  displayName: '_CodeContainer'
  getInitialState: -> {
    importedContent: 'Loading file…'
  }
  componentDidMount: ->
    if @props.import?
      self = @
      fetch(self.props.import.url, {method: 'get'})
      .then (response) ->
        response.text()
      .then (text) ->
        for o in self.props.import.options
          switch
            | 'nocomments' is o
              # remove all comments and preceding linebreaks
              text = text.replace(/\n?\n[ \t]*\/\/.*/g, '')
            | /^\/.*\/$/ is o
              console.log text.length
              # keep only matching group
              text = (new RegExp o.substr 1, o.length - 2).exec(text)?.1 or "regex match failed, check code-import option"
              console.log text.length
        self.setState { importedContent: text }
  render: ->
    if not @props.import?
      React.createElement AdabruCode, @props
    else
      pp = {} <<< @props ; pp.content =@state.importedContent
      React.createElement AdabruCode, pp


AdabruCode = React.createClass do
  displayName: '_Code'
  getDefaultProps: ->
    syntax: 'javascript'
    content: 'var content=""'
    scrollToMe: ->
      console.log 'scroll not supported'
  getInitialState: ->
      contentHash: 0
      clientHeight: 0
      folded: true
      confirmationState:
        left: 0
        top: 0
        numChars: 0
        flashState: 0
  componentDidMount: ->
    # https://highlightjs.org/usage/
    <~ setTimeout _, 100
    hljs.highlightBlock @refs["code"]
    @setState do
      clientHeight: @refs["code"].clientHeight
      contentHash: @hashCode @props.content
  componentDidUpdate: (prevProps, prevState) ->
    hash = @hashCode @props.content
    if @state.contentHash != hash
      # content changed
      @setState do
        clientHeight: @refs["code"].clientHeight
        contentHash: hash
    if not /hljs/.test @refs["code"].className
      <~ setTimeout _, 100
      hljs.highlightBlock @refs["code"]
  render: ->
    # copy-confirmation
    conf = span do
      className: 'copyconfirmation ' + if @state.confirmationState.flashState == 0 then 'flash1' else 'flash2'
      style:
        left: @state.confirmationState.left
        top: @state.confirmationState.top
      @state.confirmationState.numChars + ' Zeichen kopiert!'

    # whole dom
    if @state.clientHeight < 300
      pre do
        onMouseUp: @copyContent
        code do
          ref: "code"
          className: @props.syntax
          @props.content
        textarea do
          value: @props.content
          readOnly: true
        conf
    else
      self = @

      div do
        className: 'code-wrapper'
        pre do
          className: if @state.folded then 'collapsed' else 'expanded'
          style:
            height: if @state.folded then 200 else @state.clientHeight
          onMouseUp: @copyContent
          code do
            ref: "code"
            className: @props.syntax
            @props.content
          textarea do
            value: @props.content
            readOnly: true
          conf
        button do
          onClick: @toggleCollapse

  copyContent: (event) ->
    # copy to clipboard
    selection = window.getSelection().toString()
    length = 'x'
    if selection == ""
      ta = ReactDOM.findDOMNode(@).querySelector('textarea')
      ta.select()
      length = ta.innerHTML.length
    else
      length = selection.length
    document.execCommand('copy')

    # show confirmation
    # animation on update: https://github.com/ordishs/react-animation-example
    @setState confirmationState:
      flashState: (@state.confirmationState.flashState + 1) % 2
      numChars: length
      left: event.pageX
      top: event.pageY
  toggleCollapse: (event) ->
    if not @state.folded
      @props.scrollToMe()
    @setState { folded: not @state.folded }
  hashCode: (str) ->
    str.length

exports <<<
  AdabruCodeContainer: AdabruCodeContainer
