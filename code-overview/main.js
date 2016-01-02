'use strict';

if (process.argv.length !== 3) {
  console.error('Requires path to repo');
  process.exit(255);
}

const fs = require('fs');
const execSync = require('child_process').execSync;
const electron = require('electron');
const app = electron.app;
const BrowserWindow = electron.BrowserWindow;

const GIT_WALKER = "../utils/git_walker.rb";

const loadFrame = (repoPath) => {
  let stdout = execSync(`${GIT_WALKER} lines-of-code ${repoPath}`).toString();
  return JSON.parse(stdout);
};

global.frame = loadFrame(process.argv[2]);

let mainWindow;

app.on('window-all-closed', () => app.quit());

app.on('ready', () => {
  mainWindow = new BrowserWindow({width: 800, height: 600});
  mainWindow.loadURL('file://' + __dirname + '/index.html');
  mainWindow.on('closed', () => mainWindow = null);
});
