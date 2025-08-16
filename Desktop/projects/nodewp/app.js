const express = require('express');
const path = require('path');
require('dotenv').config();

// Routes
const indexRoutes = require('./src/routes/index');
const categoryRoutes = require('./src/routes/category');
const tagRoutes = require('./src/routes/tag');
const contactRoutes = require('./src/routes/contact');

const app = express();

// View engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');

// Middleware
app.use(express.urlencoded({ extended: false }));
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Routes
app.use('/', indexRoutes);
app.use('/category', categoryRoutes);
app.use('/tag', tagRoutes);
app.use('/contact', contactRoutes);
app.use('/', categoryRoutes);

const wpRoutes = require('./src/routes/wp');
app.use('/api/wp', wpRoutes);



// 404 handler
app.use((req, res) => {
  res.status(404).render('404', { url: req.originalUrl });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, '0.0.0.0', () =>
  console.log(`Listening on http://0.0.0.0:${PORT}`)
);




