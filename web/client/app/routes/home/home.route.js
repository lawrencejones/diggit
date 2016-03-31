import angular from 'angular';

import {homeControllerModule} from './home.controller.js';
import template from './home.html!text';

export const HOME_ROUTE_STATE = 'app.home';
export const homeRouteModule = angular.module('homeRouteModule', [
  'ui.router',
  homeControllerModule.name,
])
.config(($stateProvider) => {
  $stateProvider.state(HOME_ROUTE_STATE, {
    url: '/home',
    template,
    controllerAs: 'ctrl',
    controller: 'HomeController',
  });
});
