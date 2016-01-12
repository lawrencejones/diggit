'use strict';
/* globals window, $, d3 */

const _ = require('lodash');
const { renderGraph } = require('../client/vis.js');
const { generateFrameRectangles } = require('../client/renderer.js');

let renderInputFixture = require('../fixtures/rendererInputFixture.json');
let frameRectangles = generateFrameRectangles(renderInputFixture, [0, 0, 800, 480]);

renderGraph('d3-target', frameRectangles);
