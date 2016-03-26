'use strict';
/* globals angular */

const {refactorDiligenceControllerModule} = require('./refactor-diligence.controller.js');
const {grandPerspectiveComponentModule} = require('../../components/grand-perspective/grand-perspective.directive.js');
const {progressCircleComponentModule} = require('../../components/progress-circle/progress-circle.directive.js');

const REFACTOR_DILIGENCE_ROUTE_STATE = 'app.refactorDiligence';
const refactorDiligenceRouteModule = angular.module('refactorDiligenceRouteModule', [
  'ui.router',
  refactorDiligenceControllerModule.name,
  grandPerspectiveComponentModule.name,
  progressCircleComponentModule.name,
])
.config([
  '$stateProvider',
  ($stateProvider) => {
    $stateProvider.state(REFACTOR_DILIGENCE_ROUTE_STATE, {
      url: '/refactor-diligence',
      template: require('./refactor-diligence.html'),
      bindToController: true,
      controllerAs: 'ctrl',
      controller: 'RefactorDiligenceController',
    });
  },
]);

module.exports = {refactorDiligenceRouteModule, REFACTOR_DILIGENCE_ROUTE_STATE};
