'use strict';

const config = require("./config");
const functions = require('@jtviegas/store-functions')(config);

exports.handler = (event, context, callback) => {

    functions.handler(event, context, callback);

}

