
ko.observable.fn.inc = function() {this(this()+1)}
ko.observable.fn.dec = function() {this(this()-1)}

adabruMarkup.setupSlides = function (slidediv) {
  var obj = {}

  obj.wrapper = slidediv

  obj.slideplane = obj.wrapper.children[0]
  $(obj.slideplane).addClass('slideplane')

  obj.slides = []
  for (var i=0 ; i<obj.slideplane.children.length ; i++) {
    var hor = obj.slideplane.children[i]
    var vert = $(hor).children('section')
    if (vert.length == 0) {
      obj.slides.push([hor])
    } else {
      obj.slides.push(vert.toArray())
    }
  }

  obj.slides.slidewidth = $(obj.slides[0][0]).width() + parseInt($(obj.slides[0][0]).css('margin-right'))
  obj.slides.slideheight = $(obj.slides[0][0]).height() + parseInt($(obj.slides[0][0]).css('margin-bottom'))

  obj.totalcount = obj.slides.reduce((a,x) => a+x.length, 0)

  obj.cursor = {
    x: ko.observable(0),
    y: ko.observable(0)
  }

  // transitions
  obj.right = function () {if (obj.cursor.x() < obj.slides.length - 1) {obj.cursor.x.inc();obj.cursor.y(0)}}
  obj.left = function () {if (obj.cursor.x() > 0) {obj.cursor.x.dec();obj.cursor.y(0)}}
  obj.down = function () {if (obj.cursor.y() < obj.slides[obj.cursor.x()].length - 1) obj.cursor.y.inc()}
  obj.up = function () {if (obj.cursor.y() > 0) obj.cursor.y.dec()}

  // animation on change
  obj.update = function () {
    $(obj.slideplane).css('transform', 'translate(-'+obj.cursor.x()*obj.slides.slidewidth+'px,-'+obj.cursor.y()*obj.slides.slideheight+'px)')
  }
  obj.cursor.x.subscribe(obj.update)
  obj.cursor.y.subscribe(obj.update)

  // key-listener
  obj.keylistener = function(e) {
    switch (e.keyCode) {
      case 37: obj.left(); break
      case 38: obj.up(); break
      case 39: obj.right(); break
      case 40: obj.down(); break
      default:
    }
    if(37<=e.keyCode && e.keyCode<=40) {
      e.preventDefault()
    }
  }
  $(obj.wrapper).keydown(function(e) {obj.keylistener(e)})
    .prop('tabindex',0)


  // add progress-numbers
  var prog_div = $('<div>').addClass('progress-div')
  var curr_slide = $('<span>').addClass('progress-current').html(obj.cursor.x()+1)
  obj.cursor.x.subscribe( function(newVal) {curr_slide.html(newVal+1)} )
  var total_slide = $('<span>').addClass('progress-total').html('/'+obj.slides.length)
  prog_div.append(curr_slide).append(total_slide)
  $(obj.wrapper).append(prog_div)

  // add navigation-arrows
  var nav_div = $('<div>').addClass('navigation-div')
  nav_div.append($('<button>').addClass('navigation-arrow navigation-up').click(obj.up))
  nav_div.append($('<button>').addClass('navigation-arrow navigation-down').click(obj.down))
  nav_div.append($('<button>').addClass('navigation-arrow navigation-left').click(obj.left))
  nav_div.append($('<button>').addClass('navigation-arrow navigation-right').click(obj.right))
  var update_nav = function () {
    if (obj.cursor.x() == 0) {
      nav_div.children('.navigation-left').addClass('disabled').removeClass('enabled')
    } else {
      nav_div.children('.navigation-left').removeClass('disabled').addClass('enabled')
    }
    if (obj.cursor.x() == obj.slides.length-1) {
      nav_div.children('.navigation-right').addClass('disabled').removeClass('enabled')
    } else {
      nav_div.children('.navigation-right').removeClass('disabled').addClass('enabled')
    }
    if (obj.cursor.y() == 0) {
      nav_div.children('.navigation-up').addClass('disabled').removeClass('enabled')
    } else {
      nav_div.children('.navigation-up').removeClass('disabled').addClass('enabled')
    }
    if (obj.cursor.y() == obj.slides[obj.cursor.x()].length-1) {
      nav_div.children('.navigation-down').addClass('disabled').removeClass('enabled')
    } else {
      nav_div.children('.navigation-down').removeClass('disabled').addClass('enabled')
    }
  }
  obj.cursor.x.subscribe(update_nav)
  obj.cursor.y.subscribe(update_nav)
  update_nav();
  $(obj.wrapper).append(nav_div)

  return obj
}
