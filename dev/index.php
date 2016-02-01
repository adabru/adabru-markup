<?php
if(!$_SERVER["QUERY_STRING"]) {
  header('Location: ./?test.md');
  die();
}
?>

<meta charset="utf-8">

<!-- css reset -->
<link rel="stylesheet" href="./bower_components/cssreset/reset.css">

<!-- jQuery -->
<script src="./bower_components/jquery/dist/jquery.min.js"></script>
<!-- jquery-mousewheel -->
<script src="./bower_components/jquery-mousewheel/jquery.mousewheel.min.js"></script>
<!-- jquery-ui -->
<script src="./bower_components/jquery-ui/jquery-ui.min.js"></script>

<!-- knockout -->
<script src="./bower_components/knockout/dist/knockout.js"></script>

<!-- markdown -->
<!-- <script src="./bower_components/markdown/lib/markdown.js"></script> -->

<!-- waxeye -->
<script src="./bower_components/waxeye/src/javascript/waxeye.js"></script>

<!-- highlight.js -->
<script src="./bower_components/highlightjs/highlight.pack.min.js"></script>
<link rel="stylesheet" href="./bower_components/highlightjs/styles/xcode.css">

<!-- custom -->
<link rel="stylesheet" href="./bower_components/adabru-markup/css/core.css">
<link rel="stylesheet" href="./bower_components/adabru-markup/css/slides.css">
<link rel="stylesheet" href="./bower_components/adabru-markup/css/toc.css">
<link rel="stylesheet" href="./bower_components/adabru-markup/css/code.css">
<link rel="stylesheet" href="./bower_components/adabru-markup/css/span.css">
<link rel="stylesheet" href="./bower_components/adabru-markup/css/block.css">

<script src="./bower_components/adabru-markup/js/build/parser.js"></script>
<script src="./bower_components/adabru-markup/js/core.js"></script>
<script src="./bower_components/adabru-markup/js/slides.js"></script>
<script src="./bower_components/adabru-markup/js/toc.js"></script>
<script src="./bower_components/adabru-markup/js/code.js"></script>
<script src="./bower_components/adabru-markup/js/filetree.js"></script>

<body>
</body>

<script>
  var mdfile = <?php
  $file_path = urldecode( './markup/'.$_SERVER["QUERY_STRING"] );

  $md_file = file_get_contents( $file_path );
  // glob("*.md")[0]
  echo json_encode($md_file);
  ?>

  var start = new Date()
  var parsed = adabruMarkup.parseAndPrint(mdfile)
  var end = new Date()
  console.log('markup parsetime: ', end-start)
  start = new Date()
  $('body').html( parsed )
  end = new Date()
  console.log('dom parsetime + script execution: ', end-start)
  // $('#big').html( markdown.toHTML(mdfile) )
</script>
