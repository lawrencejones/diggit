import angular from 'angular';

import {projectsIndexRouteModule} from './index/projects-index.route.js';

export const PROJECTS_ROUTE_STATE = 'app.projects';
export const projectsRouteModule = angular.module('projectsRouteModule', [
  'ui.router',
  projectsIndexRouteModule.name,
])
.config(($stateProvider) => {
  $stateProvider.state(PROJECTS_ROUTE_STATE, {
    abstract: true,
    template: '<ui-view></ui-view>',
  });
});
