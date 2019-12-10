const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const log = require('ulog');
const base64 = require('base64-img');
const {get, keyBy, pick, mapValues} = require('lodash');

const outputFilename = get(process.argv, '[2]') || 'components-meta.json';
const componentsDirectory = get(process.argv, '[3]') || '../../../components';

const FALSY_STRINGS = /^\s*(false|f|off|0|)\s*$/i;

function write(filename, value) {
    const out = fs.openSync(filename, 'w');
    fs.writeFileSync(out, JSON.stringify(value, undefined, 2));
    fs.closeSync(out);
}

function checkIcon(name, property) {
    if (!property.startsWith('http') && !property.startsWith('data:image/')) {
        throw new Error(`Invalid meta.icon of ${name} component. Must be either proper URL or Data URI`);
    }
    if (property.startsWith('http://')) {
        log.warn(`WARNING: Location of ${name} component icon is not TLS protected`);
    }
    return property.replace(/(\r\n|\n|\r)/gm, '');
}

function extract(components) {
    return keyBy(
        components.map(([name, {meta, requires = [], provides = []}, iconFilePath]) => ({
            name,
            ...pick(meta, [
                'brief', 'version', 'maturity', 'license', 'title', 'description', 'category'
            ]),
            ...mapValues(
                pick(meta, 'disabled'),
                (value) => !FALSY_STRINGS.test(value)
            ),
            ...(iconFilePath ? {icon: base64.base64Sync(iconFilePath)} : {}),
            ...(meta.icon ? {icon: checkIcon(name, meta.icon)} : {}),
            requires,
            provides
        })),
        'name');
}

function iconPath(basePath) {
    const iconPth = [
        `${basePath}/icon.svg`,
        `${basePath}/icon.png`
    ].find((pth) => fs.existsSync(pth));
    if (iconPth) {
        const {size} = fs.statSync(iconPth);
        if (size > 1024) {
            log.warn(`WARNING: Size of ${iconPth} file is greater than 1 KB. Possible performance degradation!`);
        }
    }
    return iconPth;
}

function read(components) {
    const options = {schema: yaml.FAILSAFE_SCHEMA};
    return components.map(([name, filename, iconFilePath]) => [
        name,
        yaml.safeLoad(fs.readFileSync(filename)),
        iconFilePath,
        options
    ]);
}

function scan(directory) {
    return fs.readdirSync(directory)
        .map((name) => [name, path.join(directory, name)])
        .map(([name, basePath]) => [
            name,
            path.join(basePath, 'hub-component.yaml'),
            iconPath(basePath)])
        .filter(([, filename]) => fs.existsSync(filename));
}

write(outputFilename, extract(read(scan(componentsDirectory))));
