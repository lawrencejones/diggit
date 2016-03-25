'use strict';
/* globals angular */

const homeControllerModule = angular.module('homeControllerModule', [
  'ui.bootstrap',
  'angular-humanize',
])

.filter('humanizeMetric', () => {
  return (metricKey) => {
    return metricKey
      .replace(/_/g, ' ')
      .replace(/^\w/, (char) => { return char.toUpperCase() });
  };
})

.controller('HomeController', [
  '$uibModal',
  'repo',
  function HomeController($uibModal, repo) {
    const ctrl = this;

    ctrl.repo = repo;
    ctrl.clickCodeOverview = () => {
      $uibModal.open({
        animation: true,
        size: 'sm',
        controller: [
          '$uibModalInstance',
          '$scope',
          ($uibModalInstance, $scope) => {
            $scope.close = $uibModalInstance.close.bind($uibModalInstance);
          },
        ],
        template: `
        <div class="col-md-12" style="margin-bottom: 6px">
          <label style="margin-top: 4px">File glob</label>
          <input type="text" class="form-control" ng-model="fileGlob" placeholder="*.{rb,js}">
          </input>
        </div>
        <ul class="nav nav-pills nav-stacked">
          <li ng-repeat="metric in ['file_size', 'lines_of_code', 'no_of_authors', 'complexity']">
            <a href="#" ng-click="close()" ui-sref="app.codeOverview({metric: metric, pattern: fileGlob})">
              {{ metric | humanizeMetric }}
            </a>
          </li>
        </ul>
        `,
      });
    };
  },
]);

module.exports = {homeControllerModule};
