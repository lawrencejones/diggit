'use strict';

const _ = require('lodash');
const P = require('bluebird');
const fs = require('fs');
const path = require('path');
const {spawn} = require('child_process');

const REFACTOR_DILIGENCE = path.join(__dirname, '../../../lib/utils/refactor_diligence.rb');

if (!fs.existsSync(REFACTOR_DILIGENCE)) {
  throw new Error(`Cannot locate refactor_diligence.rb at ${REFACTOR_DILIGENCE}`);
}

const parseNoOfCommits = (loggedNoOfCommits) => {
  let match = loggedNoOfCommits.toString().match(/RepoScanner: NO OF COMMITS (\d+)/);
  if (match && match[1]) {
    return parseInt(match[1]);
  }
}

const parseCommitSha = (loggedSha) => {
  return _.get(loggedSha.toString().match(/CommitScanner: SCAN (\S+)/), 1);
}

const streamProgress = (stream, notify) => {
  let progress = { total: 0, count: -1 };  // start at -1 so count is 0 indexed

  stream.on('data', (data) => {
    if (progress.total === 0) {
      progress.total = parseNoOfCommits(data) || 0;
    }

    let commitSha = parseCommitSha(data);
    if (commitSha) {
      progress.count += 1;
      notify(_.clone(progress));
    }
  });
}

const refactorDiligence = (repoPath, onProgress) => {
  let prog = spawn(REFACTOR_DILIGENCE, [
      'profile',
      '--stream-progress',
      '--output-json',
      repoPath,
  ]);

  if (_.isFunction(onProgress)) {
    streamProgress(prog.stderr, onProgress);
  }

  return new P((resolve, reject) => {
    let jsonString = '';
    prog.stdout.on('data', (jsonSegment) => { jsonString += jsonSegment });

    prog.on('exit', (exitStatus) => {
      if (exitStatus === 0) {
        resolve(JSON.parse(jsonString));
      } else {
        reject(new Error(`refactor_diligence.rb exited with [${exitStatus}]`));
      }
    });
  });
}

module.exports = {refactorDiligence, parseNoOfCommits, parseCommitSha};
