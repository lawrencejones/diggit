import angular from 'angular';
import 'angular-ui-router';

import template from './login.html!text';

export const LOGIN_ROUTE_STATE = 'app.login';
export const loginRouteModule = angular.module('loginRouteModule', [
  'ui.router',
])
.config(($stateProvider) => {
  $stateProvider.state(LOGIN_ROUTE_STATE, {
    url: '/login',
    template,
  });
});

