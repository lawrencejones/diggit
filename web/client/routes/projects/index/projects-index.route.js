import angular from 'angular';

import './projects-index.css!';
import {projectsIndexControllerModule} from './projects-index.controller.js';
import template from './projects-index.html!text';

import {projectWatchBtnComponentModule} from '../../../components/project-watch-btn/project-watch-btn.directive.js';
import {projectsModule} from '../../../services/projects.js';

export const PROJECTS_INDEX_ROUTE_STATE = 'app.projects.index';
export const projectsIndexRouteModule = angular.module('projectsIndexRouteModule', [
  'ui.router',
  projectsIndexControllerModule.name,
  projectWatchBtnComponentModule.name,
  projectsModule.name,
])
.config(($stateProvider) => {
  $stateProvider.state(PROJECTS_INDEX_ROUTE_STATE, {
    url: '/projects',
    template,
    controllerAs: 'ctrl',
    controller: 'ProjectsIndexController',
    resolve: {
      projects: (Projects) => { return Projects.findAll() },
    },
  });
});
