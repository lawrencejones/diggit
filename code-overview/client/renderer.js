'use strict';

const _ = require('lodash');

const balance = (rootFrame, [x, y, w, h]) => {
  return _
    .sortBy(rootFrame.entries, (f) => { return -f.metric })
    .map((frame) => {
      console.log(frame, 100 * frame.metric / rootFrame.metric)
      return _.tap({
        label: frame.path,
        x, y,
        height: h,
        width: Math.floor((frame.metric / rootFrame.metric) * w),
      }, ({width}) => { x += width });
    })
};

module.exports = { balance };
