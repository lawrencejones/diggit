'use strict';
/* globals window, $, d3 */

const _ = require('lodash');
const { renderGraph } = require('../client/vis.js');
const { generateFrameRectangles } = require('../client/renderer.js');

let gitWalkerData = require('remote').getGlobal('frame');
let frameRectangles = generateFrameRectangles(gitWalkerData, [0, 0, 800, 480]);

renderGraph('d3-target', frameRectangles);
