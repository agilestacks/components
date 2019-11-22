const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const {get, keyBy, pick, mapValues} = require('lodash');

const outputFilename = get(process.argv, '[2]') || 'components-meta.json';
const componentsDirectory = get(process.argv, '[3]') || '../../../components';

const FALSY_STRINGS = /^\s*(false|f|off|0|)\s*$/i;

function write(filename, value) {
    const out = fs.openSync(filename, 'w');
    fs.writeFileSync(out, JSON.stringify(value, undefined, 2));
    fs.closeSync(out);
}

function extract(components) {
    return keyBy(
        components.map(([name, {meta, requires = [], provides = []}]) => ({
            name,
            ...pick(meta, [
                'brief', 'version', 'maturity', 'license', 'title', 'description', 'category'
            ]),
            ...mapValues(
                pick(meta, 'disabled'),
                value => !FALSY_STRINGS.test(value)
            ),
            requires,
            provides
        })),
        'name');
}

function read(components) {
    const options = {schema: yaml.FAILSAFE_SCHEMA};
    return components.map(([name, filename]) => [name, yaml.safeLoad(fs.readFileSync(filename), options)]);
}

function scan(directory) {
    return fs.readdirSync(directory)
        .map((name) => [name, path.join(directory, name, 'hub-component.yaml')])
        .filter(([, filename]) => fs.existsSync(filename));
}

write(outputFilename, extract(read(scan(componentsDirectory))));
