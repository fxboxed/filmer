const express = require('express');
const router = express.Router();
const { sendContactMail } = require('../lib/mail');

function isBot(body) {
  return body && typeof body.website === 'string' && body.website.trim() !== '';
}

router.post('/', async (req, res) => {
  const { name = '', email = '', message = '', source = 'contact-modal' } = req.body || {};

  // basic validation
  if (!name.trim() || !email.trim() || !message.trim()) {
    return res.status(400).json({ ok: false, error: 'All fields are required.' });
  }
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    return res.status(400).json({ ok: false, error: 'Please enter a valid email.' });
  }
  if (isBot(req.body)) {
    console.log('[contact] honeypot triggered');
    return res.json({ ok: true, message: 'Thanks!' });
  }

  try {
    await sendContactMail({ name: name.trim(), email: email.trim(), message: message.trim(), source });
    console.log('[contact] email sent ✓', { from: email, name, len: message.length });
    return res.json({ ok: true, message: 'Thanks! Your message was sent.' });
  } catch (err) {
    console.error('[contact] email FAILED ✗', err && err.message);
    return res.status(500).json({ ok: false, error: 'Unable to send right now. Please try later.' });
  }
});

module.exports = router;


