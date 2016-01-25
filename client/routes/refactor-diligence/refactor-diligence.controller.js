'use strict';
/* globals angular, alert */

const {refactorDiligence} = require('../../lib/ruby/refactorDiligence.js');
const {generateHierarchy} = require('../../lib/hierarchalData.js');

const refactorDiligenceControllerModule = angular.module('refactorDiligenceControllerModule', [
]).controller('RefactorDiligenceController', [
  '$scope',
  '$log',
  'repo',
  function RefactorDiligenceController($scope, $log, repo) {
    const ctrl = this;

    ctrl.progress = { count: 0, total: 0 };

    refactorDiligence(repo.path)
      .on('commit', (commit) => { $scope.$apply(() => { ctrl.progress = commit }) })
      .on('done', (profile) => {
        ctrl.profile = profile;
        ctrl.hierarchalProfile =
          generateHierarchy(profile.method_histories, '::', (methodHistory) => {
            let score = methodHistory.size;
            if (score > 1) return score * score;
          });
        $scope.$digest();
      })
      .on('exit', (exitStatus) => {
        if (exitStatus !== 0) {
          alert(`Attempting to run refactorDiligence raised an error!`);
        }
      });
  },
]);

module.exports = {refactorDiligenceControllerModule};
