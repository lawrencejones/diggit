'use strict';
/* globals angular */

const remote = require('remote');
const path = require('path');
const {loadRepoSummary} = require('./lib/repo.js');
const {createCache} = require('./lib/cache.js');

/* Routes */
const {homeRouteModule, HOME_ROUTE_STATE} = require('./routes/home/home.route.js');
const {codeOverviewRouteModule} = require('./routes/code-overview/code-overview.route.js');
const {refactorDiligenceRouteModule} = require('./routes/refactor-diligence/refactor-diligence.route.js');

angular.module('diggit', [
  'ui.router',
  homeRouteModule.name,
  codeOverviewRouteModule.name,
  refactorDiligenceRouteModule.name,
])

.constant('repo', loadRepoSummary(remote.getGlobal('REPO_PATH')))
.constant('diggitCache', createCache(path.join(__dirname, '../cache')))

.config(($locationProvider, $stateProvider) => {
  $locationProvider.html5Mode(false);
  $stateProvider.state('app', {
    abstract: true,
  });
})

.run(($state) => {
  $state.go(HOME_ROUTE_STATE);
});
