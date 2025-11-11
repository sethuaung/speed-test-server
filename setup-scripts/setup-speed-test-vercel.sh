#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="speed-test-vercel"
echo "📦 Creating full Vercel repo at ./${ROOT_DIR}"

rm -rf "${ROOT_DIR}"
mkdir -p "${ROOT_DIR}/api" "${ROOT_DIR}/public"

cd "${ROOT_DIR}"

# .env.example
cat > .env.example <<'EOF'
# Add these in Vercel project settings (Environment Variables)
API_KEY=your-secret-api-key
# Optional for JWT flows
JWT_SECRET=your-jwt-secret
EOF

# package.json (for any server-side deps)
cat > package.json <<'EOF'
{
  "name": "speed-test-vercel",
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
cat > vercel.json <<'EOF'
{
  "version": 2,
  "functions": {
    "api/log.js": {
      "memory": 512,
      "maxDuration": 10
    }
  },
  "routes": [
    { "src": "/log", "dest": "/api/log.js" },
    { "src": "/", "dest": "/index.html" }
  ]
}
EOF

# api/log.js - accepts API key (x-api-key) or JWT (Authorization: Bearer)
cat > api/log.js <<'EOF'
import jwt from 'jsonwebtoken';

export default async function handler(req, res) {
  const apiKey = process.env.API_KEY;
  const jwtSecret = process.env.JWT_SECRET;

  // Extract token/key from x-api-key, query, or Authorization Bearer
  const clientToken =
    req.headers['x-api-key'] ||
    req.query.api_key ||
    (req.headers.authorization && req.headers.authorization.replace(/^Bearer\s+/i, ''));

  // Authenticate: API key OR JWT
  if (apiKey && clientToken === apiKey) {
    // API key OK
  } else if (jwtSecret && clientToken) {
    try {
      jwt.verify(clientToken, jwtSecret);
    } catch (err) {
      return res.status(403).json({ ok: false, error: 'Invalid token' });
    }
  } else {
    return res.status(401).json({ ok: false, error: 'Unauthorized' });
  }

  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ ok: false, error: 'Method not allowed' });
  }

  try {
    const data = req.body;
    // Simple console log for demo. Replace with DB or object storage as needed.
    console.log('Speed test log received:', JSON.stringify(data));
    return res.status(200).json({ ok: true, received: true });
  } catch (err) {
    console.error('Log handler error:', err);
    return res.status(500).json({ ok: false, error: 'Server error' });
  }
}
EOF

# public/index.html - full frontend: region detection, multi-region tests, chart, JSON export, auto-submit with x-api-key
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
    .card { max-width: 960px; margin: auto; background: #111827; padding: 2rem; border-radius: 1rem; box-shadow: 0 0 20px rgba(0,0,0,0.3); }
    h1 { font-size: 1.5rem; margin-bottom: 1rem; color: #60a5fa; }
    button { background: #06b6d4; color: #04263a; border: none; padding: 0.5rem 0.9rem; border-radius: 0.5rem; cursor: pointer; font-weight: bold; margin-right: 0.5rem; }
    canvas { margin-top: 1rem; background: #0b1220; border-radius: 0.5rem; width:100%; }
    .metrics { display: flex; gap: 1rem; margin-top: 1rem; flex-wrap: wrap; }
    .metric { flex: 1 1 120px; background: #0b1220; padding: 0.75rem; border-radius: 0.5rem; text-align: center; }
    .metric .label { font-size: 0.80rem; color: #94a3b8; }
    .metric .value { font-size: 1.1rem; font-weight: bold; margin-top: 0.25rem; }
    pre { background: #0b1220; padding: 1rem; border-radius: 0.5rem; font-size: 0.9rem; overflow-x: auto; margin-top: 1rem; white-space: pre-wrap; word-break: break-word; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Speed Test Logger</h1>
    <div style="display:flex;gap:0.5rem;flex-wrap:wrap;">
      <button id="multiRegionBtn">Run Multi-Region Test</button>
      <button id="exportBtn">Export JSON</button>
      <label style="display:flex;align-items:center;gap:0.5rem;margin-left:auto;">
        <span style="color:#94a3b8;font-size:0.9rem">API Key</span>
        <input id="apiKey" type="password" placeholder="x-api-key" style="background:#081023;border:none;color:#e6eef8;padding:0.35rem 0.5rem;border-radius:0.35rem;">
      </label>
    </div>

    <div id="regionInfo" style="margin-top:1rem;color:#94a3b8">Detecting region…</div>

    <div class="metrics">
      <div class="metric"><div class="label">US</div><div id="usVal" class="value">—</div></div>
      <div class="metric"><div class="label">Europe</div><div id="euVal" class="value">—</div></div>
      <div class="metric"><div class="label">Asia</div><div id="asiaVal" class="value">—</div></div>
    </div>

    <canvas id="chart" height="180"></canvas>
    <pre id="output">No test run yet.</pre>
  </div>

  <script>
    // Config: test URLs (CORS required). Change or add regions as needed.
    const TEST_URLS = {
      US: 'https://speedtest.tele2.net/10MB.zip',
      Europe: 'https://speed.hetzner.de/10MB.bin',
      Asia: 'https://sgp-ping.vultr.com/10MB.bin'
    };

    const multiRegionBtn = document.getElementById('multiRegionBtn');
    const exportBtn = document.getElementById('exportBtn');
    const apiKeyInput = document.getElementById('apiKey');
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
          { label: 'US', data: [], borderColor: '#60a5fa', backgroundColor: 'rgba(96,165,250,0.08)', tension: 0.3 },
          { label: 'Europe', data: [], borderColor: '#34d399', backgroundColor: 'rgba(52,211,153,0.08)', tension: 0.3 },
          { label: 'Asia', data: [], borderColor: '#f97316', backgroundColor: 'rgba(249,115,22,0.08)', tension: 0.3 }
        ]
      },
      options: {
        animation: false,
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: { beginAtZero: true },
          x: { display: false }
        },
        plugins: {
          legend: { labels: { color: '#cbd5e1' } }
        }
      }
    });

    const testResults = {
      timestamp: null,
      clientRegion: null,
      tests: []
    };

    async function detectRegion() {
      try {
        const res = await fetch('https://ipapi.co/json/');
        const data = await res.json();
        const region = \`\${data.city}, \${data.region}, \${data.country_name}\`;
        regionInfo.textContent = 'Detected Region: ' + region;
        testResults.clientRegion = region;
      } catch (err) {
        regionInfo.textContent = 'Region detection failed';
        testResults.clientRegion = null;
      }
    }

    async function streamDownload(url, label, datasetIndex, displayEl) {
      const start = performance.now();
      let received = 0;
      chart.data.datasets[datasetIndex].data = [];

      try {
        const res = await fetch(url, { cache: 'no-store' });
        if (!res.ok || !res.body) throw new Error('Fetch failed or stream not available: ' + res.status);
        const reader = res.body.getReader();
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          received += value.length;
          const elapsed = (performance.now() - start) / 1000;
          const bps = (received * 8) / Math.max(elapsed, 0.001);
          chart.data.labels.push('');
          chart.data.datasets[datasetIndex].data.push(bps);
          chart.update('none');
        }
        const totalTime = (performance.now() - start) / 1000;
        const totalBps = (received * 8) / Math.max(totalTime, 0.001);
        displayEl.textContent = \`\${(totalBps / 1e6).toFixed(2)} Mbps\`;
        testResults.tests.push({ region: label, url, bytes: received, seconds: totalTime, bps: totalBps, mbps: (totalBps / 1e6) });
        return { ok: true, label, bytes: received, seconds: totalTime, mbps: (totalBps / 1e6) };
      } catch (err) {
        displayEl.textContent = 'Failed';
        return { ok: false, label, error: err.message };
      }
    }

    async function submitToBackend() {
      const apiKey = apiKeyInput.value.trim();
      if (!apiKey) {
        output.textContent += '\\n⚠️ No API key provided. Skipping submit to /log.';
        return;
      }

      try {
        const res = await fetch('/log', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey
          },
          body: JSON.stringify(testResults)
        });
        if (!res.ok) {
          const text = await res.text();
          output.textContent += '\\n❌ Backend responded with status ' + res.status + ': ' + text;
          return;
        }
        const json = await res.json();
        output.textContent += '\\n✅ Results submitted to /log.';
      } catch (err) {
        output.textContent += '\\n❌ Submit failed: ' + err.message;
      }
    }

    function exportResults() {
      const blob = new Blob([JSON.stringify(testResults, null, 2)], { type: 'application/json' });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = 'speed-test-results.json';
      document.body.appendChild(a);
      a.click();
      a.remove();
    }

    multiRegionBtn.addEventListener('click', async () => {
      output.textContent = 'Running multi-region test...';
      chart.data.labels = [];
      chart.data.datasets.forEach(ds => ds.data = []);
      chart.update();
      testResults.tests = [];
      testResults.timestamp = new Date().toISOString();

      // Run regions sequentially to avoid saturating the network and to provide clear chart overlays
      const results = [];
      results.push(await streamDownload(TEST_URLS.US, 'US', 0, usVal));
      results.push(await streamDownload(TEST_URLS.Europe, 'Europe', 1, euVal));
      results.push(await streamDownload(TEST_URLS.Asia, 'Asia', 2, asiaVal));

      output.textContent = results.map(r => r.ok ? \`\${r.label}: \${r.mbps.toFixed(2)} Mbps\` : \`\${r.label} error: \${r.error}\`).join('\\n');

      // Auto-submit if API key provided
      await submitToBackend();
    });

    exportBtn.addEventListener('click', exportResults);

    // Init
    detectRegion();
  </script>
</body>
</html>
EOF

# README.md
cat > README.md <<'EOF'
# Speed-Test-Server

- Containing the authenticated logging API and the multi-region speed-test frontend (auto-region detection, Chart.js, JSON export, and auto-submit with x-api-key).
- The project uses Node 22.x for Vercel functions.

---

Full Vercel-ready repo combining:
- A secured logging API at /log (API key or JWT)
- A multi-region client-side speed-test UI served from /index.html

Quick start:
1. Copy .env.example values to Vercel Environment Variables (API_KEY, JWT_SECRET)
2. Commit & push this repo to GitHub
3. Import project in Vercel and deploy

Frontend features:
- Automatic region detection via ipapi.co
- Multi-region streaming download tests (US, Europe, Asia)
- Live Chart.js overlays
- JSON export and automatic submit to /log using x-api-key


**Here’s a multi-region download speed comparison chart** showing simulated results from three public test servers in the US, Europe, and Asia.

---

### 🌍 Download Speed Comparison by Region

This chart compares download speeds (in Mbps) across five test iterations from:

- **US**: speedtest.tele2.net (10MB.zip)
- **Europe**: speed.hetzner.de (10MB.bin)
- **Asia**: sgp-ping.vultr.com (10MB.bin)

Each line represents a region’s performance over time:

📊 Download Speed (Mbps) vs. Test Iteration
🟦 US  🟩 Europe  🟥 Asia

⬇️ Click the image above to download or view it in full resolution.

---

### 📈 Simulated Results

| Iteration | US (Mbps) | Europe (Mbps) | Asia (Mbps) |
|-----------|-----------|----------------|-------------|
| 1         | 12.5      | 18.1           | 9.4         |
| 2         | 13.2      | 17.8           | 9.6         |
| 3         | 12.8      | 18.5           | 9.2         |
| 4         | 13.0      | 18.2           | 9.5         |
| 5         | 12.9      | 18.0           | 9.3         |

Europe consistently outperforms the other regions in this simulation, while Asia shows slightly lower throughput—likely due to longer round-trip latency or peering differences.

---

Backend features:
- /log accepts POST JSON
- Auth by x-api-key header or Bearer JWT (JWT_SECRET must be set)
- Console logs received payload (replace with DB or storage in production)

Notes:
- Ensure test URLs used by the client are CORS-enabled
- For larger scale logging add persistence (Postgres, S3, etc.) and proper rate-limiting

---

EOF

echo "✅ Scaffold complete in ./${ROOT_DIR}"
echo ""
echo "Next steps:"
echo "  1) cd ${ROOT_DIR}"
echo "  2) npm install"
echo "  3) push to GitHub and import to Vercel"
echo "  4) Add API_KEY (and JWT_SECRET if using JWT) in Vercel Environment Variables"
