'use strict';
/* globals angular */

const remote = require('remote');
const {loadRepoSummary} = require('./lib/repo.js');

/* Routes */
const {homeRouteModule, HOME_ROUTE_STATE} = require('./routes/home/home.route.js');
const {codeOverviewRouteModule} = require('./routes/code-overview/code-overview.route.js');

angular.module('diggit', [
  'ui.router',
  homeRouteModule.name,
  codeOverviewRouteModule.name,
])

.constant('repo', loadRepoSummary(remote.getGlobal('REPO_PATH')))

.config(($locationProvider, $stateProvider) => {
  $locationProvider.html5Mode(false);
  $stateProvider.state('app', {
    abstract: true,
  });
})

.run(($state) => {
  $state.go(HOME_ROUTE_STATE);
});
