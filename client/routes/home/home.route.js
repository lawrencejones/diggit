'use strict';
/* globals angular */

const HOME_ROUTE_STATE = 'app.home';
const homeRouteModule = angular.module('homeRouteModule', [
  'ui.router',
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
