'use strict';

const _ = require('lodash');

const {processFrames} = require('./visualisation.js');

describe('Visualisation', () => {
  describe('.processFrames', () => {
    const getFrame = (frames, searchLabel) => {
      return _.find(frames, ({label}) => { return label === searchLabel })
    };

    const unprocessedFrames = [
      { label: 'root', score: 7, x: 0, y: 0, w: 100, h: 100 },
      { label: 'root/b', score: 1, x: 0, y: 0, w: 100, h: 25 },
      { label: 'root/a', score: 3, x: 0, y: 25, w: 100, h: 75 },
      { label: 'root/a/aa', score: 1, x: 0, y: 25, w: 33, h: 75 },
      { label: 'root/a/ab', score: 2, x: 33, y: 25, w: 67, h: 75 },
      { label: 'root/bb', score: 3, x: 0, y: 25, w: 100, h: 75 },
    ];

    let separator = '/';

    it('marks each frame with a parent', () => {
      let {frames} = processFrames(unprocessedFrames, separator);

      expect(getFrame(frames, 'root/a/aa').parent)
        .to.equal(getFrame(frames, 'root/a'));
    });

    it('will not mark root/b as a parent of root/bb', () => {
      let {frames} = processFrames(unprocessedFrames, separator);

      expect(getFrame(frames, 'root/bb').parent)
        .to.equal(getFrame(frames, 'root'));
    });

    it('marks any parents as isParent=true', () => {
      let {frames} = processFrames(unprocessedFrames, separator);

      expect(getFrame(frames, 'root/a').isParent).to.be.true;
      expect(getFrame(frames, 'root/a/aa').isParent).to.be.undefined;
    });
  });
});
