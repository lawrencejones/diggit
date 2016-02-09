'use strict';
/* globals angular */

const {homeControllerModule} = require('./home.controller.js');
const {repoSummaryPanelComponentModule} = require('../../components/repo-summary-panel/repo-summary-panel.directive.js');

const HOME_ROUTE_STATE = 'app.home';
const homeRouteModule = angular.module('homeRouteModule', [
  'ui.router',
  homeControllerModule.name,
  repoSummaryPanelComponentModule.name,
])
.config([
  '$stateProvider',
  ($stateProvider) => {
    $stateProvider.state(HOME_ROUTE_STATE, {
      url: '/home',
      template: require('./home.html'),
      controllerAs: 'ctrl',
      controller: 'HomeController',
    });
  },
]);

module.exports = {homeRouteModule, HOME_ROUTE_STATE};
