# 📡 Speed Upload Server (Vercel)

A serverless upload timing endpoint for measuring client-to-server performance. Compatible with Node.js 22.x and Vercel Functions.

## 🚀 Usage

POST a file to:

```
https://your-vercel-project.vercel.app/upload
```

Form field: `file` (multipart/form-data)

Returns:

```json
{
  "ok": true,
  "filename": "upload.bin",
  "size": 1048576,
  "serverReceivedAt": 1699999999999,
  "serverProcessedAt": 1699999999999,
  "serverProcessingMs": 12
}
```

## 🧪 Local Dev

Install dependencies:

```bash
npm install
```

Run locally (with Vercel CLI):

```bash
vercel dev
```

## 📦 Deploy

Push to GitHub and import into Vercel. Set root directory to `speed-upload-server-vercel`.

## 🔐 Notes

- Max upload size: 100MB
- No authentication included — add API key or JWT if needed
