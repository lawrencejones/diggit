'use strict';
/* globals window, $, d3 */

const _ = require('lodash');
const { renderGraph } = require('../client/vis.js');
const { balance } = require('../client/renderer.js');

let renderInputFixture = require('../fixtures/rendererInputFixture.json');

let renderOutputFixture = [
  {
    label: '/Users',
    x: 0, y: 0,
    width: 100,
    height: 80,
    score: 76,
  }, {
    label: '/Users/Guest',
    x: 75, y: 0,
    width: 25,
    height: 80,
    score: 19,
  }, {
    label: '/Users/lawrencejones',
    x: 0, y: 0,
    width: 75,
    height: 80,
    score: 57,
  }, {
    label: '/etc',
    x: 100, y: 0,
    width: 30,
    height: 50,
    score: 14,
  }, {
    label: '/Applications',
    x: 100, y: 50,
    width: 30,
    height: 30,
    score: 8,
  }
];

renderGraph('d3-target', _.tap(balance(renderInputFixture, [0, 0, 800, 480]), console.log.bind(console)));
