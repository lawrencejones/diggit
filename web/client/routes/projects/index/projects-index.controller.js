import angular from 'angular';
import 'angular-ui-router';
import _ from 'lodash';

import {projectsModule} from '../../../services/projects.js'

export const projectsIndexControllerModule = angular.module('projectsIndexControllerModule', [
  'ui.router',
  projectsModule.name,
])
.controller('ProjectsIndexController', function($log, $state, $window, projects, Projects) {
  let ctrl = this;

  $log.debug(`Received ${projects.projects.length} projects`);

  _.extend(ctrl, {
    projects: projects.projects,
    updateProject: (project, fields) => {
      let [owner, repo] = project.gh_path.split('/');
      Projects.update({params: {owner, repo}, data: {projects: fields}})
        .then(() => {
          $log.debug(`Successfully updated project!`);
          $state.reload();
        })
        .catch((err) => { $window.alert(`Failed to update project with ${err}`); });
    },
  });
});
