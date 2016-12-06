require! [react]
{ul,li,a,div,span,textarea} = react.DOM

if process.env.BROWSER?
  require '../css/linker.styl'

AdabruLinker = react.createClass do
  displayName: '_Linker'
  getDefaultProps: ->
    filetree:
      * name: 'dir_a'
        children:
          * name: 'file_a1'
          * name: 'file_a2'
      * name: 'dir_b'
        children:
          * name: 'file_b1'
          ...
    baseurl: '.'
    searchurl: void
  getInitialState: ->
    search: ''
    searchResult: []
  componentDidUpdate: (_props, _state) ->
    if _state.search isnt @state.search
      fetch "#{@props.searchurl}?#{@state.search}", method: 'get'
      .then (r) -> if r.ok then r.text!
      .then (data) ~> if data? then @setState searchResult:JSON.parse data
  render: ->
    buildFileItem = ({name,children},baseurl) ~>
      li do
        key: "#baseurl/#name"
        a do
          href: "#baseurl/#name"
          name
        if children?
          ul do
            {}
            [buildFileItem c,"#baseurl/#name" for c in children]

    buildSearchItem = ({weight,filename,context,keywords}, i) ->
      li do
        key: i
        a do
          href: "#filename\##{context.0.i_ast}"
          span do
            className: "weight"
            weight
          div do
            className: "context"
            [(span {key:j, className:(if e.i in keywords then "hit " else "")+e.nt}, "#{e.s} ") for e,j in context]
          span do
            className: "filename"
            filename.split('/').reverse!.join(' ')

    div do
      className: 'linker'
      textarea do
        placeholder: 'ardour oi*[ab] Link 📆3w'
        value: @state.search
        autoFocus: true
        onChange: (e) ~> console.log "TODO: abort previous pending requests" ; @setState {search:e.target.value}
      ul do
        className: "searchresults"
        [buildSearchItem r,i for r,i in @state.searchResult]
      div do
        className: 'linker_filetree'
        ul do
          {}
          [buildFileItem c,@props.baseurl for c in @props.filetree]

exports <<< {AdabruLinker}
