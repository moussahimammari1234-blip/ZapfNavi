const fs = require('fs');
let html = fs.readFileSync('index.html', 'utf8');
html = html.replace(/\.\.\/assets\//g, 'assets/');
fs.writeFileSync('index.html', html);
console.log('Fixed paths');
