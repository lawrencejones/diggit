'use strict';
/* globals angular */

const template = require('./repo-summary-panel.template.html');
const repoSummaryPanelComponentModule = angular.module('repoSummaryPanelComponentModule', [
  'angular-humanize',
])
.directive('repoSummaryPanel', [() => {
  return {
    template,
    controller: angular.noop,
    controllerAs: 'ctrl',
    bindToController: true,
    scope: {
      repo: '&',
    },
  };
}]);

module.exports = {repoSummaryPanelComponentModule};
