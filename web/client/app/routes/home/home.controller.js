import angular from 'angular';

export const homeControllerModule = angular.module('homeControllerModule', [
])
.controller('HomeController', ($log) => {
  $log.info('Running home controller!');
});
