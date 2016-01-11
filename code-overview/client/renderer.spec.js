'use strict';

const Renderer = require('./renderer.js');

describe('Renderer', () => {
  it('loads module', () => {
    expect(Renderer).to.equal('DUMMY');
  });
});
