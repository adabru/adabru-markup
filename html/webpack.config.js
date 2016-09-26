var webpack = require('webpack')
var RawSource = require("webpack-sources").RawSource;
var jsmin = require('jsmin')

module.exports = {
  entry: ['./html/js/core.coffee'],
  module: {
    loaders: [
      {test: /\.coffee$/, loader: 'coffee'}
      ,{test: /\.json$/, loader: 'json'}
      ,{test: /\.css$/, loader: "style-loader!css-loader"}
      ,{test: /\.ls$/, loader: "livescript"}
    ]
  },
  output: {
    filename: './html/js/build/adabrumarkup.js',
    library: 'adabruMarkup',
    libraryTarget: 'commonjs2'
  },
  externals: [
    'ease'
  ],
  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        // BROWSER: JSON.stringify(true)
        // NODE_ENV: JSON.stringify('production')
       }
    })
    // jsmin is (regex) much faster than uglify (ast), but a little less effective
    // adds about 400ms for 2.3M → 1.3M compression
    ,function(compiler) {
      this.plugin('compilation', function(compilation){
        compilation.plugin("optimize-chunk-assets", function(chunks, callback) {
          var file = chunks[0].files[0]
          var asset = compilation.assets[file]
          compilation.assets[file] = new RawSource(jsmin.jsmin(asset.source()))
          callback()
      })})
    }
    // ,new webpack.optimize.UglifyJsPlugin({
    //     compress: {
    //         warnings: false
    //     }
    // })
  ]
}
