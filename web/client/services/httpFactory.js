import angular from 'angular';
import _ from 'lodash';

/**
 * ngHttpFactory is a module that wraps Angular $http
 *
 * let BillHttp = HttpFactory.create({
 *   method: 'GET',
 *   url: '/api/bills/:id'
 * }, {
 *   find: {
 *     interceptor: {
 *       response: function(response) {
 *         return response.data;
 *       },
 *       responseError: function(responseError) {
 *         return responseError.data;
 *       }
 *     }
 *   },
 *   entries: {
 *     method: 'GET',
 *     url: '/api/submissions/:id/entries'
 *   }
 * });
 *
 *  BillHttp.find({params: { id: 1 }})
 *    .then(function(responseData) {
 *    });
 *  GET /api/bills/1
 */

 export const httpFactoryModule = angular.module('httpFactoryModule', [
]).service('HttpFactory', [
  '$http', '$q',
  function HttpFactoryService($http, $q) {

    function error(message) {
      throw new Error(message);
    }

    function defaultResponseInterceptor(response) {
      return response.data;
    }

    /**
     * This method is intended for encoding *key* or *value* parts of query
     * component. We need a custom
     * method because encodeURIComponent is too aggressive and encodes stuff
     * that doesn't have to be
     * encoded per http://tools.ietf.org/html/rfc3986:
     *    query       = *( pchar / "/" / "?" )
     *    pchar         = unreserved / pct-encoded / sub-delims / ":" / "@"
     *    unreserved    = ALPHA / DIGIT / "-" / "." / "_" / "~"
     *    pct-encoded   = "%" HEXDIG HEXDIG
     *    sub-delims    = "!" / "$" / "&" / "'" / "(" / ")"
     *                     / "*" / "+" / "," / ";" / "="
     */
    function encodeUriQuery(val, pctEncodeSpaces) {
      return encodeURIComponent(val).
        replace(/%40/gi, '@').
        replace(/%3A/gi, ':').
        replace(/%24/g, '$').
        replace(/%2C/gi, ',').
        replace(/%20/g, (pctEncodeSpaces ? '%20' : '+'));
    }

   /**
     * We need our custom method because encodeURIComponent is too aggressive
     * and doesn't follow
     * http://www.ietf.org/rfc/rfc3986.txt with regards to the character set
     * (pchar) allowed in path
     * segments:
     *    segment       = *pchar
     *    pchar         = unreserved / pct-encoded / sub-delims / ":" / "@"
     *    pct-encoded   = "%" HEXDIG HEXDIG
     *    unreserved    = ALPHA / DIGIT / "-" / "." / "_" / "~"
     *    sub-delims    = "!" / "$" / "&" / "'" / "(" / ")"
     *                     / "*" / "+" / "," / ";" / "="
     */
    function encodeUriSegment(val) {
      return encodeUriQuery(val, true).
        replace(/%26/gi, '&').
        replace(/%3D/gi, '=').
        replace(/%2B/gi, '+');
    }

    /**
     * Deep clones all configs
     * @param  {Object} all arguments
     * @return {Object}
     */
    function cloneConfigs() {
      let configs = _.map(_.toArray(arguments), _.cloneDeep);
      return _.merge.apply(null, configs);
    }

    /**
     * @param {Object} config $http config
     * @return {Object}
     */
    function setUrlParams(config) {
      let url = config.url;
      let params = config.params || {};
      let urlParams = {};

      // Clear old params
      delete config.params;

      _.each(url.split(/\W/), function(param){
        if (!(new RegExp('^\\d+$').test(param)) && param &&
            (new RegExp('(^|[^\\\\]):' + param + '(\\W|$)').test(url))) {
          urlParams[param] = true;
        }
      });

      url = url.replace(/\\:/g, ':');

      _.forEach(_.keys(urlParams), function(urlParam){
        let val = params[urlParam];
        let encodedVal;

        if (angular.isDefined(val) && val !== null) {
          encodedVal = encodeUriSegment(val);
          url = url.replace(new RegExp(':' + urlParam + '(\\W|$)', 'g'),
            encodedVal + '$1');
        } else {
          url = url.replace(new RegExp('(\/?):' + urlParam + '(\\W|$)', 'g'),
            function(match, leadingSlashes, tail) {
              if (tail.charAt(0) === '/') {
                return tail;
              } else {
                return leadingSlashes + tail;
              }
            }
          );
        }
      });

      // strip trailing slashes and set the url
      url = url.replace(/\/+$/, '');

      // then replace collapse `/.` if found in the last URL path segment
      // before the query
      // E.g. `http://url.com/id./format?q=x` becomes
      // `http://url.com/id.format?q=x`
      url = url.replace(/\/\.(?=\w+($|\?))/, '.');

      // replace escaped `/\.` with `/.`
      config.url = url.replace(/\/\\\./, '/.');

      // set params - delegate param encoding to $http
      _.forEach(params, function(value, key){
        if (!urlParams[key]) {
          config.params = config.params || {};
          config.params[key] = value;
        }
      });

      return config;
    }

    /**
     * http request
     * @param  {Object} config
     * @return {Promise}
     */
    function request(config) {
      let requestInterceptors = config.interceptor &&
        config.interceptor.request;
      let responseInterceptor = config.interceptor &&
        config.interceptor.response || defaultResponseInterceptor;
      let responseErrorInterceptor = config.interceptor &&
        config.interceptor.responseError || undefined;

      if (!_.isArray(requestInterceptors)) {
        requestInterceptors = [requestInterceptors];
      }

      config = $q.when(config);

      requestInterceptors.forEach(function(interceptor) {
        if (!_.isFunction(interceptor)) return;

        config = config.then(function(configValue) {
          return interceptor(configValue);
        });
      });

      return $q.when(config).then(function(config) {
        return $http(config)
          .then(responseInterceptor)
          .catch(function(rejection) {
            if (_.isFunction(responseErrorInterceptor)) {
              return responseErrorInterceptor(rejection);
            }
            return $q.reject(rejection);
          });
      });
    }

    /**
     * Rewrites property values to functions if the value is an object
     * and if the key is not blacklisted. The rewritten property values
     * are called @prop. The resulting function @fn.
     *
     * @fn(newConfig):
     * 1. config = _.extend({}, configDefaults, actions[@prop], newConfig)
     * 2. config = parseConfig(config);
     * 3. promise = request(config, function(response.data) {
     *      return factoryCreate(actions.factory, response.data)
     *    });
     *
     * promise will resolve w
     *
     * @param  {Object} configDefaults
     * @param  {Object} actions
     * @return {Object}
     */
    function methods(configDefaults, actions) {
      _.forEach(_.keys(actions), function(action) {
        let config = actions[action];
        if (_.isObject(config)) {
          actions[action] = _.flowRight(
            request,
            setUrlParams,
            _.partial(cloneConfigs, configDefaults, config)
          );
        }
      });
      return actions;
    }

    /**
     * Bulk = HttpFactory.create({
     *   url: '/api/payments_submissions/:id',
     * }, {
     *   findAll: {
     *     method: 'GET'
     *   }
     * });
     *
     * Bulk.findAll(config -> $http(config)).then();
     */

    let PARAM_DEFAULTS = {
      url: '',
    };

    /**
     * Build http methods
     *
     * @param  {Object} configDefaults|actions
     * @param  {Object|undefined} actions
     * @return {Object}
     */
    function create(configDefaults, actions) {
      if (!_.isObject(actions)) {
        actions = configDefaults;
        configDefaults = {};
      }

      if (!_.isObject(actions)) {
        error('@param {Object} actions not provided');
      }

      configDefaults = _.extend({}, PARAM_DEFAULTS, configDefaults);

      return methods(configDefaults, actions);
    }

    this.create = create;
    this.request = request;
  },

]);
