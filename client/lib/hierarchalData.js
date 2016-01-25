'use strict';

const _ = require('lodash');

/* Generates nested hierarchal data from flat key value pairs. Assumes that each key
 * can be split into hierarchies using a given separator, and that each level of the
 * hierarchy is valued as the sum of it's children.
 *
 * {
 *   'parent/a': 1,
 *   'parent/b': 2,
 * }
 *
 * can be grouped into
 *
 * {
 *   "path": "/",
 *   "value": 3,
 *   "items": {
 *     "parent": {
 *       "path": "/parent",
 *       "value": 3,
 *       "items": {
 *         "a": {
 *           "path": "/parent/a",
 *           "value": 1
 *         },
 *         "b": {
 *           "path": "/parent/b",
 *           "value": 2
 *         }
 *       }
 *     }
 *   }
 * }
 */
const generateHierarchy = (keyValues, userOptions) => {
  let options = _.defaults(userOptions, {
    separator: '/',               // token with with to split keys
    valueKey: 'value',            // key to use to store the 'value' of each node
    valueMapper: _.identity,      // map and filter for values
  });

  const newFrame = (path) => { return _.set({path}, options.valueKey, 0) };

  return _.chain(keyValues)
    .mapValues(options.valueMapper)
    .pick((value, key) => { return _.includes(key, options.separator) && !!value })
    .reduce((root, value, key) => {
      key.split(options.separator).reduce((frame, group) => {
        frame.items = frame.items || {};
        frame.items[group] = frame.items[group] || newFrame(`${frame.path}${options.separator}${group}`);
        frame.items[group][options.valueKey] += value;

        return frame.items[group];
      }, root);

      return _.set(root, options.valueKey, root[options.valueKey] + value);
    }, newFrame(''))
    .set('path', options.separator)
    .value();
}

module.exports = {generateHierarchy};
