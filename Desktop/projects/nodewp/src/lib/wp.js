// src/lib/wp.js
const fetch = (...args) => import('node-fetch').then(({default: f}) => f(...args));

const WP_BASE_URL = process.env.WP_BASE_URL; // e.g., http://nodewp.local

async function getPosts({ page = 1, perPage = 10 } = {}) {
  const url = `${WP_BASE_URL}/wp-json/wp/v2/posts?per_page=${perPage}&page=${page}&_embed`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`WP error: ${res.status}`);
  const posts = await res.json();
  const totalPages = parseInt(res.headers.get('x-wp-totalpages') || '1', 10);
  // Normalize keys to match our Pug templates
  return {
    posts: posts.map(p => ({
      id: p.id,
      slug: p.slug,
      title: p.title?.rendered || '(untitled)',
      excerpt: p.excerpt?.rendered || '',
      content: p.content?.rendered || ''
    })),
    totalPages
  };
}

async function getPostBySlug(slug) {
  const url = `${WP_BASE_URL}/wp-json/wp/v2/posts?slug=${encodeURIComponent(slug)}&_embed`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`WP error: ${res.status}`);
  const arr = await res.json();
  const p = arr[0];
  if (!p) return null;
  return {
    id: p.id,
    slug: p.slug,
    title: p.title?.rendered || '(untitled)',
    content: p.content?.rendered || ''
  };
}

module.exports = { getPosts, getPostBySlug };
