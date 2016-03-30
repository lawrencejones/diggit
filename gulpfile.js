'use strict';

const path        = require('path');

const gulp        = require('gulp');
const taskMaker   = require('gulp-helpers').taskMaker(gulp);
const runSequence = require('gulp-helpers').framework('run-sequence');
const KarmaServer = require('karma').Server;
const jshint      = require('gulp-jshint');
const stylish     = require('jshint-stylish');
const jade        = require('gulp-jade');

const config = {
  output: 'web/dist/',                                 // output directory for compiled assets
  public: 'public/',                                   // public assets from sinatra app
  appRoot: 'client/app/app.js',                        // root for front-end app
  index: 'web/client/index.jade',                      // root index.html source
  jsSource: ['web/client/**/*.js'],                    // client javascript
  json: 'web/client/**/*.json',                        // client json
  pegjs: 'web/client/**/*.pegjs',                      // client pegjs
  html: 'web/client/**/*.html',                        // client html
  jspm: 'web/jspm_packages',                           // location of jspm packages
  watch: 'web/client/**',                              // watch pattern that triggers server reload
  karmaConfig: 'web/karma.conf.js',                    // karma test runner configuration file
  systemConfig: 'web/system.config.js',                // SystemJS configuration file
};

gulp.task('default', ['run']);
gulp.task('run', ['recompile', 'serve', 'watch']);

gulp.task('lint', () => {
  return gulp.src(config.jsSource)
    .pipe(jshint())
    .pipe(jshint.reporter(stylish));
});

gulp.task('karma', ['recompile'], (cb) => {
  new KarmaServer({
    configFile: path.join(__dirname, config.karmaConfig),
    singleRun: true,
  }, cb).start()
});

gulp.task('compile', ['babel', 'systemConfig', 'json', 'index.dev', 'html', 'pegjs']);
gulp.task('recompile', (cb) => { runSequence('clean', 'compile', cb) });

gulp.task('production', ['bundle', 'index.prod']);
gulp.task('bundle', (cb) => {
  require('jspm').bundleSFX(config.appRoot, path.join(config.public, 'build.js'), {
    sourceMaps: true,
    minify: false, // TODO - At the moment this breaks ng-annotate
  }).then(cb, cb);
});

/* Compile index.jade with different environments */
const indexTask = (locals, dest) => {
  return () => { gulp.src(config.index).pipe(jade({locals})).pipe(gulp.dest(dest)); }
}

gulp.task('index.prod', indexTask({env: 'production'}, config.public));
gulp.task('index.dev', indexTask({env: 'development'}, config.output));

taskMaker.defineTask('babel', {
  taskName: 'babel',
  src: config.jsSource,
  dest: config.output,
  ngAnnotate: true,
  compilerOptions: {modules: 'system'},
});

taskMaker.defineTask('copy', {taskName: 'systemConfig', src: config.systemConfig, dest: config.output});
taskMaker.defineTask('copy', {taskName: 'json', src: config.json, dest: config.output});
taskMaker.defineTask('copy', {taskName: 'html', src: config.html, dest: config.output});
taskMaker.defineTask('copy', {taskName: 'pegjs', src: config.pegjs, dest: config.output});

taskMaker.defineTask('watch', {taskName: 'watch', src: config.watch, tasks: ['compile']});
taskMaker.defineTask('clean', {taskName: 'clean', src: [
  config.output,
  path.join(config.public, 'index.html'),
  path.join(config.public, 'build.js*'),
]});

taskMaker.defineTask('browserSync', {
  taskName: 'serve',
  historyApiFallback: true,
  config: {
    open: false,
    port: process.env.PORT || 4567,
    server: {
      baseDir: [config.output, config.public],
      routes: {
        '/system.config.js': config.systemConfig,
        '/jspm_packages': config.jspm,
      },
    },
  },
});
