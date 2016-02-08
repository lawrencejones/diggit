'use strict';

const _ = require('lodash');

const {processFrames} = require('./visualisation.js');

describe('Visualisation', () => {
  describe('.processFrames', () => {
    const getFrame = (frames, searchLabel) => {
      return _.find(frames, ({label}) => { return label === searchLabel })
    };

    const unprocessedFrames = [
      { label: 'root/b', score: 1, x: 0, y: 0, w: 100, h: 25 },
      { label: 'root/a', score: 3, x: 0, y: 25, w: 100, h: 75 },
      { label: 'root/a/aa', score: 1, x: 0, y: 25, w: 33, h: 75 },
      { label: 'root/a/ab', score: 2, x: 33, y: 25, w: 67, h: 75 },
    ];

    it('marks each frame with a parent', () => {
      let {frames} = processFrames(unprocessedFrames);

      expect(getFrame(frames, 'root/a/aa').parent)
        .to.equal(getFrame(frames, 'root/a'));
    });
  });
});
