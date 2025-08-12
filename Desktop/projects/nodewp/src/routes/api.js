// src/routes/api.js
const express = require('express');
const router = express.Router();

// Simple API to demonstrate JSON output
router.get('/health', (req, res) => res.json({ ok: true }));
router.get('/version', (req, res) => res.json({ version: '1.0.0' }));

module.exports = router;
