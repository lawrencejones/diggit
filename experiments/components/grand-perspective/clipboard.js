'use strict';
/* globals document */

const _ = require('lodash');

/* Browsers place restrictions on how javascript can access the system clipboard,
 * so some slight of hand is required to enable a copy function.
 *
 * We must create a <textarea> that is added to the document only momentarily, and
 * from that select and copy the inner text.
 *
 * See http://stackoverflow.com/a/30810322 for context. */
const copy = (text) => {
  let textArea = document.createElement('textarea');

  /* Place the <textarea> at the top left of the screen, with as minimal
   * visibility as we can achieve while still technically rendering it. */
  _.extend(textArea.style, {
    position: 'fixed',
    top: 0, left: 0,
    width: '2em', height: '2em',
    padding: 0,
    border: 'none',
    outline: 'none',
    boxShadow: 'none',
    background: 'transparent',
  });

  textArea.value = text;

  try {
    document.body.appendChild(textArea);
    textArea.select();
    document.execCommand('copy');
  } catch (err) {
    console.error('Clipboard copy failed');
  }

  document.body.removeChild(textArea);
};

module.exports = {copy}
