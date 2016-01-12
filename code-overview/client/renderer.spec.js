'use strict';

const Renderer = require('./renderer.js');
const dataFixture = require('../fixtures/rendererInputFixture.json');
const outputFixture = require('../fixtures/rendererOutputFixture.json');

describe('Renderer', () => {
  describe('balance', () => {
    const balance = Renderer.balance;

    it('exports method', () => {
      expect(balance).to.be.a('function');
    });

    it('matches fixture', () => {
      expect(balance(dataFixture)).to.equal(outputFixture);
    });
  });
});
