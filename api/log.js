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
