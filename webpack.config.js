var webpack = require('webpack')

module.exports = {
  entry: ['./html/js/core.coffee'],
  module: {
    loaders: [
      {test: /\.coffee$/, loader: 'coffee'},
      {test: /\.json$/, loader: 'json'},
      {test: /\.css$/, loader: "style-loader!css-loader"},
      {test: /\.ls$/, loader: "livescript"}
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
    // ,new webpack.optimize.UglifyJsPlugin({
    //     compress: {
    //         warnings: false
    //     }
    // })
  ]
}
