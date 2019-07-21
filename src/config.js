'use strict';

const winston = require('winston');
const config_module = function(){

    let config = {
        STAGES: ['local', 'dev', 'test', 'prod']
        , ENVS: ['dev', 'test', 'prod']
        , WINSTON_CONFIG: {
            level: 'debug',
            format: winston.format.combine(
                winston.format.splat(),
                winston.format.timestamp(),
                winston.format.printf(info => {
                    return `${info.timestamp} ${info.level}: ${info.message}`;
                })
            ),
            transports: [new winston.transports.Console()]
        }

    };

    const variables = [
        'TENANT'
        , 'STAGE'
        , 'ENV'
        , 'DB_ENDPOINT'
        , 'DB_API_REGION'
        , 'DB_API_VERSION'
        , 'ENTITIES'
        , 'DB_API_ACCESS_KEY_ID'
        , 'DB_API_ACCESS_KEY'
        , 'TEST_ITERATIONS'
    ];

    const defaults = [
        null
        , null // 'local'
        , null // 'dev'
        , null // 'http://localhost:8000'
        , 'eu-west-1'
        , '2012-08-10'
        , null
        , null
        , null
        , 6
    ];

    for(let i in variables){

        let variable = variables[i];
        let defaultValue = defaults[i];

        if ( process.env[variable] ){

            let value = null;
            if( variable === 'ENTITIES' ){
                let list = process.env[variable];
                value = list.split(',');
            }
            else {
                value = process.env[variable];
            }

            let rangeVariable = variable + 'S';
            if( config[rangeVariable] ){
                let range = config[rangeVariable];
                if( -1 === range.indexOf(value) )
                    throw new Error('!!! variable: ' + variable + ' has an invalid value: ' + value + ' !!!');
            }
            config[variable] = value;
        }
        else
            config[variable] = defaultValue;

    }
    console.log(config)
    return config;
    
}();

module.exports = config_module;
