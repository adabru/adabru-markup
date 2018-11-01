var webpack = require('webpack')

module.exports = {
  mode: 'development',
  target: 'web',
  entry: './html/js/frontend.ls',
  node: {
    util: "empty",
    fs: "empty",
    path: "empty"
  },
  output: {
    path: `${__dirname}/js/build`,
    filename: 'adabrumarkup.js',
    library: 'adabruMarkup',
    libraryTarget: 'var'
  },
  module: {
    rules: [
      {test: /\.css$/,  loader: "style-loader!css-loader"},
      {test: /\.ls$/,   loader: "livescript-loader"},
      {test: /\.styl$/, loader: "style-loader!css-loader!stylus-loader"}
    ]
  },
  externals: [
    'ease'
  ]
}
