#!/usr/bin/env bash
set -euo pipefail

echo "📦 Creating Vercel-ready upload server..."

mkdir -p speed-upload-server-vercel/api
mkdir -p speed-upload-server-vercel/public
cd speed-upload-server-vercel

# package.json
cat > package.json <<EOF
{
  "name": "speed-upload-server-vercel",
  "version": "1.0.0",
  "engines": {
    "node": "22.x"
  },
  "dependencies": {
    "formidable": "^3.7.0"
  }
}
EOF

# vercel.json
cat > vercel.json <<EOF
{
  "version": 2,
  "functions": {
    "api/upload.js": {
      "memory": 512,
      "maxDuration": 10
    }
  },
  "routes": [
    { "src": "/upload", "dest": "/api/upload.js" }
  ]
}
EOF

# api/upload.js
cat > api/upload.js <<'EOF'
export const config = {
  api: {
    bodyParser: false
  }
};

import formidable from 'formidable';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.status(405).json({ ok: false, error: 'Method not allowed' });
    return;
  }

  const serverReceivedAt = Date.now();

  const form = formidable({ maxFileSize: 100 * 1024 * 1024 });

  form.parse(req, (err, fields, files) => {
    const serverProcessedAt = Date.now();

    if (err) {
      res.status(400).json({ ok: false, error: err.message });
      return;
    }

    const file = files.file;
    const size = file?.size || 0;
    const filename = file?.originalFilename || null;

    res.status(200).json({
      ok: true,
      filename,
      size,
      serverReceivedAt,
      serverProcessedAt,
      serverProcessingMs: serverProcessedAt - serverReceivedAt
    });
  });
}
EOF

# public/index.html (optional UI placeholder)
cat > public/index.html <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>Speed Upload Server</title>
</head>
<body>
  <h1>Upload Timing Server</h1>
  <p>POST a file to <code>/upload</code> using multipart/form-data.</p>
</body>
</html>
EOF

# README.md
cat > README.md <<EOF
# 📡 Speed Upload Server (Vercel)

A serverless upload timing endpoint for measuring client-to-server performance. Compatible with Node.js 22.x and Vercel Functions.

## 🚀 Usage

POST a file to:

\`\`\`
https://your-vercel-project.vercel.app/upload
\`\`\`

Form field: \`file\` (multipart/form-data)

Returns:

\`\`\`json
{
  "ok": true,
  "filename": "upload.bin",
  "size": 1048576,
  "serverReceivedAt": 1699999999999,
  "serverProcessedAt": 1699999999999,
  "serverProcessingMs": 12
}
\`\`\`

## 🧪 Local Dev

Install dependencies:

\`\`\`bash
npm install
\`\`\`

Run locally (with Vercel CLI):

\`\`\`bash
vercel dev
\`\`\`

## 📦 Deploy

Push to GitHub and import into Vercel. Set root directory to \`speed-upload-server-vercel\`.

## 🔐 Notes

- Max upload size: 100MB
- No authentication included — add API key or JWT if needed
EOF

echo "✅ Vercel-ready project created in speed-upload-server-vercel/"
