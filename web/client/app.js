import angular from 'angular';
import 'angular-ui-router';
import 'twbs/bootstrap/css/bootstrap.css!';

import {homeRouteModule} from './routes/home/home.route.js';
import {loginRouteModule} from './routes/login/login.route.js';
import {authInterceptorModule} from './services/authInterceptor';

export const appModule = angular.module('app', [
  'ui.router',
  homeRouteModule.name,
  loginRouteModule.name,
  authInterceptorModule.name,
])

.config(($locationProvider, $httpProvider, $urlRouterProvider, $stateProvider) => {
  $locationProvider.html5Mode({enabled: true, requireBase: false});

  $httpProvider.interceptors.push('AuthInterceptor')
  $httpProvider.useApplyAsync(true);

  $urlRouterProvider.otherwise('/home');
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
