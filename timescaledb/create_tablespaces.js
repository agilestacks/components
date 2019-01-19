#!/usr/bin/env node

const yaml = require('js-yaml');
const fs   = require('fs');
const { Client } = require('pg')

const CONFIGFILE='/config.yml';
const client = new Client()

let doc;
let paths; 
let tablename;
 
// Get document, or throw exception on error
try {
  doc = yaml.safeLoad(fs.readFileSync(CONFIGFILE, 'utf8'));
  paths = ['db']['paths'];
  tablename = ['db']['table'];

} catch (e) {
  console.log(e);
  process.exit(111);
}

try {
  client.connect();
} catch (e) {
  console.log(e);
  process.exit(111);
}

for (let path of paths) {
  client.query(`SELECT attach_tablespace('${path}', '${tablename}', if_not_attached => true);`, (err, res) => {
    console.log(err ? err.stack : res.rows[0].message) // Hello World!
  });
}

client.end()
