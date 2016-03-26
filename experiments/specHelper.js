'use strict';

const _ = require('lodash');
const chai = require('chai');
const path = require('path');
const P = require('bluebird');
const rmrf = P.promisify(require('rimraf'));
const {execSync} = require('child_process');

chai.use(require('sinon-chai'));

const temporaryRepos = [];
const makeTemporaryRepo = () => {
  let stdout = execSync(path.join(__dirname, '..', 'bin', 'mktmprepo'));
  let repoPath = stdout.toString().replace(/\s*$/, '');

  temporaryRepos.push(repoPath);
  return repoPath;
}

afterEach(() => {
  return P.all(temporaryRepos.splice(0).map((repoPath) => {
    return rmrf(repoPath, {});
  }));
});

module.exports = _.extend(global, {
  _: _,
  expect: chai.expect,
  sinon: require('sinon'),
  fs: require('fs'),
  path: require('path'),
  makeTemporaryRepo,
});

