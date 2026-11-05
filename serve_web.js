const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8085;
const WEB_DIR = path.join(__dirname, 'build', 'web');
const ASSETS_DIR = path.join(__dirname, 'assets');
const EXPORTS_DIR = path.join(__dirname, 'backend', 'exports');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.mp4': 'video/mp4',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2'
};

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, DELETE');
  res.setHeader('Access-Control-Allow-Headers', '*');
  res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  res.setHeader('Cross-Origin-Embedder-Policy', 'credentialless');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  let pathname = decodeURIComponent(parsedUrl.pathname);

  // Forward /api requests to backend on port 5000
  if (pathname.startsWith('/api')) {
    const proxyReq = http.request({
      hostname: '127.0.0.1',
      port: 5000,
      path: req.url,
      method: req.method,
      headers: {
        ...req.headers,
        host: '127.0.0.1:5000'
      }
    }, (proxyRes) => {
      res.writeHead(proxyRes.statusCode, proxyRes.headers);
      proxyRes.pipe(res);
    });

    proxyReq.on('error', (err) => {
      console.error('API proxy error:', err.message);
      res.writeHead(502, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Backend unreachable on port 5000' }));
    });

    req.pipe(proxyReq);
    return;
  }

  // Handle exports static files
  if (pathname.startsWith('/exports/')) {
    const rel = pathname.replace('/exports/', '');
    const filePath = path.join(EXPORTS_DIR, rel);
    if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
      return serveStaticFile(filePath, res, req);
    }
  }

  // Handle assets static files
  if (pathname.startsWith('/assets/')) {
    const rel = pathname.replace(/^\/assets\//, '').replace(/^assets\//, '');
    const directPath = path.join(ASSETS_DIR, rel);
    if (fs.existsSync(directPath) && fs.statSync(directPath).isFile()) {
      return serveStaticFile(directPath, res, req);
    }
    const webAssetPath = path.join(WEB_DIR, pathname);
    if (fs.existsSync(webAssetPath) && fs.statSync(webAssetPath).isFile()) {
      return serveStaticFile(webAssetPath, res, req);
    }
  }

  // Serve build/web static files
  let targetPath = path.join(WEB_DIR, pathname === '/' ? 'index.html' : pathname);
  if (!fs.existsSync(targetPath) || !fs.statSync(targetPath).isFile()) {
    // SPA fallback: return index.html for unknown frontend routes
    targetPath = path.join(WEB_DIR, 'index.html');
  }

  serveStaticFile(targetPath, res, req);
});

function serveStaticFile(filePath, res, req) {
  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';
  const stat = fs.statSync(filePath);

  // Range support for videos
  if (req.headers.range && ext === '.mp4') {
    const range = req.headers.range;
    const parts = range.replace(/bytes=/, "").split("-");
    const start = parseInt(parts[0], 10);
    const end = parts[1] ? parseInt(parts[1], 10) : stat.size - 1;
    const chunksize = (end - start) + 1;
    const file = fs.createReadStream(filePath, { start, end });

    res.writeHead(206, {
      'Content-Range': `bytes ${start}-${end}/${stat.size}`,
      'Accept-Ranges': 'bytes',
      'Content-Length': chunksize,
      'Content-Type': contentType,
    });
    file.pipe(res);
    return;
  }

  res.writeHead(200, {
    'Content-Type': contentType,
    'Content-Length': stat.size,
    'Cache-Control': ext === '.html' ? 'no-cache' : 'public, max-age=3600',
    'Accept-Ranges': 'bytes'
  });

  fs.createReadStream(filePath).pipe(res);
}

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[Web Server] Flutter Web app running at http://localhost:${PORT}`);
  console.log(`[Web Server] Serving production bundle from: ${WEB_DIR}`);
});
