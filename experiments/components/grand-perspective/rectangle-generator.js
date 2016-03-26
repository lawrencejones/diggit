'use strict';
/* Rendering tools for the code-overview display */

const _ = require('lodash');

/* Given a root frame of {path, score, items?}, will generate rectangles for each subframe
 * that fill the space defined as [x, y, w, h]. */
const generateFrameRectangles = (rootFrame, [x, y, w, h], drawDirectories) => {
  if (_.isUndefined(drawDirectories)) { drawDirectories = false; }

  /* Relies upon items being an array for slicing */
  if (!_.isArray(rootFrame.items)) rootFrame.items = _.values(rootFrame.items);

  if (rootFrame.items.length === 0) return [];

  if (rootFrame.items.length === 1) {
    let frame = rootFrame.items[0];
    let rects = [];

    /* Only output this rectangle if we're drawing directories, or it's not a directory */
    if (drawDirectories || !_.isObject(frame.items)) {
      rects.push({
        label: frame.path,
        score: frame.score,
        x, y, w, h,
      });
    }

    if (_.isObject(frame.items)) {
      rects = rects.concat(generateFrameRectangles({
        score: frame.score,
        items: _.values(frame.items),
      }, [x, y, w, h], drawDirectories));
    }

    return rects;
  }

  return _
    .chain(evenlySplit(rootFrame.items, 'score', 2))
    .reduce(function(rects, {score, items}) {
      let dims = splitDimensions(this.totalDim, score / this.totalScore);

      this.totalScore -= score;  // remove this item from the available space
      this.totalDim = dims[1];  // set remaining space to dimensions from after split

      return [...rects, generateFrameRectangles({ score, items }, dims[0], drawDirectories)];

    }, [], {totalDim: [x, y, w, h], totalScore: rootFrame.score})
    .flatten()
    .value()
};

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

module.exports = { generateFrameRectangles, evenlySplit, splitDimensions };
