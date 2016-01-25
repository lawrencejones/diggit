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
const generateHierarchy = (keyValues, separator, valueMapper) => {
  if (_.isUndefined(separator))   { throw new Error('Requires separator'); }
  if (_.isUndefined(valueMapper)) { valueMapper = _.identity }

  const newFrame = (path) => { return {path, value: 0} };

  return _.chain(keyValues)
    .mapValues(valueMapper)
    .pick((value, key) => { return _.includes(key, separator) && !!value })
    .reduce((root, value, key) => {
      key.split(separator).reduce((frame, group) => {
        frame.items = frame.items || {};
        frame.items[group] = frame.items[group] || newFrame(`${frame.path}${separator}${group}`);
        frame.items[group].value += value;

        return frame.items[group];
      }, root);

      return _.set(root, 'value', root.value + value);
    }, newFrame(''))
    .set('path', separator)
    .value();
}

module.exports = {generateHierarchy};
