'use strict';
/* globals angular, alert */

const {gitWalker} = require('../../lib/ruby/gitWalker.js');

const codeOverviewControllerModule = angular.module('codeOverviewControllerModule', [
]).controller('CodeOverviewController', [
  '$scope',
  'repo',
  function CodeOverviewController($scope, repo) {
    const ctrl = this;

    gitWalker(repo.path, 'lines_of_code').then((data) => {
      ctrl.gitWalkerData = data;
    }).catch((err) => {
      ctrl.err = err;
      alert(`Attempting to run gitWalker raised the error: ${err}`);
    }).finally($scope.$apply.bind($scope));
  },
]);

module.exports = {codeOverviewControllerModule};
