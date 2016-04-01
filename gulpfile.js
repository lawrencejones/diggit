'use strict';

const path        = require('path');

const gulp        = require('gulp');
const gutil       = require('gulp-util');
const taskMaker   = require('gulp-helpers').taskMaker(gulp);
const runSequence = require('gulp-helpers').framework('run-sequence');
const jshint      = require('gulp-jshint');
const jade        = require('gulp-jade');
const ngAnnotate  = require('gulp-ng-annotate');
const uglify      = require('gulp-uglify');
const sourcemaps  = require('gulp-sourcemaps');
const sass        = require('gulp-sass');

const config = {
  web: 'web/',
  dist: 'web/dist/',
  client: 'web/client/',
  public: 'public/',
  bundle: {
    root: 'dist/app.js',
    output: 'public/build.js',
  },
};

const assets = {
  es6: 'web/client/**/*.js',
  jade: ['web/client/**/*.jade', '!web/client/index.jade'],
  scss: 'web/client/**/*.scss',
  index: 'web/client/index.jade',
};

// LINT AND TESTING //

gulp.task('lint', () => {
  return gulp.src(assets.es6)
    .pipe(jshint())
    .pipe(jshint.reporter(require('jshint-stylish')));
});

gulp.task('karma', ['recompile'], (cb) => {
  let KarmaServer = require('karma').Server;
  new KarmaServer({
    configFile: path.join(__dirname, 'web', 'karma.conf.js'),
    singleRun: true,
  }, cb).start()
});

// ASSET TRANSPILATION //

const transpileTask = (src, transpiler, dst) => {
  return (cb) => {
    return gulp.src(src)
      .pipe(transpiler()).on('error', cb)
      .pipe(gulp.dest(dst));
  }
}

gulp.task('assets', ['es6', 'jade', 'scss', 'static-assets', 'index.dev']);
gulp.task('recompile', (cb) => { runSequence('clean', 'assets', cb) });
taskMaker.defineTask('clean', {taskName: 'clean', src: [
  config.dist,
  path.join(config.public, 'index.html'),
  path.join(config.public, 'build.*'),
]});

taskMaker.defineTask('babel', {
  taskName: 'es6',
  src: assets.es6,
  dest: config.dist,
  ngAnnotate: true,
  compilerOptions: {modules: 'system'},
});

taskMaker.defineTask('copy', {
  taskName: 'static-assets',
  src: 'web/client/**/*.{json,html,pegjs}',
  dest: config.dist,
})

gulp.task('jade', transpileTask(assets.jade, jade, config.dist));
gulp.task('scss', transpileTask(assets.scss, sass, config.dist));

gulp.task('index.prod', transpileTask(assets.index, jade.bind(jade, {locals: {env: 'production'}}), config.public));
gulp.task('index.dev', transpileTask(assets.index, jade.bind(jade, {locals: {env: 'development'}}), config.dist));

// PRODUCTION BUNDLING //

gulp.task('bundle', ['compile', 'index.prod'], (cb) => {
  gutil.log('Creating production bundle...');
  require('jspm').bundleSFX(config.bundle.root, config.bundle.output, {
    sourceMaps: 'inline',
    minify: false,
  }).then(() => {
    return gulp.src(config.output)
      .pipe(sourcemaps.init({loadMaps: true}))
        .on('data', () => { gutil.log('Running ng-annotate...') })
        .pipe(ngAnnotate())
        .on('data', () => { gutil.log('Minifying bundle.js...') })
        .pipe(uglify())
      .on('data', () => { gutil.log('Finalising sourcemaps...') })
      .pipe(sourcemaps.write('.'))
      .pipe(gulp.dest(config.public))
      .on('end', () => { gutil.log('Done!') })
      .on('error', cb);
  }).catch(cb);
});

// DEVELOPMENT TASKS //

gulp.task('default', ['run']);
gulp.task('run', ['recompile', 'serve', 'watch']);
taskMaker.defineTask('watch', {taskName: 'watch', src: path.join(config.client, '**/*'), tasks: ['assets']});

taskMaker.defineTask('browserSync', {
  taskName: 'serve',
  historyApiFallback: true,
  config: {
    open: false,
    port: process.env.PORT || 4567,
    server: {
      baseDir: [config.dist, config.public],
      routes: {
        '/system.config.js': 'web/system.config.js',
        '/jspm_packages': 'web/jspm_packages',
      },
    },
  },
});
