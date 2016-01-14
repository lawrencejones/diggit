'use strict';
/* globals angular, alert */

const _ = require('lodash');
const {gitWalker} = require('../../lib/gitWalker.js');

const codeOverviewControllerModule = angular.module('codeOverviewControllerModule', [
]).controller('CodeOverviewController', [
  '$scope',
  'repo',
  function CodeOverviewController($scope, repo) {
    const ctrl = this;

    gitWalker(repo.path, 'lines-of-code').then((data) => {
      ctrl.gitWalkerData = data;
    }).catch((err) => {
      ctrl.err = err;
      alert(`Attempting to run gitWalker raised the error: ${err}`);
    }).finally($scope.$apply.bind($scope));
  },
]);

module.exports = {codeOverviewControllerModule};