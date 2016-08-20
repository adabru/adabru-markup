var webpack = require('webpack')

module.exports = {
  entry: ['./js/core.coffee'],
  module: {
    loaders: [
      {test: /\.coffee$/, loader: 'coffee'},
      {test: /\.css$/, loader: "style-loader!css-loader"}
    ]
  },
  output: {
    filename: './js/build/adabrumarkup.js',
    library: 'adabruMarkup'
  },
  externals: [
    'ease'
  ],
  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        BROWSER: JSON.stringify(true)
        //  NODE_ENV: JSON.stringify('production')
       }
    })
  ]
}
