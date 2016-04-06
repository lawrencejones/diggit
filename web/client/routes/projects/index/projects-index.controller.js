import angular from 'angular';

export const projectsIndexControllerModule = angular.module('projectsIndexControllerModule', [
])
.controller('ProjectsIndexController', function($log, projects) {
  let ctrl = this;

  $log.info(`Received ${projects.projects.length} projects`);
  ctrl.projects = projects.projects;
});
