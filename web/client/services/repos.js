import angular from 'angular';

import {httpFactoryModule} from './httpFactory.js';
import {authInterceptorModule} from './authInterceptor';

export const reposModule = angular.module('reposModule', [
  httpFactoryModule.name,
  authInterceptorModule.name,
])
.factory('Repos', (HttpFactory, AuthInterceptor) => {
  return HttpFactory.create({
    url: '/api/repos/:id',
    interceptor: AuthInterceptor,
  }, {
    findAll: {
      method: 'GET',
    },
  });
});
