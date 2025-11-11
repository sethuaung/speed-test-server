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

