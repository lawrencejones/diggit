'use strict';

const fs = require('fs');
const path = require('path');
const md5 = require('md5');
const P = require('bluebird');

const createCache = (cachePath) => {
  return {

    get: (key) => {
      let cacheObjectPath = path.join(cachePath, md5(key));
      if (fs.existsSync(cacheObjectPath)) {
        return JSON.parse(fs.readFileSync(cacheObjectPath));
      }
    },

    getOrFulfill: function(key, fulfiller) {
      let cacheObject = this.get(key);
      if (cacheObject) {
        return P.resolve(cacheObject);
      }

      let cache = this;
      return new P((resolve) => {
        fulfiller((value) => { resolve(cache.put(key, value)) });
      });
    },

    put: (key, value) => {
      let cacheObjectPath = path.join(cachePath, md5(key));
      return fs.writeFileSync(cacheObjectPath, JSON.stringify(value), 'utf-8');
    },
  };
};

module.exports = {createCache};
