'use strict';

const fs = require('fs');
const path = require('path');
const P = require('bluebird');
const {exec} = require('child_process');

const GIT_WALKER = path.join(__dirname, '..', '..', 'utils', 'git_walker.rb');

if (!fs.existsSync(GIT_WALKER)) {
  throw new Error(`Cannot locate git_walker.rb at ${GIT_WALKER}`);
}

const gitWalker = (repoPath, metric) => {
  return P.promisify(exec)(`${GIT_WALKER} ${repoPath} ${metric}`).then((stdout) => {
    return JSON.parse(stdout);
  });
};

module.exports = {gitWalker};
