const express = require('express');
const router = express.Router();

const PER_PAGE = 6; // adjust as you like

// demo data (swap for WP later)
const CATEGORIES = {
  news: [
    { title: 'News 1', content: '...' },
    { title: 'News 2', content: '...' },
    { title: 'News 3', content: '...' },
  ],
  tech: [{ title: 'Tech 1', content: '...' }],
};

// PAGE 1 = /category/:slug
router.get('/:slug', (req, res) => {
  const slug = req.params.slug;
  const all = CATEGORIES[slug] || [];
  const total = Math.max(Math.ceil(all.length / PER_PAGE), 1);
  const posts = all.slice(0, PER_PAGE);

  res.render('archive', {
    title: `Category: ${slug}`,
    posts,
    pagination: {
      current: 1,
      total,
      baseHref: `/category/${slug}/page`,
      firstHref: `/category/${slug}`,
    },
  });
});

// PAGE 2+ = /category/:slug/page/:page
router.get('/:slug/page/:page', (req, res) => {
  const slug = req.params.slug;
  const page = Math.max(parseInt(req.params.page, 10) || 1, 1);
  if (page === 1) return res.redirect(301, `/category/${slug}`);

  const all = CATEGORIES[slug] || [];
  const total = Math.max(Math.ceil(all.length / PER_PAGE), 1);
  const start = (page - 1) * PER_PAGE;
  const posts = all.slice(start, start + PER_PAGE);

  res.render('archive', {
    title: `Category: ${slug}`,
    posts,
    pagination: {
      current: page,
      total,
      baseHref: `/category/${slug}/page`,
      firstHref: `/category/${slug}`,
    },
  });
});

module.exports = router;

