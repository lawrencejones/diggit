'use strict';
/* globals angular */

const {repoSummaryWellComponentModule} = require('../../components/repo-summary-well/repo-summary-well.directive.js');

const HOME_ROUTE_STATE = 'app.home';
const homeRouteModule = angular.module('homeRouteModule', [
  'ui.router',
  repoSummaryWellComponentModule.name,
])
.config([
  '$stateProvider',
  ($stateProvider) => {
    $stateProvider.state(HOME_ROUTE_STATE, {
      url: '/home',
      template: require('./home.html'),
      controllerAs: 'ctrl',
      controller: function($scope, repo) {
        const ctrl = this;
        ctrl.repo = repo;
      },
    });
  },
]);

module.exports = {homeRouteModule, HOME_ROUTE_STATE};
