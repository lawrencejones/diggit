import angular from 'angular';

import {httpFactoryModule} from './httpFactory.js';
import {authInterceptorModule} from './authInterceptor';

export const projectsModule = angular.module('projectsModule', [
  httpFactoryModule.name,
  authInterceptorModule.name,
])
.factory('Projects', (HttpFactory, AuthInterceptor) => {
  return HttpFactory.create({
    url: '/api/projects/:owner/:repo',
    interceptor: AuthInterceptor,
  }, {
    findAll: { method: 'GET' },
    update: { method: 'PUT' },
  });
});
