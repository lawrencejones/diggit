import angular from 'angular';

import './repos.css!';
import {reposControllerModule} from './repos.controller.js';
import template from './repos.html!text';

import {reposModule} from '../../services/repos.js';

export const REPOS_ROUTE_STATE = 'app.repos';
export const reposRouteModule = angular.module('reposRouteModule', [
  'ui.router',
  reposControllerModule.name,
  reposModule.name,
])
.config(($stateProvider) => {
  $stateProvider.state(REPOS_ROUTE_STATE, {
    url: '/repos',
    template,
    controllerAs: 'ctrl',
    controller: 'reposController',
    resolve: {
      repos: (Repos) => { return Repos.findAll() },
    },
  });
});
