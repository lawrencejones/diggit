'use strict';

const path = require('path');
const {execSync} = require('child_process');

const loadRepoSummary = (repoPathRelative) => {
  let repoPath = path.resolve(repoPathRelative);

  return {
    path: repoPath,
    totalSize: execSync('du -s -k -I .git', { cwd: repoPath }).toString().replace(/[\s.]/g, ''),
    noOfFiles: execSync(`find "${repoPath}" -type f | wc -l`).toString().replace(/\s/g, ''),
    sha: execSync(`GIT_DIR="${repoPath}/.git" git rev-parse master`).toString().replace(/\s/g, ''),
  };
};

module.exports = {loadRepoSummary};
