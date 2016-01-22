'use strict';

const _ = require('lodash');
const fs = require('fs');
const path = require('path');
const EventEmitter = require('events');
const {spawn} = require('child_process');

const REFACTOR_DILIGENCE = path.join(__dirname, '..', '..', 'utils', 'refactor_diligence.rb');

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

const refactorDiligence = (repoPath) => {
  let eventEmitter = new EventEmitter();
  let progress = { total: 0, count: -1 };  // start at -1 so count is 0 indexed

  let prog = spawn(REFACTOR_DILIGENCE, [
      'profile',
      '--stream-progress',
      '--output-json',
      repoPath,
  ]);

  /* Wait for progress output */
  prog.stderr.on('data', (data) => {
    if (progress.total === 0) {
      progress.total = parseNoOfCommits(data) || 0;
    }

    let commitSha = parseCommitSha(data)
    if (commitSha) {
      progress.count += 1;
      eventEmitter.emit('commit', _.extend({sha: commitSha}, progress));
    }
  });

  /* Wait for the json profile output */
  prog.stdout.on('data', (jsonString) => {
    let profile = JSON.parse(jsonString);
    eventEmitter.emit('done', profile);
  });

  return eventEmitter;
}

module.exports = {refactorDiligence, parseNoOfCommits, parseCommitSha};
