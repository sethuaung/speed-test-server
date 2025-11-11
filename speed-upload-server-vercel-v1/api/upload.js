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
