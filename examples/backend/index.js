'use strict';

// Load modules

const Http = require('http');
const Os = require('os');


const server = module.exports = Http.createServer((req, res) => {
  res.writeHead(200);
  res.end('Hello World\n' + Os.hostname() + '\n');
});

server.listen(3001, () => {
  console.log(`Hello server listening on port ${server.address().port}`);
});
