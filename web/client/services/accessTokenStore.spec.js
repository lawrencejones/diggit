import angular from 'angular';
import 'angular-mocks';

import {accessTokenStoreModule, ACCESS_TOKEN_KEY} from './accessTokenStore';

describe('AccessTokenStore', () => {
  beforeEach(angular.mock.module(accessTokenStoreModule.name));

  let $window;
  let AccessTokenStore;
  let token;

  beforeEach(inject(($injector) => {
    $window = $injector.get('$window');
    $window.localStorage.clear();

    AccessTokenStore = $injector.get('AccessTokenStore');
    token = {token: 'jwt-token-payload'};
  }));

  it('sets, recovers and clears token', () => {
    expect(AccessTokenStore.get()).toBeNull();

    AccessTokenStore.set(token);
    expect(AccessTokenStore.get()).toEqual(token);

    AccessTokenStore.clear();
    expect(AccessTokenStore.get()).toBeNull();

    expect($window.localStorage.length).toEqual(0);
  });

  describe('#get', () => {
    describe('with an access token in localStorage', () => {
      beforeEach(() => {
        $window.localStorage.setItem(ACCESS_TOKEN_KEY, JSON.stringify(token));
      });

      it('returns the parsed token', () => {
        expect(AccessTokenStore.get()).toEqual(token);
      });
    });

    describe('with no access token', () => {
      it('returns null', () => {
        expect(AccessTokenStore.get()).toBeNull();
      });
    });
  });

  describe('#set', () => {
    describe('with plain string token', () => {
      it('throws an error', () => {
        expect(() => AccessTokenStore.set('plain-token'))
          .toThrowError(/token must be/i);
      });
    });

    describe('with extra keys in token', () => {
      it('throws an error', () => {
        expect(() => AccessTokenStore.set({token: 'token', extraKey: 'extra'}))
          .toThrowError(/token must be/i);
      });
    });
  });
});
