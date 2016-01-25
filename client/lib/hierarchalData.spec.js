'use strict';

const _ = require('lodash');
const {generateHierarchy} = require('./hierarchalData.js')

describe('HierarchalData', () => {
  describe('.generateHierarchy', () => {
    const generate = (valueMapper) => {
      return generateHierarchy({
        'non_hierarchal_key': 3,
        'parent/a': 2,
        'parent/b': 1,
        'parent/child/a': 3,
        'parent/child/b': 2,
      }, {separator, valueMapper});
    };

    let separator = '/';

    it('exports function', () => {
      expect(generateHierarchy).to.be.a('function');
    });

    it('ignores non-hierarchal keys', () => {
      expect(_.get(generate(), 'items.non_hierarchal_key')).to.be.undefined;
    });

    it('nests nodes under parent', () => {
      expect(_.get(generate(), 'items.parent.items.child')).to.be.an('object');
    })

    it('aggregates values for parents', () => {
      expect(_.get(generate(), 'items.parent.value')).to.equal(8);
      expect(_.get(generate(), 'items.parent.items.child.value')).to.equal(5);
    });

    describe('with valueMapper', () => {
      let atLeastOneSquared = (value) => { if (value > 1) return value * value };
      let generateWithMap = () => { return generate(atLeastOneSquared) };

      it('filters values that modifier translates to 0', () => {
        expect(_.get(generateWithMap(), 'items.parent.items.b'))
          .to.be.undefined;
      });

      it('translates values via the modifier', () => {
        expect(_.get(generateWithMap(), 'items.parent.items.a.value'))
          .to.equal(4);
      });
    });
  });
});
