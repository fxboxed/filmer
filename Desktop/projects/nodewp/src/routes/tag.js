const express = require('express');
const router = express.Router();

const PER_PAGE = 6; // adjust as you like

// demo data (swap for WP later)
const TAGS = {
  javascript: [
    { title: 'JS 1', content: '...' },
    { title: 'JS 2', content: '...' },
    { title: 'JS 3', content: '...' },
  ],
  css: [{ title: 'CSS 1', content: '...' }],
};

// PAGE 1 = /tag/:slug
router.get('/:slug', (req, res) => {
  const slug = req.params.slug;
  const all = TAGS[slug] || [];
  const total = Math.max(Math.ceil(all.length / PER_PAGE), 1);
  const posts = all.slice(0, PER_PAGE);

  res.render('archive', {
    title: `Tag: ${slug}`,
    posts,
    pagination: {
      current: 1,
      total,
      baseHref: `/tag/${slug}/page`,
      firstHref: `/tag/${slug}`,
    },
  });
});

// PAGE 2+ = /tag/:slug/page/:page
router.get('/:slug/page/:page', (req, res) => {
  const slug = req.params.slug;
  const page = Math.max(parseInt(req.params.page, 10) || 1, 1);
  if (page === 1) return res.redirect(301, `/tag/${slug}`);

  const all = TAGS[slug] || [];
  const total = Math.max(Math.ceil(all.length / PER_PAGE), 1);
  const start = (page - 1) * PER_PAGE;
  const posts = all.slice(start, start + PER_PAGE);

  res.render('archive', {
    title: `Tag: ${slug}`,
    posts,
    pagination: {
      current: page,
      total,
      baseHref: `/tag/${slug}/page`,
      firstHref: `/tag/${slug}`,
    },
  });
});

module.exports = router;


