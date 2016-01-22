'use strict';
/* globals angular, alert */

const {refactorDiligence, generateModuleHierarchy} = require('../../lib/refactorDiligence.js');

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
        ctrl.hierarchalProfile = generateModuleHierarchy(profile.method_histories);
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
