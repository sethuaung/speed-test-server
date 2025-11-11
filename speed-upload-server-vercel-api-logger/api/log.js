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
