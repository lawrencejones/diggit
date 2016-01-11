'use strict';

const chai = require('chai');
chai.use(require('sinon-chai'));

const _ = require('lodash');

_.extend(global, {
  _: _,
  fs: require('fs'),
  path: require('path'),
});

