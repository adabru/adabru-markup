var gulp = require('gulp');

// alternative:
// https://truongtx.me/2015/11/03/using-gulp-with-browserify-and-watchify-update-nov-2015/
var watchify = require('gulp-watchify')
var uglify = require('gulp-uglify')
var streamify = require('gulp-streamify')
var rename = require('gulp-rename')


gulp.task('watch-deps', watchify(function(watchify) {
  return gulp.src('./js/dependencies.js')
    .pipe(watchify({
      watch:true,
      setup: function(bundle) {
          bundle.transform(require('brfs'))
        }
      }))
    .pipe(streamify(uglify()))
    .pipe(rename('dependency_bundle.js'))
    .pipe(gulp.dest('./js/build/'))
}))

require('gulp-release-tasks')(gulp)
