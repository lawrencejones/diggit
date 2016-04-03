import angular from 'angular';

import {httpFactoryModule} from './httpFactory.js';

export const authModule = angular.module('authModule', [
  httpFactoryModule.name,
])
.factory('Auth', (HttpFactory) => {
  return HttpFactory.create({url: '/api/auth'}, {
    createAccessToken: { method: 'POST', url: '/api/auth/access_token' },
  });
});
