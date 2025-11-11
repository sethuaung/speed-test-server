#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Creating full speed-test-vercel repo..."

mkdir -p speed-test-vercel/api
mkdir -p speed-test-vercel/public
cd speed-test-vercel

# .env.example
cat > .env.example <<EOF
API_KEY=your-secret-api-key
EOF

# package.json
cat > package.json <<EOF
{
  "name": "speed-test-vercel",
  "version": "1.0.0",
  "engines": {
    "node": "22.x"
  },
  "dependencies": {
    "formidable": "^3.7.0",
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
    },
    "api/upload.js": {
      "memory": 512,
      "maxDuration": 10
    }
  },
  "routes": [
    { "src": "/upload", "dest": "/api/upload.js" },
    { "src": "/log", "dest": "/api/log.js" }
  ]
}
EOF

# api/upload.js
cat > api/upload.js <<'EOF'
export const config = {
  api: { bodyParser: false }
};

import formidable from 'formidable';

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ ok: false, error: 'Method not allowed' });

  const serverReceivedAt = Date.now();
  const form = formidable({ maxFileSize: 100 * 1024 * 1024 });

  form.parse(req, (err, fields, files) => {
    const serverProcessedAt = Date.now();
    if (err) return res.status(400).json({ ok: false, error: err.message });

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

# api/log.js
cat > api/log.js <<'EOF'
import jwt from 'jsonwebtoken';

export default async function handler(req, res) {
  const apiKey = process.env.API_KEY;
  const clientKey =
    req.headers['x-api-key'] ||
    req.query.api_key ||
    (req.headers.authorization && req.headers.authorization.replace(/^Bearer\s+/i, ''));

  if (!clientKey || clientKey !== apiKey) {
    return res.status(401).json({ ok: false, error: 'Unauthorized' });
  }

  if (req.method !== 'POST') return res.status(405).end('Method not allowed');

  const data = req.body;
  console.log('Received speed test result:', data);
  res.status(200).json({ ok: true, received: true });
}
EOF

# public/index.html
cat > public/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>Speed Test Logger</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.3.0/dist/chart.umd.min.js"></script>
  <style>
    body { font-family: Inter, system-ui, sans-serif; background: #0f1724; color: #e6eef8; padding: 2rem; }
    .card { max-width: 720px; margin: auto; background: #111827; padding: 2rem; border-radius: 1rem; box-shadow: 0 0 20px rgba(0,0,0,0.3); }
    h1 { font-size: 1.5rem; margin-bottom: 1rem; color: #60a5fa; }
    button { background: #06b6d4; color: #04263a; border: none; padding: 0.6rem 1rem; border-radius: 0.5rem; cursor: pointer; font-weight: bold; margin-right: 0.5rem; }
    canvas { margin-top: 1rem; background: #0b1220; border-radius: 0.5rem; }
    .metrics { display: flex; gap: 2rem; margin-top: 1rem; }
    .metric { flex: 1; background: #0b1220; padding: 1rem; border-radius: 0.5rem; text-align: center; }
    .metric .label { font-size: 0.85rem; color: #94a3b8; }
    .metric .value { font-size: 1.2rem; font-weight: bold; margin-top: 0.5rem; }
    pre { background: #0b1220; padding: 1rem; border-radius: 0.5rem; font-size: 0.9rem; overflow-x: auto; margin-top: 1rem; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Speed Test Logger</h1>
    <button id="multiRegionBtn">Run Test</button>
    <button onclick="exportResults()">Export JSON</button>
    <div id="regionInfo" style="margin-top:1rem;color:#94a3b8">Detecting region…</div>
    <div class="metrics">
      <div class="metric"><div class="label">US</div><div id="usVal" class="value">—</div></div>
      <div class="metric"><div class="label">Europe</div><div id="euVal" class="value">—</div></div>
      <div class="metric"><div class="label">Asia</div><div id="asiaVal" class="value">—</div></div>
    </div>
    <canvas id="chart" height="160"></canvas>
    <pre id="output">No test run yet.</pre>
  </div>

  <script>
    const multiRegionBtn = document.getElementById('multiRegionBtn');
    const usVal = document.getElementById('usVal');
    const euVal = document.getElementById('euVal');
    const asiaVal = document.getElementById('asiaVal');
    const output = document.getElementById('output');
    const regionInfo = document.getElementById('regionInfo');

    const chartCtx = document.getElementById('chart').getContext('2d');
    const chart = new Chart(chartCtx, {
      type: 'line',
      data: {
        labels: [],
        datasets: [
          { label: 'US', data: [], borderColor: '#60a5fa', backgroundColor: 'rgba(96,165,250,0.1)', tension: 0.3 },
          { label: 'Europe', data: [], borderColor: '#34d399', backgroundColor: 'rgba(52,211,153,0.1)', tension: 0.3 },
          { label: 'Asia', data: [], borderColor: '#f97316', backgroundColor: 'rgba(249,115,22,0.1)', tension: 0.3 }
        ]
      },
      options: {
        animation: false,
        scales: {
          y: { beginAtZero: true },
          x: { display: false }
        }
      }
    });

    const testResults = {
      timestamp: new Date().toISOString(),
      region: null,
      tests: []
    };

    async function detectRegion() {
      try {
        const res = await fetch('https://ipapi.co/json/');
        const data = await res.json();
        const region = `${data.city}, ${data.region}, ${data.country_name}`;
        regionInfo.textContent = `Detected Region: ${region}`;
        testResults.region = region;
      } catch (err) {
        regionInfo.textContent = 'Region detection failed';
      }
    }

    async function testDownload(url, label, datasetIndex, displayEl) {
      const start = performance.now();
      let received = 0;
      chart.data.datasets[datasetIndex].data = [];

      try {
        const res = await fetch(url, { cache: 'no-store' });
        const reader = res.body.getReader();
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          received += value.length;
          const elapsed = (performance.now() - start) / 1000;
          const bps = (received * 8) / elapsed;
          chart.data.labels.push('');
          chart.data.datasets[datasetIndex].
