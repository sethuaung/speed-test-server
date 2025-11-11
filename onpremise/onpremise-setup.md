

---

# 📡 Speed Upload Server (with Caddy TLS)

A secure, Dockerized upload timing server for measuring client-to-server upload performance. Designed for integration with browser-based internet speed tests. Automatically provisions HTTPS via Caddy and supports API key protection, rate limiting, and file size limits.

---

## 🚀 Features

- 📥 Accepts multipart/form-data uploads (e.g. from browser speed test clients)
- ⏱️ Returns precise server-side timing metadata (received, processed, duration)
- 🔐 Optional API key protection
- 📉 Rate limiting (per IP)
- 📦 Memory-safe upload handling (configurable max size)
- 🌐 Automatic HTTPS with Caddy + Let's Encrypt
- 🐳 Docker Compose deployment with a single command

---

## 📁 Project Structure

```
speed-upload-server/
├── .env.example         # Environment variable template
├── Caddyfile            # Caddy v2 reverse proxy config
├── deploy.sh            # One-command deployment script
├── docker-compose.yml   # Compose stack: Caddy + Node server
└── server/
    ├── Dockerfile
    ├── index.js         # Express upload server
    └── package.json
```

---

## ⚙️ Configuration

Copy and edit your environment:

```bash
cp .env.example .env
```

Edit `.env`:

```env
API_KEY=your-secret-api-key
MAX_FILE_BYTES=104857600
ADMIN_EMAIL=admin@example.com
```

Edit `Caddyfile`:

```caddyfile
your.domain.example.com {
  route /upload* {
    reverse_proxy server:3000
  }
  # ... other routes and headers
}
```

Ensure your domain points to the server’s public IP (A/AAAA record).

---

## 🧪 API Usage

### POST /upload

Accepts: `multipart/form-data`  
Field: `file`  
Optional: `meta` (JSON string)  
Headers: `x-api-key: your-secret-api-key` (if enabled)

Returns:

```json
{
  "ok": true,
  "message": "received",
  "filename": "upload.bin",
  "size": 1048576,
  "serverReceivedAt": 1699999999999,
  "serverProcessedAt": 1699999999999,
  "serverProcessingMs": 12
}
```

---

## 🚀 Deployment

### Prerequisites

- Docker + Docker Compose
- A domain name pointing to your server
- Ports 80 and 443 open

### One-command deploy

```bash
chmod +x deploy.sh
./deploy.sh
```

Caddy will automatically provision TLS certificates for your domain.

---

## 🔐 Security Notes

- API key is optional but strongly recommended for public deployments
- File size limit defaults to 100MB (configurable via `.env`)
- Rate limiting is enabled (60 req/min per IP)
- Caddy handles TLS, headers, and reverse proxying

---

## 🧼 Cleanup

To stop and remove containers:

```bash
docker compose down
```

To rebuild:

```bash
docker compose build --no-cache
```

---

## 🧩 Integration

Use this server with your browser-based speed test UI. Set the upload endpoint to:

```
https://your.domain.example.com/upload
```

Include the API key in headers:

```http
x-api-key: your-secret-api-key
```

---

## 📜 License

MIT — free to use, modify, and distribute.

---
