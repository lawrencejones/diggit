'use strict';

if (process.argv.length !== 3) {
  console.error('Requires path to repo');
  process.exit(255);
}

const fs = require('fs');
const path = require('path');
const execSync = require('child_process').execSync;
const electron = require('electron');
const app = electron.app;
const BrowserWindow = electron.BrowserWindow;
const _ = require('lodash');

const CLIENT_DIR = path.join(__dirname, 'client');
const GIT_WALKER = "../utils/git_walker.rb";

const loadFrame = (repoPath) => {
  let stdout = execSync(`${GIT_WALKER} lines-of-code ${repoPath}`).toString();
  return JSON.parse(stdout);
};

global.frame = loadFrame(process.argv[2]);

const reloadMainWindow = _.debounce(() => {
  console.info('Reloading mainWindow...');
  mainWindow.reload();
}, 10);

let mainWindow;

app.on('window-all-closed', () => app.quit());

app.on('ready', () => {
  mainWindow = new BrowserWindow({width: 1400, height: 600});
  mainWindow.loadURL(`file://${CLIENT_DIR}/index.html`);
  mainWindow.on('closed', () => mainWindow = null);
});

if (process.env['WATCH']) {
  require('watch').watchTree(CLIENT_DIR, (f, curr, prev) => {
    if (typeof f === 'object' && curr === null && prev === null) {
      console.info(`Watching ${CLIENT_DIR} for file changes`);
    } else {
      console.info(`Change! [${f}]`);
      reloadMainWindow();
    }
  });
}
