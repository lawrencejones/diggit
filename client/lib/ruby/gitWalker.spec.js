'use strict';

const {gitWalker} = require('./gitWalker.js');
const {makeTemporaryRepo} = require('../../specHelper.js');

describe('GitWalker', () => {
  describe('.gitWalker', () => {
    if (!process.env.INTEG) { return }

    it('runs against test repo', (done) => {
      gitWalker(makeTemporaryRepo(), 'file_size')
        .then(() => { done() })
        .catch(done);
    });
  });
});
