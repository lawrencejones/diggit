'use strict';
/* globals angular, alert */

const {gitWalker} = require('../../lib/ruby/gitWalker.js');

const codeOverviewControllerModule = angular.module('codeOverviewControllerModule', [
]).controller('CodeOverviewController', [
  '$scope',
  '$stateParams',
  'repo',
  function CodeOverviewController($scope, $stateParams, repo) {
    const ctrl = this;

    ctrl.metric = $stateParams.metric;

    gitWalker(repo.path, $stateParams.metric, $stateParams.pattern).then((data) => {
      ctrl.gitWalkerData = data;
    }).catch((err) => {
      ctrl.err = err;
      alert(`Attempting to run gitWalker raised the error: ${err}`);
    }).finally($scope.$apply.bind($scope));
  },
]);

module.exports = {codeOverviewControllerModule};
