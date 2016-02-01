adabruMarkup.setupToc = function () {

  // create from headers
  var headers = $('h2,h3').not('.slidewrap *').toArray()
  var level = 1
  var newLevel
  var html = ''
  for (h of headers) {
    nextLevel = h.tagName[1]
    var newId = (''+Math.random()).substr(2)
    while (level != nextLevel) {
      if (level < nextLevel) {
        html += '<ul>'
        level++
      } else {
        html += '</ul>'
        level--
      }
    }
    h.id = escape(h.innerHTML).replace(/%/g,'_')
    html += '<li><a href="#' + h.id + '">' + h.innerHTML + '</a></li>'
  }
  $('nav').html(html)
  var tocItems = $('nav li')

  // animated scroll on click
  $('nav a').click(function(e) {
    e.preventDefault()
  })
  $('nav li').click(function(e) {
    var target = $($(this).find('a').attr('href'))
    var scrollDiff = $('article').scrollTop() + target.offset().top + parseInt(target.css('margin-top')) + parseInt(target.css('border-top-width')) + parseInt(target.css('padding-top')) - 50
    $('article').animate({scrollTop: scrollDiff}, 500); //scroll smoothly to #id
  })

  // enable current progress
  var currentTocItem = tocItems.first()
  currentTocItem.addClass('highlight')
  $('article').scroll(function () {
    var currentHeader = headers.reduce( function (acc, x) {
      if ($(x).offset().top < 0 && $(x).offset().top > $(acc).offset().top) {
        return x
      } else {
        return acc
      }
    }, headers[0])
    var tocItem = tocItems.filter((i,e) => e.children[0].href.split('#')[1] == currentHeader.id).first()
    if (tocItem != currentTocItem) {
      currentTocItem.removeClass('highlight')
      currentTocItem = tocItem
      currentTocItem.addClass('highlight')
    }
  })
}
