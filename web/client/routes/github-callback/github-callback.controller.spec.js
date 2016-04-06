import angular from 'angular';
import 'angular-mocks';

import {PROJECTS_INDEX_ROUTE_STATE} from '../projects/index/projects-index.route.js';
import {LOGIN_ROUTE_STATE} from '../login/login.route.js';

import {githubCallbackControllerModule} from './github-callback.controller.js';

describe('GithubCallbackController', () => {
  beforeEach(angular.mock.module(githubCallbackControllerModule.name));

  const accessTokenSuccess = () => {
    return { access_token: { token: 'github-oauth-token' } }
  };

  const accessTokenFailed = () => {
    return { error: 'oauth_error' }
  };

  let $state;
  let $q;
  let stateGoSpy;
  let alertSpy;
  let Auth;
  let AccessTokenStore;
  let scope;
  let createController;

  beforeEach(inject(($injector, $rootScope, $controller, $window, _$q_, _$state_) => {
    $state = _$state_
    $q = _$q_;
    stateGoSpy = spyOn($state, 'go');
    alertSpy = spyOn($window, 'alert');

    Auth = $injector.get('Auth');
    AccessTokenStore = $injector.get('AccessTokenStore');

    scope = $rootScope.$new();
    createController = () => {
      $controller('GithubCallbackController as ctrl', {
        $scope: scope,
        $state,
      });
    };
  }));

  const itAlertsAndGoesToLogin = () => {
    it('throws an alert', () => {
      expect(alertSpy).toHaveBeenCalled();
    });

    it('gos to login state', () => {
      expect(stateGoSpy).toHaveBeenCalledWith(LOGIN_ROUTE_STATE);
    });
  }

  describe('with error in params', () => {
    beforeEach(() => {
      $state.params = {error: 'oauth_error'};
      createController();
    });

    itAlertsAndGoesToLogin();
  });

  describe('with no error in params', () => {
    let createAccessTokenSpy;
    let accessTokenDeferred;

    beforeEach(() => {
      $state.params = {code: 'code', state: 'state'};
      createAccessTokenSpy = spyOn(Auth, 'createAccessToken');
      accessTokenDeferred = $q.defer();
      createAccessTokenSpy.and.returnValue(accessTokenDeferred.promise);
    });

    it('calls Auth.createAccessToken with code and state', () => {
      createController();
      expect(createAccessTokenSpy)
        .toHaveBeenCalledWith({data: {code: 'code', state: 'state'}});
    });

    describe('with successful access token exchange', () => {
      beforeEach(() => {
        createController();
        accessTokenDeferred.resolve(accessTokenSuccess());
        scope.$digest();
      });

      it('sets access token in store', () => {
        expect(AccessTokenStore.get().token).toEqual('github-oauth-token');
      });

      it('gos to projects state', () => {
        expect(stateGoSpy).toHaveBeenCalledWith(PROJECTS_INDEX_ROUTE_STATE);
      });
    });

    describe('with failed access token exchange', () => {
      beforeEach(() => {
        createController();
        accessTokenDeferred.reject(accessTokenFailed());
        scope.$digest();
      });

      itAlertsAndGoesToLogin();
    });
  });
});
