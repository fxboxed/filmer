const express = require('express');
const router = express.Router();
const getFetch = () =>
  global.fetch ? global.fetch : (...a) => import('node-fetch').then(({default:f}) => f(...a));

const WP = process.env.WP_API_BASE || 'http://localhost/wp-json';

router.get('/posts', async (req, res) => {
  try {
    const per = Math.max(parseInt(req.query.per_page || '5', 10), 1);
    const r = await getFetch()(`${WP}/wp/v2/posts?per_page=${per}&_embed`);
    if (!r.ok) throw new Error(`WP ${r.status}`);
    res.json(await r.json());
  } catch (e) {
    console.error('[wp] /posts failed:', e.message);
    res.status(502).json({ error: 'WordPress fetch failed' });
  }
});

router.get('/posts/:id', async (req, res) => {
  try {
    const r = await getFetch()(`${WP}/wp/v2/posts/${req.params.id}?_embed`);
    if (!r.ok) throw new Error(`WP ${r.status}`);
    res.json(await r.json());
  } catch (e) {
    console.error('[wp] /posts/:id failed:', e.message);
    res.status(502).json({ error: 'WordPress fetch failed' });
  }
});

module.exports = router;

