import angular from 'angular';
import 'angular-mocks';
import {authInterceptorModule} from './authInterceptor';

describe('AuthInterceptor', () => {
  beforeEach(angular.mock.module(authInterceptorModule.name));

  let $state;
  let AuthInterceptor;
  let AccessTokenStore;

  beforeEach(inject(($injector) => {
    $state = $injector.get('$state');
    AuthInterceptor = $injector.get('AuthInterceptor');
    AccessTokenStore = $injector.get('AccessTokenStore');
  }));

  describe('#request', () => {
    let token;
    let request;

    describe('with access token already loaded', () => {
      beforeEach(() => {
        request = {};
        token = { token: 'jwt-token-payload' };
        spyOn(AccessTokenStore, 'get').and.returnValue(token);
      });

      it('adds Authorization header', () => {
        AuthInterceptor.request(request);
        expect(request.headers.Authorization).toEqual(`Bearer ${token.token}`);
      });

      it('returns request config', () => {
        expect(AuthInterceptor.request(request)).toBe(request);
      });
    });

    describe('with no access token', () => {
      beforeEach(() => {
        request = {};
        spyOn(AccessTokenStore, 'get').and.returnValue(null);
      });

      it('returns request config', () => {
        expect(AuthInterceptor.request(request)).toBe(request);
      });
    });
  });

  describe('#responseError', () => {
    beforeEach(() => {
      spyOn($state, 'go').and.returnValue(null);
      spyOn(AccessTokenStore, 'clear').and.returnValue(null);
    });

    describe('with non-401 error', () => {
      beforeEach(() => AuthInterceptor.responseError({status: 400}))

      it('does not make state change', () => {
        expect($state.go).not.toHaveBeenCalled();
      });

      it('does not clear AccessTokenStore', () => {
        expect(AccessTokenStore.clear).not.toHaveBeenCalled();
      });
    });

    describe('with 401 error', () => {
      beforeEach(() => AuthInterceptor.responseError({status: 401}))

      it('clears AccessTokenStore', () => {
        expect(AccessTokenStore.clear).toHaveBeenCalled();
      });

      it('changes to login state', () => {
        expect($state.go).toHaveBeenCalled();
        expect($state.go.mostRecentCall.args[0]).toMatch(/login/);
      });
    });
  });
});
