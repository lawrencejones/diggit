'use strict';
/* globals angular */

const template = require('./repo-summary-well.template.html');
const repoSummaryWellComponentModule = angular.module('repoSummaryWellComponentModule', [
])
.directive('repoSummaryWell', [() => {
  return {
    template,
    replace: true,
    controller: angular.noop,
    controllerAs: 'ctrl',
    bindToController: true,
    scope: {
      repo: '&',
    },
  };
}]);

module.exports = {repoSummaryWellComponentModule};
