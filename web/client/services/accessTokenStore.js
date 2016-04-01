import angular from 'angular';

export const ACCESS_TOKEN_KEY = 'diggit.access_token';

export const accessTokenStoreModule = angular.module('accessTokenStoreModule', [
]).factory('AccessTokenStore', ($window) => {
  class AccessTokenStore {
    constructor(storeKey) {
      this.storeKey = storeKey;
    }

    get() {
      return JSON.parse($window.localStorage.getItem(this.storeKey));
    }

    set(token) {
      return $window.localStorage.setItem(this.storeKey, JSON.stringify(token));
    }

    clear() {
      $window.localStorage.removeItem(this.storeKey);
    }
  }

  return new AccessTokenStore(ACCESS_TOKEN_KEY);
});
