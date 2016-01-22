'use strict';

const _ = require('lodash');
const {parseNoOfCommits, parseCommitSha, generateModuleHierarchy} = require('./refactorDiligence.js');

describe('RefactorDiligence', () => {
  describe('parseNoOfCommits', () => {
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

  describe('parseCommitSha', () => {
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

  describe('generateModuleHierarchy', () => {
    const generate = () => {
      return generateModuleHierarchy({
        'unscoped_method': [3, 2, 1],
        'Module::a': [2, 1],
        'Module::b': [1],
        'Module::Class::a': [3, 2, 1],
        'Module::Class::b': [2, 1],
      });
    };

    it('ignores unscoped methods', () => {
      expect(_.get(generate(), 'items.unscoped_method')).to.be.undefined;
    });

    it('nests classes under modules', () => {
      expect(_.get(generate(), 'items.Module.items.Class')).to.be.an('object');
    })

    it('aggregates scores for classes', () => {
      expect(_.get(generate(), 'items.Module.items.Class.score')).to.equal(5);
    });

    it('aggregates scores for modules', () => {
      expect(_.get(generate(), 'items.Module.score')).to.equal(8);
    });
  });
});
