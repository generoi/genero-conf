'use strict';

var gulp = require('gulp')
  , path = require('path')
  , fs = require('fs')
  , del = require('del')
  , util = require('gulp-util')
  , jshint = require('gulp-jshint')
  , cache = require('gulp-cached')
  , changed = require('gulp-changed')
  , sass = require('gulp-sass')
  , phplint = require('phplint').lint
  , autoprefixer = require('gulp-autoprefixer')
  , livereload = require('gulp-livereload')
  , sourcemaps = require('gulp-sourcemaps')
  , minifyCSS = require('gulp-minify-css')
  , gulpif = require('gulp-if')
  , notify = require('gulp-notify')
  , imagemin = require('gulp-imagemin')
  , through = require('gulp-through')
  , rsync = require('gulp-rsync');

var config = {
    cssDir: 'css'
  , themeDir: 'sites/all/themes/<THEME>'
  , modulesDir: 'sites/all/modules/custom'
  , production: !!util.env.production
  , sourceMaps: !util.env.production
  , browserSupport: ['last 2 versions', 'ie 8', 'ie 9']
  , errorString: 'Error: [<%= error.line %>:<%= error.column %>] <%= error.message %>'
  , rsync: !util.env.production
  , rsyncOptions: {
      hostname: '<project>.dev'
    , username: 'vagrant'
    , shell: 'ssh -o PasswordAuthentication=no -i ' + process.env['HOME'] + '/.vagrant.d/insecure_private_key'
    , destination: '/var/www/drupal'
  }
};

var paths = {
    sass: [config.themeDir + '/scss/{,*/}*.scss']
  , cssDest: config.themeDir + '/css'
  , javascript: [
      config.themeDir + '/js/{,*/}*.js'
    , config.modulesDir + '/**/*.js'
    , '*.{js,json}'
    , '.jshintrc'
    , '!' + config.modulesDir + '/graphael_chart/js/g.pie.js'
  ]
  , images: [config.themeDir + '/images/{,*/}*.{png,jpg,jpeg}']
  , imagesDest: config.themeDir + '/images'
  , php: [
      config.themeDir + '/**/*.{php,module,inc,install,theme}'
    , config.modulesDir + '/**/*.{php,module,inc,install,theme}'
  ]
};

var gulpPhplint = through('phplint', function(file, config) {
  phplint(file.path, config, function (err, stdout, stderr) {
    if (err) {
      err.shortMessage = err.message.split('\n')[1];
      return this.emit('error', new util.PluginError('phplint', err));
    }
  }.bind(this));
}, { limit: 1 });

gulp.task('sass', function() {
  return gulp.src(paths.sass)
    .pipe(gulpif(config.sourceMaps, sourcemaps.init()))
    .pipe(sass().on('error', notify.onError(config.errorString)))
    .pipe(autoprefixer({
        browsers: config.browserSupport
      , cascade: false
    }))
    .pipe(gulpif(config.production, minifyCSS()))
    .pipe(gulpif(config.sourceMaps, sourcemaps.write()))
    .pipe(gulp.dest(paths.cssDest))
    .pipe(gulpif(config.rsync, rsync(config.rsyncOptions)))
    .on("error", notify.onError("Error: <%= error.message %>"));
});

gulp.task('reload-css', ['sass'], function() {
  livereload.changed(config.themeDir + '/css/v3.css');
});
gulp.task('reload-js', ['jshint'], function() {
  return gulp.src(paths.javascript)
    .pipe(livereload())
    .on("error", notify.onError("Error: <%= error.message %>"));
});

gulp.task('jshint', function() {
  return gulp.src(paths.javascript)
    .pipe(cache('linting'))
    .pipe(gulpif(config.rsync, rsync(config.rsyncOptions)))
    .pipe(jshint('.jshintrc'))
    .pipe(notify(function (file) {
      if (file.jshint.success) return false;
      var errors = file.jshint.results.map(function (data) {
        if (data.error) {
          return "[" + data.error.line + ':' + data.error.character + '] ' + data.error.reason;
        }
      }).join("\n");
      return file.relative + " (" + file.jshint.results.length + " errors)\n" + errors;
    }))
    .pipe(jshint.reporter('default'))
    .on("error", notify.onError("Error: <%= error.message %>"));
});

gulp.task('imagemin', function() {
  return gulp.src(paths.images)
    .pipe(imagemin({
        progressive: true
    }))
    .pipe(gulp.dest(paths.imagesDest))
    .pipe(livereload())
    .on("error", notify.onError("Error: <%= error.message %>"));
});

gulp.task('clean', function(cb) {
  del([paths.cssDest + '/*'], cb);
});

gulp.task('watch', function() {
  livereload.listen();
  gulp.watch(paths.sass, ['sass', 'reload-css']);
  gulp.watch(paths.javascript, ['jshint', 'reload-js']);
});

gulp.task('phplint', function(cb) {
  return gulp.src(paths.php)
    .pipe(cache('linting'))
    .pipe(gulpif(config.rsync, rsync(config.rsyncOptions)))
    .pipe(gulpPhplint())
    .on("error", notify.onError("Error: <%= error.shortMessage %>"));
});

gulp.task('build', ['sass']);
gulp.task('lint', ['jshint', 'phplint']);
