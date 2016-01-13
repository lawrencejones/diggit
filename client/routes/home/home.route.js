'use strict';
/* globals angular */

const {loadRepoSummary} = require('../../lib/repo.js');
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
      resolve: {
        repo: (REPO_PATH) => { return loadRepoSummary(REPO_PATH); },
      },
      controllerAs: 'ctrl',
      controller: function($scope, repo) {
        const ctrl = this;
        ctrl.repo = repo;
      },
    });
  },
]);

module.exports = {homeRouteModule, HOME_ROUTE_STATE};
