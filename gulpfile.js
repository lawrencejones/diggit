'use strict';

const path        = require('path');

const gulp        = require('gulp');
const taskMaker   = require('gulp-helpers').taskMaker(gulp);
const runSequence = require('gulp-helpers').framework('run-sequence');
const KarmaServer = require('karma').Server;
const jshint      = require('gulp-jshint');
const stylish     = require('jshint-stylish');

const config = {
  output: 'web/dist/',                                 // output directory for compiled assets
  jsSource: ['web/client/**/*.js'],                    // client javascript
  json: 'web/client/**/*.json',                        // client json
  pegjs: 'web/client/**/*.pegjs',                      // client pegjs
  html: 'web/client/**/*.html',                        // client html
  jspm: 'web/jspm_packages',                           // location of jspm packages
  assets: ['web/client/assets/**'],                    // media assets for client
  watch: 'web/client/**',                              // watch pattern that triggers server reload
  karmaConfig: 'web/karma.conf.js',                    // karma test runner configuration file
  systemConfig: 'web/system.config.js',                // SystemJS configuration file
};

taskMaker.defineTask('babel', {
  taskName: 'babel',
  src: config.jsSource,
  dest: config.output,
  ngAnnotate: true,
  compilerOptions: {modules: 'system'},
});

taskMaker.defineTask('copy', {taskName: 'systemConfig', src: config.systemConfig, dest: config.output});
taskMaker.defineTask('copy', {taskName: 'assets', src: config.assets, dest: path.join(config.output, 'assets')});
taskMaker.defineTask('copy', {taskName: 'json', src: config.json, dest: config.output});
taskMaker.defineTask('copy', {taskName: 'html', src: config.html, dest: config.output});
taskMaker.defineTask('copy', {taskName: 'pegjs', src: config.pegjs, dest: config.output});

taskMaker.defineTask('watch', {taskName: 'watch', src: config.watch, tasks: ['compile']});
taskMaker.defineTask('clean', {taskName: 'clean', src: config.output});

taskMaker.defineTask('browserSync', {
  taskName: 'serve',
  historyApiFallback: true,
  config: {
    open: false,
    port: process.env.PORT || 4567,
    server: {
      baseDir: [config.output],
      routes: {
        '/system.config.js': config.systemConfig,
        '/jspm_packages': config.jspm,
      },
    },
  },
});

gulp.task('karma', ['recompile'], (cb) => {
  new KarmaServer({
    configFile: path.join(__dirname, config.karmaConfig),
    singleRun: true,
  }, cb).start()
});

gulp.task('compile', ['babel', 'systemConfig', 'assets', 'json', 'html', 'pegjs']);
gulp.task('recompile', (cb) => { runSequence('clean', 'compile', cb) });
gulp.task('lint', () => {
  return gulp.src(config.jsSource)
    .pipe(jshint())
    .pipe(jshint.reporter(stylish));
});

gulp.task('run', ['recompile', 'serve', 'watch']);

gulp.task('default', ['run']);
