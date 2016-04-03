import angular from 'angular';
import _ from 'lodash';

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
      if (!_.isObject(token) || _.keys(token).join(',') !== 'token') {
        throw new Error(`Token must be {token}, but received ${JSON.stringify(token)}!`);
      }
      return $window.localStorage.setItem(this.storeKey, JSON.stringify(token));
    }

    clear() {
      $window.localStorage.removeItem(this.storeKey);
    }
  }

  return new AccessTokenStore(ACCESS_TOKEN_KEY);
});
