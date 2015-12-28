'use strict';

const remote = require('remote');
const snapshot = remote.getGlobal('snapshot');

$('body').append(`<pre>${JSON.stringify(snapshot, null, 2)}</pre>`);
