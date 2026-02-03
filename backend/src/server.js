require('dotenv').config();
const express = require('express');
const cors = require('cors');
const planningYearsRouter = require('./routes/planningYears');
const referenceRouter = require('./routes/reference');
const { close } = require('./config/db');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors({ origin: true }));
app.use(express.json());

app.use('/api/planning-years', planningYearsRouter);
app.use('/api/reference', referenceRouter);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'cost-plans-api' });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error',
  });
});

const server = app.listen(PORT, () => {
  console.log(`Cost Plans API listening on http://localhost:${PORT}`);
});

process.on('SIGTERM', async () => {
  server.close();
  await close();
  process.exit(0);
});
