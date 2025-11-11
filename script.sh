#!/usr/bin/env bash
set -euo pipefail

echo "📦 Creating speed-upload-server project..."

mkdir -p speed-upload-server/server
cd speed-upload-server

# .env.example
cat > .env.example <<EOF
API_KEY=your-secret-api-key
MAX_FILE_BYTES=104857600
ADMIN_EMAIL=admin@example.com
EOF

# Caddyfile
cat > Caddyfile <<EOF
your.domain.example.com {
  encode gzip
  route /upload* {
    reverse_proxy server:3000
  }
  route /api/* {
    reverse_proxy server:3000
  }
  route /* {
    reverse_proxy server:3000
  }
  header {
    Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    Referrer-Policy "no-referrer-when-downgrade"
    X-Content-Type-Options "nosniff"
    X-Frame-Options "DENY"
    X-XSS-Protection "1; mode=block"
  }
}
EOF

# deploy.sh
cat > deploy.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "🚀 Starting deployment..."
if [ ! -f .env ]; then
  echo "❌ .env file not found. Copy .env.example to .env and configure it."
  exit 1
fi
docker compose pull || true
docker compose build --pull --no-cache server
docker compose up -d --remove-orphans
echo "✅ Deployment complete."
EOF
chmod +x deploy.sh

# docker-compose.yml
cat > docker-compose.yml <<EOF
version: "3.8"
services:
  caddy:
    image: caddy:2.7.4
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      - ACME_AGREE=true
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config

  server:
    build:
      context: ./server
      dockerfile: Dockerfile
    container_name: speed-upload-server
    restart: unless-stopped
    environment:
      - PORT=3000
      - MAX_FILE_BYTES=\${MAX_FILE_BYTES:-104857600}
      - API_KEY=\${API_KEY:-}
    expose:
      - "3000"
    networks:
      - internal

volumes:
  caddy_data:
  caddy_config:

networks:
  internal:
    driver: bridge
EOF

# README.md
cat > README.md <<EOF
# 📡 Speed Upload Server (with Caddy TLS)

A secure, Dockerized upload timing server for measuring client-to-server upload performance...

[See full README content in previous response]
EOF

# server files
cd server

# Dockerfile
cat > Dockerfile <<EOF
FROM node:18-alpine
WORKDIR /usr/src/app
COPY package.json package-lock.json ./
RUN npm ci --only=production
COPY index.js ./
EXPOSE 3000
ENV NODE_ENV=production
CMD ["node", "index.js"]
EOF

# package.json
cat > package.json <<EOF
{
  "name": "speed-upload-server",
  "version": "0.1.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "multer": "^1.4.5-lts.1",
    "helmet": "^6.0.1",
    "express-rate-limit": "^6.7.0",
    "morgan": "^1.10.0"
  }
}
EOF

# index.js
cat > index.js <<'EOF'
'use strict';
const express = require('express');
const multer = require('multer');
const morgan = require('morgan');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const app = express();
app.use(helmet());
app.use(morgan('combined'));
const limiter = rateLimit({ windowMs: 60000, max: 60, standardHeaders: true, legacyHeaders: false });
app.use(limiter);
const MAX_BYTES = parseInt(process.env.MAX_FILE_BYTES || '104857600', 10);
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: MAX_BYTES } });
function requireApiKey(req, res, next) {
  const configured = process.env.API_KEY;
  if (!configured) return next();
  const key = req.header('x-api-key') || req.query.api_key || (req.headers.authorization && req.headers.authorization.replace(/^Bearer\s+/i, ''));
  if (!key || key !== configured) return res.status(401).json({ ok:false, error: 'Unauthorized' });
  next();
}
app.post('/upload', requireApiKey, upload.single('file'), (req, res) => {
  const serverReceivedAt = Date.now();
  const file = req.file || null;
  const serverProcessedAt = Date.now();
  res.json({
    ok: true,
    message: 'received',
    filename: file?.originalname || null,
    size: file?.size || 0,
    serverReceivedAt,
    serverProcessedAt,
    serverProcessingMs: serverProcessedAt - serverReceivedAt
  });
});
app.get('/api/health', (req,res) => res.json({ ok:true, ts: Date.now() }));
app.get('/', (req, res) => res.send('Upload timing server. POST /upload with multipart/form-data field "file".'));
const port = parseInt(process.env.PORT || '3000', 10);
app.listen(port, '0.0.0.0', () => {
  console.log(`Upload server listening on port ${port} (MAX_FILE_BYTES=${MAX_BYTES})`);
});
EOF

echo "✅ Project structure created in speed-upload-server/"
