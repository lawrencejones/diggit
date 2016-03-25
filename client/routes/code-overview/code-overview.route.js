'use strict';
/* globals angular */

const {codeOverviewControllerModule} = require('./code-overview.controller.js');
const {grandPerspectiveComponentModule} = require('../../components/grand-perspective/grand-perspective.directive.js');

const CODE_OVERVIEW_ROUTE_STATE = 'app.codeOverview';
const codeOverviewRouteModule = angular.module('codeOverviewRouteModule', [
  'ui.router',
  codeOverviewControllerModule.name,
  grandPerspectiveComponentModule.name,
])
.config([
  '$stateProvider',
  ($stateProvider) => {
    $stateProvider.state(CODE_OVERVIEW_ROUTE_STATE, {
      url: '/code-overview/:metric/:pattern',
      template: require('./code-overview.html'),
      bindToController: true,
      controllerAs: 'ctrl',
      controller: 'CodeOverviewController',
    });
  },
]);

module.exports = {codeOverviewRouteModule, CODE_OVERVIEW_ROUTE_STATE};
