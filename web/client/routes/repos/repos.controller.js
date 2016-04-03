import angular from 'angular';

export const reposControllerModule = angular.module('reposControllerModule', [
])
.controller('reposController', function($log, repos) {
  let ctrl = this;

  $log.info(`Received ${repos.repos.length} repos`);
  ctrl.repos = repos.repos;
});
