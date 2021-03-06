import angular from 'angular';
import 'angular-ui-router';

import {LOGIN_ROUTE_STATE} from '../routes/login/login.route.js';
import {accessTokenStoreModule} from './accessTokenStore';

export const authInterceptorModule = angular.module('authInterceptorModule', [
  'ui.router',
  accessTokenStoreModule.name,
]).factory('AuthInterceptor', ($q, $injector, $cacheFactory, AccessTokenStore) => {
  return {
    request: (request) => {
      let accessToken = AccessTokenStore.get();

      if (!accessToken) {
        return request;
      }

      request.headers = request.headers || {};
      request.headers.Authorization = `Bearer ${accessToken.token}`;

      return request;
    },
    responseError: (response) => {
      if (response.status == 401) {
        AccessTokenStore.clear();
        $cacheFactory.get('$http').removeAll();
        $injector.get('$state').go(LOGIN_ROUTE_STATE);
      }

      return $q.reject(response);
    },
  };
});
