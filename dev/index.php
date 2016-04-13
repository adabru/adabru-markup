<?php
if(!$_SERVER["QUERY_STRING"]) {
  header('Location: ./?test.md');
  die();
}
?>

<meta charset="utf-8">

<!-- css reset -->
<link rel="stylesheet" href="./bower_components/cssreset/reset.css">

<script src="./bower_components/adabru-markup/js/build/adabrumarkup.js"></script>

<body>
  <div id='app'>
  </div>
</body>

<script>
  var mdfilepath = 'markup/<?php echo $_SERVER["QUERY_STRING"] ?>'

  fetch(mdfilepath, {method: 'get'}).then( r => r.text() ).then( data =>
    {
      var start = new Date()
      var parsed
      if (mdfilepath.endsWith('.json')) {
        parsed = JSON.parse(data)
      } else {
        parsed = adabruMarkup.parseDocument(data)
      }
      var end = new Date()
      console.log('markup parsetime: ', end-start)

      decorated = adabruMarkup.decorateTree(parsed)

      start = new Date()
      var printed = adabruMarkup.printDocument(decorated, document.querySelector('#app'))
      end = new Date()
      console.log('dom parsetime + script execution: ', end-start)
      // $('#big').html( markdown.toHTML(mdfile) )
    })

</script>
