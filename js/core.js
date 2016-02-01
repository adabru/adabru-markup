// adabru-markup depends on following external sources:
//
// jQuery, knockout, adabru-slides

var adabruMarkup = {}

var Parser = Parser;
if (typeof module !== 'undefined') {
    // require from module system
    Parser = require('./build/parser').Parser
	module.exports = adabruMarkup
}

adabruMarkup.parser = new Parser()

adabruMarkup.parseAndPrint = function (document) {
var start = (new Date()).getTime()
	var ast = adabruMarkup.parseDocument(document)
	var printed = adabruMarkup.printHTML(ast)
	return printed
}

adabruMarkup.parseDocument = function (document, startNT) {
	// Parse the input (multi-pass)
  var parser = adabruMarkup.parser
  if(startNT == null) { startNT = 'document' }
  if(typeof window != 'undefined')  window.parser = parser

  var _parseDocument = function (startNT, document) {
    parser.start = parser.automata.findIndex( a => a.type==startNT)
    var ast = parser.parse(document)

    adabruMarkup.visit(ast,
      a => a.children != null && a.children.find(n => n.type=='nextpass') != null,
      a => {
        var toparse = a.children.reduce((ball,x) => ball+x.children[0], '')
        a.children = _parseDocument( a.type+'_Nextpass', toparse ).children
      }
    )

    return ast
  }

  return _parseDocument(startNT, document)
}

adabruMarkup.visit = function (ast, filter, action) {
  if (filter(ast)) { action(ast) }
  if (ast.children) { ast.children.forEach(child => {adabruMarkup.visit(child, filter, action)}) }
}

adabruMarkup.printHTML = function (document_ast) {
	// Print to HTML, see http://waxeye.org/manual.html#_calculator_in_javascript or https://github.com/jgm/peg-markdown/blob/master/markdown_output.c
	var sOut = ''

	var printChildren = function(ast, sep) { if (! sep) {sep=''} return ast.children.map(function(x){return printHTML(x)}).join(sep) }
	var printChild = function(ast, type, remove) {
    var index = ast.children.findIndex( x => x.type==type )
    if (index < 0) return ''
    var item = ast.children[index]
    if (remove) { ast.children.splice(index, 1) }
    return printHTML(item)
  }
	var printHTML = function(ast) {
		switch(ast.type) {
			case 'document': return printChildren(ast, '\n')

      case 'tableofcontents': return '<nav></nav>'
      case 'paperroll': return '<article>' + printChildren(ast, '\n') + '</article>'

      // block

			case 'slides': return '<div class="slidewrap" id="' + printChild(ast, 'slides_Id', true) + '"><div>' + printChildren(ast, '\n') + '</div></div>'
      case 'slides_Id': return printChildren(ast)
			case 'slides_Multislide': return '<section class="multislide">' + printChildren(ast, '\n') + '</section>'
			case 'slides_Item': return '<section>' + printChildren(ast, '\n') + '</section>'

			case 'header_L1': return '<h1>' + printChildren(ast) + '</h1>'
			case 'header_L2': return '<h2>' + printChildren(ast) + '</h2>'
			case 'header_L3': return '<h3>' + printChildren(ast) + '</h3>'
      case 'codeblock':
        var language = printChild(ast, 'codelanguage', true)
        ast.children[0].language = language
        return printChildren(ast)
      case 'codeimport': return '<pre import="true"><code class="' + ast.language + '">' + printChildren(ast, ' ') + '</code></pre>'
      case 'codeimport_Option': return printChildren(ast)
			case 'codeinline': return '<pre><code class="' + ast.language + '">' + printChildren(ast) + '</code></pre>'
			case 'codelanguage': return printChildren(ast)
			case 'linknote': return ''

      case 'filetree': return '<div class="filetree" data-basepath="' + printChild(ast,'filetree_Basepath') + '">' + printChild(ast,'filetree_Root') + '</div>'
      case 'filetree_Basepath': return printChildren(ast)
      case 'filetree_Root': return '<ul>' + printChildren(ast, '\n') + '</ul>'
      case 'filetree_Item': return '<li><div>' + printChild(ast,'filetree_Item_File') + printChild(ast,'filetree_Item_Description') + '</div>' + printChild(ast,'filetree_Item_Children') + '</li>'
      case 'filetree_Item_File': return '<a class="filename"><span>' + printChildren(ast) + '</span></a>'
      case 'filetree_Item_Description': return '<span class="filedescription">' + printChildren(ast) + '</span>'
      case 'filetree_Item_Children': return '<ul>' + printChildren(ast, '\n') + '</ul>'

      case 'list_Ordered': return '<ol>' + printChildren(ast, '\n') + '</ol>'
			case 'list_Unordered': return '<ul>' + printChildren(ast, '\n') + '</ul>'
			case 'list_Item': return '<li>' + printChildren(ast) + '</li>'
      case 'list_Item_Paragraph': return '<p>' + printChildren(ast) + '</p>'

      case 'table': return '<table>' + printChildren(ast) + '</table>'
      case 'table_Header': return '<tr>' + printChildren(ast) + '</tr>'
      case 'table_Header_Item': return '<th>' + printChildren(ast) + '</th>'
      case 'table_Body': return printChildren(ast)
      case 'table_Body_Row': return '<tr>' + printChildren(ast) + '</tr>'
      case 'table_Body_Row_Item': return '<td>' + printChildren(ast) + '</td>'

      case 'info': return '<div class="info">' + printChildren(ast) + '</div>'
      case 'warning': return '<div class="warning">' + printChildren(ast) + '</div>'

      case 'paragraph': return '<p>' + printChildren(ast) + '</p>'
      case 'newline': return '<br/>'

      // span
      case 'hover': return '<span class="hover_span"><img src="' + printChild(ast, 'link_Url', true) + '"/><span>' + printChildren(ast) + '</span></span>'
      case 'hover_Content': return printChildren(ast)
			case 'link_Inline': return '<a href="' + printChild(ast, 'link_Url') + '">' + printChild(ast, 'link_Text') + '</a>'
			case 'link_Reference': text=printChild(ast, 'link_Text'); return '<a href="' + store.link_reference[text] + '">' + text + '</a>'
			case 'link_Auto': var url=printChildren(ast); return '<a href="'+url+'">'+url+'</a>'
			case 'link_Url': return printChildren(ast)
			case 'link_Text': return printChildren(ast)
			case 'emphasis_Italic': return '<em>' + printChildren(ast) + '</em>'
			case 'emphasis_Bold': return '<strong>' + printChildren(ast) + '</strong>'
			case 'image': return '<img src="' + printChild(ast, 'image_Url') + '" alt="' + printChild(ast, 'image_Alt') + '">'
			case 'image_Url': return printChildren(ast)
			case 'image_Alt': return printChildren(ast)
      case 'apielement': return '<span class="apielement">' + printChildren(ast) + '</span>'
      case 'keystroke': return '<span class="keystroke">' + printChildren(ast) + '</span>'
      case 'key': return '<kbd>' + printChildren(ast) + '</kbd>'
      case 'brand': return '<span class="brand">' + printChildren(ast) + '</span>'
      case 'path': return '<span class="path">' + printChildren(ast) + '</span>'
      case 'code': return '<code>' + printChildren(ast) + '</code>'
      case 'iframe': return '<iframe src="' + printChildren(ast) + '"></iframe>'
			case undefined: return (ast == '<') ? '&lt;' : ast
			default: return ast.type
		}
	}

  // retrieve information and decorate tree
  var store = {}

	// storing the link-references
	store.link_reference = {}
	adabruMarkup.visit(document_ast
		,ast => ast.type == 'linknote'
		,ast => { store.link_reference[printChild(ast, 'link_Text')] = printChild(ast, 'link_Url') }
	)

  adabruMarkup.enrichHTML = function() {
    var taskmanager = {
        tasks: [],

        addTask: function(f, args) {
          if (args != null) {
            taskmanager.tasks.push( function() {return f(args)} )
          } else {
            taskmanager.tasks.push(f)
          }
        },

        execute: function () {
          if (taskmanager.tasks.length > 0) {
            var t = taskmanager.tasks.shift()
            setTimeout(function(){
              t()
              taskmanager.execute()
            })
          }
        }
    }
    window.taskmanager = taskmanager

    taskmanager.addTask( adabruMarkup.setupToc )

    $('div.slidewrap').each(function() {
      taskmanager.addTask( adabruMarkup.setupSlides, this )
    })

    $('pre').each(function() {
      taskmanager.addTask( adabruMarkup.setupCode, this )
    })

    $('div.filetree').each(function() {
      taskmanager.addTask( adabruMarkup.setupFiletree, this )
    })

    // global scrolling
    $(window).mousewheel(function(e) {
      var art = $('article')
      art.scrollTop(art.scrollTop() - e.deltaY*e.deltaFactor)
      e.preventDefault()
    })

    // resize iframes
    $('iframe').load(function () {
      $(this).height($(this).contents().find('body').height());
      $(this).width($(this).contents().find('body').width());
    })

    taskmanager.execute()
  }

	return printHTML(document_ast) + '<script>adabruMarkup.enrichHTML()</script>'
}
