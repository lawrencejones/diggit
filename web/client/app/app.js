import angular from 'angular';
import 'angular-ui-router';

import {homeRouteModule} from './routes/home/home.route.js';

export const appModule = angular.module('app', [
  'ui.router',
  homeRouteModule.name,
])

.config(($locationProvider, $httpProvider, $urlRouterProvider, $stateProvider) => {
  $locationProvider.html5Mode({enabled: true, requireBase: false});

  $httpProvider.useApplyAsync(true);
  $urlRouterProvider.otherwise('/home');
  $stateProvider.state('app', {
    abstract: true,
  });
})

.run(($state) => { $state.go('app.home'); })
