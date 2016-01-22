'use strict';
/* globals angular */

const _ = require('lodash');
const ProgressBar = require('../../bower_components/progressbar.js/dist/progressbar.js');

const progressCircleComponentModule = angular.module('progressCircleComponentModule', [
])
.directive('progressCircle', [() => {
  return {
    replace: true,
    transclude: true,
    template: `
      <div style="position: relative" class="progress-circle">
        <header class="progress-circle-text"
                style="font-size: 2.1em;
                       white-space: nowrap;
                       position: absolute;
                       top: 50%; left: 50%;
                       transform: translate(-50%, -50%)">
          {{ count() }} / {{ total() || 0 }}
        </header>
      </div>`,
    scope: { total: '&', count: '&' },
    link: ($scope, $circle, attr, ctrl, transclude) => {
      $circle.css({
        position: 'relative',
        height: attr.circleSize,
        width: attr.circleSize
      });

      $circle.append(transclude());

      let circle = new ProgressBar.Circle($circle[0], {
        color: '#1f77b4',
        trailColor: '#ddd',
        strokeWidth: 2,
      });

      $scope.$watch('count() / total()', (percent) => {
        percent = _.isNaN(percent) ? 0 : percent;
        circle.animate(percent);
      });
    },
  };
}]);

module.exports = {progressCircleComponentModule};
