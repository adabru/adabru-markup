
// js

window.$ = require('jquery')
require('jquery-mousewheel')(window.$)
require('jquery-ui/effect-scale')

window.ko = require('knockout')
window.waxeye = require('waxeye')
window.hljs = require('highlightjs/highlight.pack') // 400KB!

// css

require('insert-css')( require('fs').readFileSync(
  './node_modules/highlightjs/styles/xcode.css'
))
