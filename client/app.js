'use strict';
/* globals angular */

const remote = require('remote');

/* Routes */
const {homeRouteModule, HOME_ROUTE_STATE} = require('./routes/home/home.route.js');

/* Components */
const {repoSummaryWellComponentModule} = require('./components/repo-summary-well/repo-summary-well.directive.js');

angular.module('diggit', [
  'ui.router',
  homeRouteModule.name,
  repoSummaryWellComponentModule.name,
])

.config(($locationProvider, $stateProvider) => {
  $locationProvider.html5Mode(false);
  $stateProvider.state('app', {
    abstract: true,
  });
})

.constant('REPO_PATH', remote.getGlobal('REPO_PATH'))

.run(($state) => {
  $state.go(HOME_ROUTE_STATE);
});
