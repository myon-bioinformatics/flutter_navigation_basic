'use strict';

// Fixture-only HTTP server. No build tool, dependency, directory listing, or
// access to the repository outside this explicit static-file allowlist.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const files = new Set([
  'index.html', 'style.css', 'state.js', 'app.js', 'provenance.json',
  'vendor/web-ui/tokens.css', 'vendor/web-ui/base.css', 'vendor/web-ui/components.css',
]);
const types = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.json': 'application/json' };
const server = http.createServer((request, response) => {
  if (!['GET', 'HEAD'].includes(request.method)) {
    response.writeHead(405, { Allow: 'GET, HEAD' }).end();
    return;
  }
  let name;
  try {
    name = decodeURIComponent(new URL(request.url, 'http://127.0.0.1').pathname).replace(/^\//, '') || 'index.html';
  } catch {
    response.writeHead(400).end();
    return;
  }
  if (!files.has(name)) {
    response.writeHead(404).end();
    return;
  }
  fs.readFile(path.join(__dirname, name), (error, body) => {
    if (error) {
      response.writeHead(404).end();
      return;
    }
    response.writeHead(200, {
      'Content-Type': `${types[path.extname(name)]}; charset=utf-8`,
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
    });
    response.end(request.method === 'HEAD' ? undefined : body);
  });
});
server.listen(8765, '127.0.0.1', () => console.log('UI showcase fixture: http://127.0.0.1:8765'));
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => server.close());
