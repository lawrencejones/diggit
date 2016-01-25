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

    refactorDiligence(repo.path, (commit) => {
      $scope.$apply(() => { ctrl.progress = commit })
    })
      .then((profile) => {
        ctrl.profile = profile;
        ctrl.hierarchalProfile =
          generateHierarchy(profile.method_histories, {
            separator: '::',
            valueKey: 'score',
            valueMapper: (methodHistory) => { return Math.pow(methodHistory.length, 2) },
          });
        $scope.$digest();
      })
      .catch((error) => {
        alert(`Attempting to run refactorDiligence raised an error! [${error}]`);
      });
  },
]);

module.exports = {refactorDiligenceControllerModule};
