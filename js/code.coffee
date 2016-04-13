ReactDOM = require 'react-dom'
React = require 'react'
hljs = require 'highlight.js'
_ = require 'lodash'
{div, code, span, pre, textarea, button} = React.DOM

if process.env.BROWSER?
  require '../css/code.css'
  require 'highlight.js/styles/xcode.css'

# container for async loading as suggested here:
# http://andrewhfarmer.com/react-ajax-best-practices/
AdabruCodeContainer = React.createClass
  displayName: '_CodeContainer'
  getInitialState: -> {
    importedContent: 'Loading file…'
  }
  componentDidMount: ->
    if @props.import?
      self = @
      fetch(self.props.import[0], {method: 'get'})
      .then (response) ->
        response.text()
      .then (text) ->
        if self.props.import[1] == 'nocomments'
          # remove all comments and preceding linebreaks
          text = text.replace(/\n?\n[ \t]*\/\/.*/g, '')
        self.setState { importedContent: text }
  render: ->
    if not @props.import?
      React.createElement(AdabruCode, @props)
    else
      childProps = _.omit(@props, ['import'])
      childProps.content = @state.importedContent
      React.createElement(AdabruCode, childProps)


AdabruCode = React.createClass
  displayName: '_Code'
  getDefaultProps: -> {
      syntax: 'javascript'
      content: 'var content=""'
      scrollToMe: ->
        console.log 'scroll not supported'
    }
  getInitialState: -> {
      contentHash: 0
      clientHeight: 0
      folded: true
      confirmationState:
        left: 0
        top: 0
        numChars: 0
        flashState: 0
    }
  componentDidMount: ->
    @highlightCode()
    @setState {
        clientHeight: ReactDOM.findDOMNode(this).clientHeight
        contentHash: @hashCode @props.content
      }
  componentWillReceiveProps: (nextProps) ->
    if @state.contentHash != @hashCode nextProps.content
      # trigger new measurement
      @setState { clientHeight: 0 }
  componentDidUpdate: ->
    @highlightCode()
    hash = @hashCode @props.content
    if @state.contentHash != hash
      # content changed
      @setState {
          clientHeight: ReactDOM.findDOMNode(this).clientHeight
          contentHash: hash
        }

  render: ->
    # copy-confirmation
    conf = span
      className: 'copyconfirmation ' + if @state.confirmationState.flashState == 0 then 'flash1' else 'flash2'
      style:
        left: @state.confirmationState.left
        top: @state.confirmationState.top
      @state.confirmationState.numChars + ' Zeichen kopiert!'

    # whole dom
    if @state.clientHeight < 300
      pre
        onMouseUp: @copyContent
        code
          className: @props.syntax
          @props.content
        textarea
          value: @props.content
          readOnly: true
        conf
    else
      self = @

      div
        className: 'code-wrapper'
        pre
          className: if @state.folded then 'collapsed' else 'expanded'
          style:
            height: if @state.folded then 200 else @state.clientHeight
          onMouseUp: @copyContent
          div
            className: 'code-fade'
          code
            className: @props.syntax
            @props.content
          textarea
            value: @props.content
            readOnly: true
          conf
        button
          onClick: @toggleCollapse

  highlightCode: ->
    # source: https://github.com/akiran/react-highlight/blob/master/src/index.jsx
    hljs.highlightBlock ((ReactDOM.findDOMNode this).querySelector 'code')
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
    @setState { confirmationState:
        flashState: (@state.confirmationState.flashState + 1) % 2
        numChars: length
        left: event.pageX
        top: event.pageY
      }
  toggleCollapse: (event) ->
    if not @state.folded
      @props.scrollToMe()
      #         var scrollDiff = $('article').scrollTop() + $(self).offset().top - 50
      #         $('article').animate({scrollTop: scrollDiff}, 400)
    @setState { folded: not @state.folded }
  hashCode: (str) ->
      str.length

Object.assign exports ? this, {
  AdabruCodeContainer: AdabruCodeContainer
}
