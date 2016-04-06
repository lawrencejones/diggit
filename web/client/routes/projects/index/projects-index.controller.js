import angular from 'angular';
import 'angular-ui-router';

import {projectsModule} from '../../../services/projects.js'

export const projectsIndexControllerModule = angular.module('projectsIndexControllerModule', [
  'ui.router',
  projectsModule.name,
])
.controller('ProjectsIndexController', function($log, $window, projects) {
  let ctrl = this;

  $log.debug(`Received ${projects.projects.length} projects`);
  ctrl.projects = projects.projects;
});
