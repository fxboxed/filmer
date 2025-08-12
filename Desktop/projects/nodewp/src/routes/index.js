const express = require('express');
const router = express.Router();

const POSTS = [
  { title: 'Post 1', content: 'Content 1' },
  { title: 'Post 2', content: 'Content 2' },
  { title: 'Post 3', content: 'Content 3' },
  { title: 'Post 4', content: 'Content 4' }
];

const PER_PAGE = 2;

// PAGE 1 = naked URL
router.get('/', (req, res) => {
  const totalPages = Math.max(Math.ceil(POSTS.length / PER_PAGE), 1);
  const posts = POSTS.slice(0, PER_PAGE);

  res.render('index', {
    posts,
    pagination: { current: 1, total: totalPages, baseHref: '/page', firstHref: '/' }
  });
});

// Normalize any /page/1 to /
router.get('/page/1', (req, res) => res.redirect(301, '/'));

// PAGE 2+
router.get('/page/:page', (req, res) => {
  const page = Math.max(parseInt(req.params.page, 10) || 1, 1);
  if (page === 1) return res.redirect(301, '/');
  const totalPages = Math.max(Math.ceil(POSTS.length / PER_PAGE), 1);
  const start = (page - 1) * PER_PAGE;
  const posts = POSTS.slice(start, start + PER_PAGE);

  res.render('index', {
    posts,
    pagination: { current: page, total: totalPages, baseHref: '/page', firstHref: '/' }
  });
});

module.exports = router;




