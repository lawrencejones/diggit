'use strict';
/* globals angular, alert */

const {refactorDiligence} = require('../../lib/refactorDiligence.js');

const refactorDiligenceControllerModule = angular.module('refactorDiligenceControllerModule', [
]).controller('RefactorDiligenceController', [
  '$scope',
  '$log',
  'repo',
  function RefactorDiligenceController($scope, $log, repo) {
    const ctrl = this;

    refactorDiligence(repo.path)
      .on('commit', (commit) => { $log.info(`Processed commit ${commit.sha}`) })
      .on('done', (profile) => { $scope.$apply(() => { ctrl.refactorDiligenceProfile = profile }) })
      .on('exit', (exitStatus) => {
        if (exitStatus !== 0) {
          alert(`Attempting to run refactorDiligence raised an error!`);
        }
      });
  },
]);

module.exports = {refactorDiligenceControllerModule};

