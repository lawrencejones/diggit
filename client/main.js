'use strict';

const _ = require('lodash');
const path = require('path');
const execSync = require('child_process').execSync;
const electron = require('electron');
const BrowserWindow = electron.BrowserWindow;
const app = electron.app;

if (process.argv.length !== 3) {
  console.error('Requires path to repo');
  process.exit(255);
}

/* Expose this argument as a global variable. Required so that the client app can easily
 * retrive the electron command argument */
global.REPO_PATH = path.resolve(process.argv[2]);

let mainWindow;

/* Enable super-exciting harmony features */
app.commandLine.appendSwitch('js-flags', '--harmony_destructuring --harmony_spread_arrays');

app.on('window-all-closed', () => app.quit());

app.on('ready', () => {
  mainWindow = new BrowserWindow({width: 1400, height: 680});
  mainWindow.loadURL(`file://${__dirname}/index.html`);
  mainWindow.on('closed', () => mainWindow = null);
});

/* Watching logic to reload on changes */

const reloadMainWindow = _.debounce(() => {
  console.info('Reloading mainWindow...');
  mainWindow.reload();
}, 10);

if (process.env.WATCH) {
  require('watch').watchTree(__dirname, (f, curr, prev) => {
    if (typeof f === 'object' && curr === null && prev === null) {
      console.info(`Watching ${__dirname} for file changes`);
    } else {
      if (!/\.(js|css|html|json)$/.test(f)) { return; }
      console.info(`Change! [${f}]`);
      reloadMainWindow();
    }
  });
}
