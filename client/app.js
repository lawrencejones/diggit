'use strict';
/* globals angular */

const remote = require('remote');
const {loadRepoSummary} = require('./lib/repo.js');

/* Routes */
const {homeRouteModule, HOME_ROUTE_STATE} = require('./routes/home/home.route.js');
const {codeOverviewRouteModule} = require('./routes/code-overview/code-overview.route.js');
const {refactorDiligenceRouteModule} = require('./routes/refactor-diligence/refactor-diligence.route.js');

angular.module('diggit', [
  'ui.router',
  'ui.bootstrap',
  homeRouteModule.name,
  codeOverviewRouteModule.name,
  refactorDiligenceRouteModule.name,
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
