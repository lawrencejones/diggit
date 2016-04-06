import angular from 'angular';

import {projectsModule} from '../../services/projects.js';
import template from './project-watch-btn.template.html!text';
import './project-watch-btn.css!';

export const projectWatchBtnComponentModule = angular.module('projectWatchBtnComponentModule', [
  projectsModule.name,
])
.directive('projectWatchBtn', () => {
  return {
    restrict: 'E',
    template,
    scope: { project: '=' },
    controllerAs: 'ctrl',
    bindToController: true,
    controller: function ProjectWatchBtnController(Projects) {
      this.updateProject = ({projects}) => {
        let [owner, repo] = this.project.gh_path.split('/');

        Projects.update({params: {owner, repo}, data: {projects}})
          .then(({projects}) => { this.project = projects })
          .catch((err) => { $window.alert(`Project update failed with ${err}`) });
      };
    },
  };
});
