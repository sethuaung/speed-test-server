#!/usr/bin/env bash
set -euo pipefail

echo "📦 Creating vercel-api-logger project..."

mkdir -p vercel-api-logger/api
cd vercel-api-logger

# .env.example
cat > .env.example <<EOF
API_KEY=your-secret-api-key
JWT_SECRET=your-jwt-secret
EOF

# package.json
cat > package.json <<EOF
{
  "name": "vercel-api-logger",
  "version": "1.0.0",
  "engines": {
    "node": "22.x"
  },
  "dependencies": {
    "jsonwebtoken": "^9.0.2"
  }
}
EOF

# vercel.json
cat > vercel.json <<EOF
{
  "version": 2,
  "functions": {
    "api/log.js": {
      "memory": 512,
      "maxDuration": 10
    }
  },
  "routes": [
    { "src": "/log", "dest": "/api/log.js" }
  ]
}
EOF

# api/log.js
cat > api/log.js <<'EOF'
import jwt from 'jsonwebtoken';

export default async function handler(req, res) {
  const apiKey = process.env.API_KEY;
  const jwtSecret = process.env.JWT_SECRET;

  const clientKey =
    req.headers['x-api-key'] ||
    req.query.api_key ||
    (req.headers.authorization && req.headers.authorization.replace(/^Bearer\s+/i, ''));

  if (apiKey && clientKey === apiKey) {
    // API key auth passed
  } else if (jwtSecret && clientKey) {
    try {
      const decoded = jwt.verify(clientKey, jwtSecret);
      console.log('Authenticated user:', decoded);
    } catch (err) {
      return res.status(403).json({ ok: false, error: 'Invalid token' });
    }
  } else {
    return res.status(401).json({ ok: false, error: 'Unauthorized' });
  }

  if (req.method !== 'POST') return res.status(405).end('Method not allowed');

  const data = req.body;
  console.log('Received speed test result:', data);
  res.status(200).json({ ok: true, received: true });
}
EOF

# README.md
cat > README.md <<EOF
# 📡 Vercel API Logger with Auth

Secure logging endpoint for speed test results. Supports API key or JWT authentication.

## 🔐 Auth Options

- API key: send \`x-api-key\` header
- JWT: send \`Authorization: Bearer <token>\`

## 🧪 Example Request

\`\`\`bash
curl -X POST https://your-vercel-project.vercel.app/log \\
  -H "Content-Type: application/json" \\
  -H "x-api-key: your-secret-api-key" \\
  -d '{"timestamp":"...","region":"...","tests":[...]}'
\`\`\`

## 🚀 Deploy

1. Push to GitHub
2. Import into Vercel
3. Add \`API_KEY\` and \`JWT_SECRET\` to environment variables
EOF

echo "✅ Project scaffolded in vercel-api-logger/"
