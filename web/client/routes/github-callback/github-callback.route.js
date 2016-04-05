import angular from 'angular';
import 'angular-ui-router';

import {githubCallbackControllerModule} from './github-callback.controller.js';

export const GITHUB_CALLBACK_ROUTE_STATE = 'app.githubCallback';
export const githubCallbackRouteModule = angular.module('githubCallbackRouteModule', [
  'ui.router',
  githubCallbackControllerModule.name,
])
.config(($stateProvider) => {
  $stateProvider.state(GITHUB_CALLBACK_ROUTE_STATE, {
    url: '/github_callback?error&code&state',
    controllerAs: 'ctrl',
    controller: 'GithubCallbackController',
  });
});
