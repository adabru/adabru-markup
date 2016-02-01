
adabruMarkup.setupFiletree = function(filetreediv) {
  var basepath = $(filetreediv).attr('data-basepath')

  var prefix = basepath
  var addlinks = function (prefix) {
    var filename = $(this).find('.filename span').first().html()
    $(this).find('a').first().attr('href',prefix+filename)
    $(this).children('ul').children().each(function() {
      addlinks.call(this,prefix+filename+'/')
    })
  }
  $(filetreediv).children('ul').children().each(function() {
    addlinks.call(this,basepath)
  })
}
