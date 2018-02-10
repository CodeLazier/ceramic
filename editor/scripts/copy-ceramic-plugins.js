#!/usr/bin/env node

const fs = require('fs-extra');
const path = require('path');
const colors = require('colors');

const srcDir = path.join(__dirname, '../../plugins');
const dstDir = path.join(__dirname, '../vendor/ceramic-plugins');

fs.removeSync(dstDir);
fs.copy(srcDir, dstDir, function(err) {
    if (err) throw err;
    console.log('✔'.green + ' Ceramic plugins copied');
});
