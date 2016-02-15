'use strict';

const fs = require('fs');
const path = require('path');
const P = require('bluebird');
const {spawn} = require('child_process');

const GIT_WALKER = path.join(__dirname, '../../..', 'utils', 'git_walker.rb');

if (!fs.existsSync(GIT_WALKER)) {
  throw new Error(`Cannot locate git_walker.rb at ${GIT_WALKER}`);
}

const collectStdio = (prog) => {
  let io = { stdout: '', stderr: '' };

  prog.stdout.setEncoding('utf8')
  prog.stderr.setEncoding('utf8')

  prog.stdout.on('data', (data) => { io.stdout += data });
  prog.stderr.on('data', (data) => { io.stderr += data });

  return io;
}

const gitWalker = (repoPath, metric, pattern) => {
  return new P((resolve, reject) => {
    let prog = spawn(GIT_WALKER, [
      'walk', repoPath,
      '--metric', metric,
      '--pattern', pattern || '**/*',
    ]);

    let io = collectStdio(prog);

    prog.on('close', (code) => {
      code === 0 ?  resolve(JSON.parse(io.stdout)) : reject(io.stderr);
    });
  });
};

module.exports = {gitWalker};
