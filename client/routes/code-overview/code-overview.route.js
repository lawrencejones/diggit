'use strict';
/* globals angular */

const CODE_OVERVIEW_ROUTE_STATE = 'app.codeOverview';
const codeOverviewRouteModule = angular.module('codeOverviewRouteModule', [
  'ui.router',
])
.config([
  '$stateProvider',
  ($stateProvider) => {
    $stateProvider.state(CODE_OVERVIEW_ROUTE_STATE, {
      url: '/code-overview',
      template: require('./code-overview.html'),
      controllerAs: 'ctrl',
      controller: function($scope, repo) {
        const ctrl = this;
        ctrl.repo = repo;
      },
    });
  },
]);

module.exports = {codeOverviewRouteModule, CODE_OVERVIEW_ROUTE_STATE};
