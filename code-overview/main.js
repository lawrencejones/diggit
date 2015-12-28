'use strict';

if (process.argv.length !== 3) {
  console.error('Requires path to data.json');
  process.exit(255);
}

const fs = require('fs');
const electron = require('electron');
const app = electron.app;
const BrowserWindow = electron.BrowserWindow;

const loadSnapshot = (dataFile) => {
  if (!fs.existsSync(dataFile)) {
    console.error(`Could not find file ${dataFile}`);
    process.exit(255);
  }

  return require(dataFile);
};

global.snapshot = loadSnapshot(process.argv[2]);

let mainWindow;

app.on('window-all-closed', () => app.quit());

app.on('ready', () => {
  mainWindow = new BrowserWindow({width: 800, height: 600});
  mainWindow.loadURL('file://' + __dirname + '/index.html');
  mainWindow.on('closed', () => mainWindow = null);
  mainWindow.hello = 'world';
});
