
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
  if(startNT == null) { startNT = 'Document' }

  var _parseDocument = function (startNT, document) {
    parser.start = startNT
    var ast = parser.parse(document)

    adabruMarkup.visit(ast,
      a => a.children != null && a.children.find(n => n.type=='Nextpass') != null,
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
			case 'Document': return printChildren(ast, '\n')

      case 'Tableofcontents': return '<nav></nav>'
      case 'Paperroll': return '<article>' + printChildren(ast, '\n') + '</article>'

      // block

			case 'Slides': return '<div class="slidewrap" id="' + printChild(ast, 'Slides_Id', true) + '"><div>' + printChildren(ast, '\n') + '</div></div>'
      case 'Slides_Id': return printChildren(ast)
			case 'Slides_Multislide': return '<section class="multislide">' + printChildren(ast, '\n') + '</section>'
			case 'Slides_Item': return '<section>' + printChildren(ast, '\n') + '</section>'

			case 'Header_L1':
        var content = printChildren(ast)
        var id = escape(content.replace(/<[^>]*>([^<]*)<[^>]*>/g, '$1')).replace(/%/g,'_')
        return '<h1 id="' + id + '">' + content + '</h1>'
			case 'Header_L2':
        var content = printChildren(ast)
        var id = escape(content.replace(/<[^>]*>([^<]*)<[^>]*>/g, '$1')).replace(/%/g,'_')
        return '<h2 id="' + id + '">' + content + '</h2>'
			case 'Header_L3':
        var content = printChildren(ast)
        var id = escape(content.replace(/<[^>]*>([^<]*)<[^>]*>/g, '$1')).replace(/%/g,'_')
        return '<h3 id="' + id + '">' + content + '</h3>'
      case 'Codeblock':
        var language = printChild(ast, 'Codelanguage', true)
        ast.children[0].language = language
        return printChildren(ast)
      case 'Codeimport': return '<pre import="true"><code class="' + ast.language + '">' + printChildren(ast, ' ') + '</code></pre>'
      case 'Codeimport_Option': return printChildren(ast)
			case 'Codeinline': return '<pre><code class="' + ast.language + '">' + printChildren(ast) + '</code></pre>'
			case 'Codelanguage': return printChildren(ast)
			case 'Linknote': return ''

      case 'Filetree': return '<div class="filetree" data-basepath="' + printChild(ast,'Filetree_Basepath') + '">' + printChild(ast,'Filetree_Root') + '</div>'
      case 'Filetree_Basepath': return printChildren(ast)
      case 'Filetree_Root': return '<ul>' + printChildren(ast, '\n') + '</ul>'
      case 'Filetree_Item': return '<li><div>' + printChild(ast,'Filetree_Item_File') + printChild(ast,'Filetree_Item_Description') + '</div>' + printChild(ast,'Filetree_Item_Children') + '</li>'
      case 'Filetree_Item_File': return '<a class="filename"><span>' + printChildren(ast) + '</span></a>'
      case 'Filetree_Item_Description': return '<span class="filedescription">' + printChildren(ast) + '</span>'
      case 'Filetree_Item_Children': return '<ul>' + printChildren(ast, '\n') + '</ul>'

      case 'List_Ordered': return '<ol>' + printChildren(ast, '\n') + '</ol>'
			case 'List_Unordered': return '<ul>' + printChildren(ast, '\n') + '</ul>'
			case 'List_Item': return '<li>' + printChildren(ast) + '</li>'
      case 'List_Item_Paragraph': return '<p>' + printChildren(ast) + '</p>'

      case 'Table': return '<table>' + printChildren(ast) + '</table>'
      case 'Table_Header': return '<tr>' + printChildren(ast) + '</tr>'
      case 'Table_Header_Item': return '<th>' + printChildren(ast) + '</th>'
      case 'Table_Body': return printChildren(ast)
      case 'Table_Body_Row': return '<tr>' + printChildren(ast) + '</tr>'
      case 'Table_Body_Row_Item': return '<td>' + printChildren(ast) + '</td>'

      case 'Info': return '<div class="info">' + printChildren(ast) + '</div>'
      case 'Warning': return '<div class="warning">' + printChildren(ast) + '</div>'

      case 'Paragraph': return '<p>' + printChildren(ast) + '</p>'
      case 'Newline': return '<br/>'

      // span
      case 'Hover': return '<span class="hover_span"><img src="' + printChild(ast, 'Link_Url', true) + '"/><span>' + printChildren(ast) + '</span></span>'
      case 'Hover_Content': return printChildren(ast)
			case 'Link_Inline': return '<a href="' + printChild(ast, 'Link_Url') + '">' + printChild(ast, 'Link_Text') + '</a>'
			case 'Link_Reference': text=printChild(ast, 'Link_Text'); return '<a href="' + store.link_reference[text] + '">' + text + '</a>'
			case 'Link_Auto': var url=printChildren(ast); return '<a href="'+url+'">'+url+'</a>'
			case 'Link_Url': return printChildren(ast)
			case 'Link_Text': return printChildren(ast)
			case 'Emphasis_Italic': return '<em>' + printChildren(ast) + '</em>'
			case 'Emphasis_Bold': return '<strong>' + printChildren(ast) + '</strong>'
			case 'Image': return '<img src="' + printChild(ast, 'Image_Url') + '" alt="' + printChild(ast, 'Image_Alt') + '">'
			case 'Image_Url': return printChildren(ast)
			case 'Image_Alt': return printChildren(ast)
      case 'Apielement': return '<span class="apielement">' + printChildren(ast) + '</span>'
      case 'Keystroke': return '<span class="keystroke">' + printChildren(ast) + '</span>'
      case 'Key': return '<kbd>' + printChildren(ast) + '</kbd>'
      case 'Brand': return '<span class="brand">' + printChildren(ast) + '</span>'
      case 'Path': return '<span class="path">' + printChildren(ast) + '</span>'
      case 'Code': return '<code>' + printChildren(ast) + '</code>'
      case 'Iframe': return '<iframe src="' + printChildren(ast) + '"></iframe>'
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

    // scroll to header defined in location.hash
    var target = $(location.hash)
    if (target.length > 0) {
      var scrollDiff = $('article').scrollTop() + target.offset().top + parseInt(target.css('margin-top')) + parseInt(target.css('border-top-width')) + parseInt(target.css('padding-top')) - 50
      $('article').scrollTop(scrollDiff)
    }

    // resize iframes
    $('iframe').load(function () {
      $(this).height($(this).contents().find('body').height());
      $(this).width($(this).contents().find('body').width());
    })

    taskmanager.execute()
  }

	return printHTML(document_ast) + '<script>adabruMarkup.enrichHTML()</script>'
}
