'use strict';

const _ = require('lodash');

/* Given a list of items, divides into n partitions that are approximately equal sizing */
const evenlySplit = (items, scoreKey, n) => {
  return _
    .chain(items)
    .sortBy(`-${scoreKey}`)
    .reduce((groups, item) => {
      groups[0].score += item[scoreKey];
      groups[0].items.push(item);

      return _.sortBy(groups, 'score');
    }, _.times(n, () => { return { score: 0, items: [] } }))
    .value();
};

/* Generates two new dimensions that represent the given dimension split by the given
 * ratio in the direction that produces maximally square boxes. */
const splitDimensions = ([x, y, w, h], ratio) => {
  if (w > h) {
    let leftSplitWidth = Math.floor(w * ratio);
    return [
      [x, y, leftSplitWidth, h],
      [x + leftSplitWidth, y, (w - leftSplitWidth), h],
    ];
  } else {
    let topSplitHeight = Math.floor(h * ratio);
    return [
      [x, y, w, topSplitHeight],
      [x, y + topSplitHeight, w, (h - topSplitHeight)],
    ];
  }
};


const balance = (rootFrame, [x, y, w, h]) => {
  if (rootFrame.entries.length === 1) {
    return [{
      label: rootFrame.entries[0].path,
      score: rootFrame.score,
      x, y, w, h,
    }];
  }

  return _
    .chain(evenlySplit(rootFrame.entries, 'score', 2))
    .reduce(function(rects, {score, items}) {
      let dims = splitDimensions(this.totalDim, score / this.totalScore);

      this.totalScore -= score;  // remove this item from the available space
      this.totalDim = dims[1];  // set remaining space to dimensions from after split

      return [...rects, balance({ score, entries: items }, dims[0])];

    }, [], {totalDim: [x, y, w, h], totalScore: rootFrame.score})
    .flatten()
    .value()
};

module.exports = { balance };
