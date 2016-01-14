'use strict';
/* globals angular */

const {codeOverviewControllerModule} = require('./code-overview.controller.js');

const CODE_OVERVIEW_ROUTE_STATE = 'app.codeOverview';
const codeOverviewRouteModule = angular.module('codeOverviewRouteModule', [
  'ui.router',
  codeOverviewControllerModule.name,
])
.config([
  '$stateProvider',
  ($stateProvider) => {
    $stateProvider.state(CODE_OVERVIEW_ROUTE_STATE, {
      url: '/code-overview',
      template: require('./code-overview.html'),
      bindToController: true,
      controllerAs: 'ctrl',
      controller: 'CodeOverviewController',
    });
  },
]);

module.exports = {codeOverviewRouteModule, CODE_OVERVIEW_ROUTE_STATE};
