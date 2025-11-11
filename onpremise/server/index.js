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
