// src/routes/posts.js
const express = require('express');
const router = express.Router();

// same dummy data (in real code, import from a module)
const POSTS = [
  { id: 1, slug: 'hello-world', title: 'Hello World', content: '<p>Welcome!</p>' },
  { id: 2, slug: 'second-post', title: 'Second Post', content: '<p>More content.</p>' },
  { id: 3, slug: 'third-post', title: 'Third Post', content: '<p>Even more content.</p>' },
];

router.get('/:slug', (req, res, next) => {
  const post = POSTS.find(p => p.slug === req.params.slug);
  if (!post) return next();
  res.render('post', { title: post.title, post });
});

module.exports = router;
