import angular from 'angular';
import 'angular-ui-router';
import _ from 'lodash';

import {PROJECTS_INDEX_ROUTE_STATE} from '../projects/index/projects-index.route.js';
import {LOGIN_ROUTE_STATE} from '../login/login.route.js';

import {authModule} from '../../services/auth.js';
import {accessTokenStoreModule} from '../../services/accessTokenStore.js';

export const githubCallbackControllerModule = angular.module('githubCallbackControllerModule', [
  'ui.router',
  authModule.name,
  accessTokenStoreModule.name,
])
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
      AccessTokenStore.set(access_token);
      $state.go(PROJECTS_INDEX_ROUTE_STATE);
    }, fail);
});
