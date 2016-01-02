'use strict';

const remote = require('remote');
const frame = remote.getGlobal('frame');

$('body').append(`<pre>${JSON.stringify(frame, null, 2)}</pre>`);
