import angular from 'angular';

export const reposControllerModule = angular.module('reposControllerModule', [
])
.controller('reposController', ($log) => {
  $log.info('Running repos controller!');
});
