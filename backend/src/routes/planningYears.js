const express = require('express');
const { query } = require('../config/db');

const router = express.Router();

router.get('/', async (req, res, next) => {
  try {
    const result = await query(`
      SELECT cost_plan_year_id, year_code, year_name, status, start_date, end_date, created_at, updated_at
      FROM dbo.cost_plan_years
      ORDER BY year_code DESC
    `);
    res.json(result.recordset);
  } catch (err) {
    next(err);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      `SELECT cost_plan_year_id, year_code, year_name, status, start_date, end_date, created_at, updated_at
       FROM dbo.cost_plan_years
       WHERE cost_plan_year_id = @id`,
      { id: parseInt(id, 10) }
    );
    if (!result.recordset || result.recordset.length === 0) {
      return res.status(404).json({ error: 'Planning year not found' });
    }
    res.json(result.recordset[0]);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
