'use strict';
/* globals angular */

const _ = require('lodash');

const {generateFrameRectangles} = require('./rectangle-generator.js');
const {renderGrandPerspective} = require('./visualisation.js');

const grandPerspectiveComponentModule = angular.module('grandPerspectiveComponentModule', [
])
.directive('grandPerspective', [() => {
  return {
    restrict: 'A',
    scope: { 'getFrameData': '&frameData' },
    link: ($scope, $elem, attr) => {
      if (!_.isObject($scope.getFrameData())) {
        throw new Error(`Frame data must be object, not ${$scope.getFrameData()}`);
      }

      if (_.isNaN(attr.width + attr.height)) {
        throw new Error(`Cannot use grand-perspective on element lacking width or height`);
      }

      /* API currently requires an id, so generate random one if not present */
      if (_.isUndefined($elem.attr('id'))) {
        $elem.attr('id', `grand-perspective-${Math.floor(1000000 * Math.random())}`);
      }

      let frames =
        generateFrameRectangles($scope.getFrameData(),
                                [0, 0, parseInt(attr.width), parseInt(attr.height)]);
      renderGrandPerspective($elem.attr('id'), frames, attr);
    },
  };
}]);

module.exports = {grandPerspectiveComponentModule};
