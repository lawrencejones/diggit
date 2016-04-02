import angular from 'angular';
import 'angular-ui-router';
import _ from 'lodash';

import {HOME_ROUTE_STATE} from 'routes/home/home.route.js';
import {LOGIN_ROUTE_STATE} from 'routes/login/login.route.js';
import {authModule} from 'services/auth.js';

export const GITHUB_CALLBACK_ROUTE_STATE = 'app.githubCallback';
export const githubCallbackRouteModule = angular.module('githubCallbackRouteModule', [
  'ui.router',
  authModule.name,
])
.config(($stateProvider) => {
  $stateProvider.state(GITHUB_CALLBACK_ROUTE_STATE, {
    url: '/github_callback?error&code&state',
    controllerAs: 'ctrl',
    controller: 'GithubCallbackController',
  });
})
.controller('GithubCallbackController', function(Auth, AccessTokenStore, $log, $window, $state) {
  const fail = (error) => {
    $window.alert(`There was an error [${error}] during OAuth, please try again`);
    $state.go(LOGIN_ROUTE_STATE);
  };

  if ($state.params.error) {
    fail($state.params.error);
  }

  Auth.createAccessToken({data: _.pick($state.params, 'code', 'state')})
    .then(({access_token}) => {
      if (!/\S+/.test(access_token.token)) { return fail('invalid_access_token') }

      $log.info('Successful github auth!');
      AccessTokenStore.set(access_token.token);
      $state.go(HOME_ROUTE_STATE);
    }, fail);
});
