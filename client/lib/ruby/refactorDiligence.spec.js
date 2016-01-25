'use strict';

const {makeTemporaryRepo} = require('../../specHelper.js');
const {refactorDiligence, parseNoOfCommits, parseCommitSha} = require('./refactorDiligence.js');

describe('RefactorDiligence', () => {
  describe('.refactorDiligence', () => {
    if (!process.env.INTEG) { return }

    it('runs against test repo', () => {
      return refactorDiligence(makeTemporaryRepo());
    });
  });

  describe('.parseNoOfCommits', () => {
    describe('for valid no of commits log', () => {
      let logString = `D, [2016-01-22] DEBUG -- RepoScanner: NO OF COMMITS 30`;

      it('returns sha string', () => {
        expect(parseNoOfCommits(logString)).to.equal(30);
      });
    });

    describe('for nonsense log', () => {
      let logString = `D, [2016-01-22] DEBUG -- RepoScanner: NONSENSE COMMITS`;

      it('returns undefined', () => {
        expect(parseNoOfCommits(logString)).to.be.undefined;
      });
    });
  });

  describe('.parseCommitSha', () => {
    describe('for valid sha in log', () => {
      let logString = `D, [2016-01-22] DEBUG -- CommitScanner: SCAN shasha`;

      it('returns sha string', () => {
        expect(parseCommitSha(logString)).to.equal('shasha');
      });
    });

    describe('for non sha commit log', () => {
      let logString = `D, [2016-01-22] DEBUG -- CommitScanner: PLANNER shasha`;

      it('returns undefined', () => {
        expect(parseCommitSha(logString)).to.be.undefined;
      });
    });
  });
});
