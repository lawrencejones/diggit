'use strict';

const _ = require('lodash');

const gitWalkerData = require('./git-walker-data.fixture.json');
const {generateFrameRectangles, evenlySplit} = require('./rectangle-generator.js');

describe('RectangleGenerator', () => {
  describe('.generateFrameRectangles', () => {
    const gen = (data) => {
      return generateFrameRectangles(data || gitWalkerData, dim, drawDirectories);
    };

    let dim = [0, 0, 100, 100];  // initial dimensions
    let drawDirectories = false;

    it('exports method', () => {
      expect(generateFrameRectangles).to.be.a('function');
    });

    it('generates an array', () => {
      expect(gen()).to.be.an('array');
    });

    it('produces rectangles that all lie within initial dimensions', () => {
      gen().map(({x, y, w, h}) => {
        expect(x).to.be.within(dim[0], dim[0] + dim[2])
        expect(x + w).to.be.within(dim[0], dim[0] + dim[2])

        expect(y).to.be.within(dim[1], dim[1] + dim[3])
        expect(y + h).to.be.within(dim[1], dim[1] + dim[3])
      });
    });

    describe('with drawDirectories=false', () => {
      beforeEach(() => { drawDirectories = false });

      it('does not draw rectangle for code-overview directory', () => {
        expect(_.find(gen(), ({label}) => {
          return label == 'diggit/code-overview'
        })).not.to.exist;
      });
    });

    describe('with drawDirectories=true', () => {
      beforeEach(() => { drawDirectories = true });

      it('draws rectangle for code-overview directory', () => {
        expect(_.find(gen(), ({label}) => {
          return label == 'diggit/code-overview'
        })).to.exist;
      });
    });

    describe('with nested empty dirs', () => {
      beforeEach(() => { drawDirectories = true });

      const nestedData = {
        path: 'diggit',
        score: 874,
        items: {
          nested: {
            path: 'diggit/nested',
            score: 874,
            items: {
              a: { path: 'diggit/nested/a', score: 437 },
              b: { path: 'diggit/nested/b', score: 437 },
            },
          }
        },
      };

      /* Regression: infinite loop where algorithm assumed array but got object */
      it('does not infinitely recurse', () => {
        expect(gen(nestedData)).to.be.an('array');
      });
    });
  });

  describe('.evenlySplit', () => {
    const split = () => { return evenlySplit(sample, scoreKey, noOfPartitions) };
    const scoreKey = 'score';
    const noOfPartitions = 2;

    const generateItemSample = (n) => {
      return _.times(n, (i) => {
        return {
          path: String(i),
          score: Math.floor(Math.pow(10 * Math.random(), 3)),
        }
      });
    };

    let sample = null;
    let sampleTotalScore = null;
    let sampleSize = 500;

    beforeEach(() => {
      sample = generateItemSample(sampleSize);
      sampleTotalScore = _.chain(sample).pluck(scoreKey).sum();
    });

    it('exports method', () => {
      expect(evenlySplit).to.be.a('function');
    });

    it('generates an array', () => {
      expect(split()).to.be.an('array');
    });

    it('splits sample into approximately even partitions', () => {
      let partitions = split();
      let expPartitionScore = sampleTotalScore / noOfPartitions;
      let expPartitionRange = [0.8 * expPartitionScore, 1.2 * expPartitionScore];

      partitions.map(({score}) => {
        expect(score).to.be.within(...expPartitionRange);
      });
    });

    it('preserves all items in the split', () => {
      let partitionedItems = split().reduce((allItems, partition) => {
        return allItems.concat(partition.items);
      }, []);

      expect(partitionedItems).members(sample);
    });
  });
});
