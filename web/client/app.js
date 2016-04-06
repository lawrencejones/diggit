import 'babel/external-helpers';
import angular from 'angular';
import 'angular-ui-router';
import 'twbs/bootstrap/css/bootstrap.css!';

import './app.css!';

import {projectsRouteModule} from './routes/projects/projects.route.js';
import {loginRouteModule} from './routes/login/login.route.js';
import {githubCallbackRouteModule} from './routes/github-callback/github-callback.route.js';

export const appModule = angular.module('app', [
  'ui.router',
  projectsRouteModule.name,
  loginRouteModule.name,
  githubCallbackRouteModule.name,
])

.config(($locationProvider, $httpProvider, $urlRouterProvider, $stateProvider) => {
  $locationProvider.html5Mode({enabled: true, requireBase: false});
  $httpProvider.useApplyAsync(true);

  $urlRouterProvider.otherwise('/login');
  $stateProvider.state('app', {
    abstract: true,
    template: `
    <div class="row">
      <div class="col-md-12">
        <h1 class="text-center">
          diggit
        </h1>
      </div>
    </div>
    <ui-view/>
    `
  });
})
