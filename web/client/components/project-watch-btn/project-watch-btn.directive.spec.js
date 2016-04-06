import angular from 'angular';
import 'angular-mocks';
import _ from 'lodash';

import {projectWatchBtnComponentModule} from './project-watch-btn.directive.js';

describe('<project-watch-btn/>', () => {
  beforeEach(angular.mock.module(projectWatchBtnComponentModule.name));

  let btn;
  let scope;
  let $q;
  let $compile;
  let Projects;

  beforeEach(inject((_$q_, _$compile_, _Projects_, $rootScope) => {
    $q = _$q_;
    $compile = _$compile_;
    Projects = _Projects_;
    scope = _.extend($rootScope.$new(), {
      project: {
        gh_path: 'lawrencejones/diggit',
        watch: true,
      }
    });
  }));

  const compileBtn = () => {
    btn = $compile(`
      <project-watch-btn project="project">
      </project-watch-btn>
    `)(scope);
  };

  const itHasClass = (cls) => {
    it(`has .${cls} class`, () => {
      expect(btn.find('button').hasClass(cls)).toBe(true);
    })
  };

  const itHasLabel = (label) => {
    it(`has '${label}' label`, () => {
      expect(btn.text()).toEqual(label);
    });
  };

  const clickButton = () => {
    btn.find('button').triggerHandler('click');
    scope.$digest();
  };

  const itUpdateProjectWithWatch = (watch) => {
    beforeEach(() => {
      spyOn(Projects, 'update').and.returnValue($q.resolve({projects: {watch}}));
    });

    it(`updates project with watch=${watch}`, () => {
      clickButton();
      expect(Projects.update).toHaveBeenCalled();
      expect(Projects.update.calls.mostRecent().args[0].data.projects.watch).toBe(watch);
      expect(scope.project.watch).toBe(watch);
    });
  };

  describe('with watched project', () => {
    beforeEach(() => {
      scope.project.watch = true;
      compileBtn();
      scope.$digest();
    });

    itHasLabel('Stop watching');
    itHasClass('stop');

    describe('clicking', () => {
      itUpdateProjectWithWatch(false);
    });
  });

  describe('with non-watched project', () => {
    beforeEach(() => {
      scope.project.watch = false;
      compileBtn();
      scope.$digest();
    });

    itHasLabel('Start watching');
    itHasClass('start');

    describe('clicking', () => {
      itUpdateProjectWithWatch(true);
    });
  });
});
