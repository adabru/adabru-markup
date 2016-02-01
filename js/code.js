adabruMarkup.setupCode = function(codepre) {
  // code copy on click
  if (adabruMarkup.setupCode.copyconfirmation == null) {
    adabruMarkup.setupCode.copyconfirmation = $('<span>').addClass('copyconfirmation').html('Kopiert!')
    $('body').append(adabruMarkup.setupCode.copyconfirmation)
  }
  var enableMousecopy = function () {
    var code = $(this).children('code')

    var ta = $('<textarea>').html(code.html())
    $(this).append(ta)

    $(this).mouseup( function(event) {
      var selection = window.getSelection().toString()
      var length = 'x'
      if (selection == "") {
        ta.select()
        length = ta.html().length
      } else {
        length = selection.length
      }
      document.execCommand('copy')
      adabruMarkup.setupCode.copyconfirmation
        .stop(true)
        .css('left', event.pageX)
        .css('top', event.pageY)
        .html(length + ' Zeichen kopiert!')
        .fadeIn(0)
        .fadeOut(1000)
    })
  }

  // code collapsing
  var enableCollapse = function () {
    this.realHeight = $(this).height()
    if (this.realHeight < 300) return

    this.collapsed = true
    $(this).addClass('collapsed')

    var divWrapper = $('<div>').addClass('code-wrapper')
    var shadow = $('<div>').addClass('code-fade')
    var expandButton = $('<button>').html('ausrollen')
    $(this).after(divWrapper).appendTo(divWrapper)
    $(this).prepend(shadow)
    divWrapper.append(expandButton)

    var self = this

    expandButton.click(function() {
      if (self.collapsed) {
        $(self).removeClass('collapsed', 400)
        expandButton.html('einrollen')
      } else {
        $(self).addClass('collapsed', 400)
        expandButton.html('ausrollen')
        // scroll up
        var scrollDiff = $('article').scrollTop() + $(self).offset().top - 50
        $('article').animate({scrollTop: scrollDiff}, 400)
      }
      self.collapsed = !self.collapsed
    })
  }

  // code highlighting
  var enableHighlight = function () {
    hljs.highlightBlock($(this).children('code')[0])
  }

  // code imports
  if ($(codepre).attr('import') != 'true') {
    enableMousecopy.call(codepre)
    enableCollapse.call(codepre)
    enableHighlight.call(codepre)
  } else {
    var params = $(codepre).children('code').html().split(' ')
    $.get(params[0], function (data) {
      if (params[1] == 'nocomments') {
        // remove all comments and preceding linebreaks
        data = data.replace(/\n?\n[ \t]*\/\/.*/g, '')
      }
      $(codepre).children('code').html(data.replace(/</g, '&lt;'))
      enableMousecopy.call(codepre)
      enableCollapse.call(codepre)
      enableHighlight.call(codepre)
    })
  }
}
