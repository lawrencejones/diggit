'use strict';
/* globals angular, alert */

const path = require('path');

const {refactorDiligence} = require('../../lib/ruby/refactorDiligence.js');
const {generateHierarchy} = require('../../lib/hierarchalData.js');

const refactorDiligenceControllerModule = angular.module('refactorDiligenceControllerModule', [
]).controller('RefactorDiligenceController', [
  '$scope',
  '$log',
  'repo',
  'diggitCache',
  function RefactorDiligenceController($scope, $log, repo, diggitCache) {
    const ctrl = this;

    /* Given the method histories, loads the profile onto the controller */
    const generateProfile = (methodHistories) => {
      ctrl.hierarchalProfile =
        generateHierarchy(methodHistories, {
          separator: '::',
          valueKey: 'score',
          valueMapper: (methodHistory) => { return Math.pow(methodHistory.length, 2) },
        });
    };

    ctrl.progress = { count: 0, total: 0 };

    diggitCache.getOrFulfill(`${path.basename(repo.path)}#${repo.sha}`, (fulfill) => {

      refactorDiligence(repo.path, (commit) => {
        $scope.$apply(() => { ctrl.progress = commit })
      })
        .then(({method_histories}) => { fulfill(method_histories) })
        .catch((error) => {
          alert(`Attempting to run refactorDiligence raised an error! [${error}]`);
        });

    }).then((methodHistories) => {
      generateProfile(methodHistories);
      $scope.$apply();
    });
  },
]);

module.exports = {refactorDiligenceControllerModule};
