const express = require('express');
const { query } = require('../config/db');

const router = express.Router();

router.get('/countries', async (req, res, next) => {
  try {
    const result = await query(`
      SELECT country_id, country_name, iso2_code, iso3_code, is_active
      FROM dbo.REF_COUNTRIES
      WHERE is_active = 1
      ORDER BY country_name
    `);
    res.json(result.recordset);
  } catch (err) {
    next(err);
  }
});

router.get('/grades', async (req, res, next) => {
  try {
    const result = await query(`
      SELECT grade_id, grade_code, grade_family, display_order, is_active
      FROM dbo.REF_GRADES
      WHERE is_active = 1
      ORDER BY display_order, grade_code
    `);
    res.json(result.recordset);
  } catch (err) {
    next(err);
  }
});

router.get('/post-categories', async (req, res, next) => {
  try {
    const result = await query(`
      SELECT post_category_id, category_code, category_name, description, is_active
      FROM dbo.REF_POST_CATEGORIES
      WHERE is_active = 1
      ORDER BY category_code
    `);
    res.json(result.recordset);
  } catch (err) {
    next(err);
  }
});

router.get('/umoja-classes', async (req, res, next) => {
  try {
    const result = await query(`
      SELECT umoja_class_id, class_code, class_name, description, is_active
      FROM dbo.REF_UMOJA_CLASSES
      WHERE is_active = 1
      ORDER BY class_code
    `);
    res.json(result.recordset);
  } catch (err) {
    next(err);
  }
});

router.get('/cost-categories', async (req, res, next) => {
  try {
    const result = await query(`
      SELECT cost_category_id, category_code, category_name, display_order, is_active
      FROM dbo.REF_COST_CATEGORIES
      WHERE is_active = 1
      ORDER BY display_order, category_code
    `);
    res.json(result.recordset);
  } catch (err) {
    next(err);
  }
});

router.get('/duty-stations', async (req, res, next) => {
  try {
    const result = await query(`
      SELECT ds.duty_station_id, ds.duty_station_name, ds.country_id, c.country_name, ds.is_active
      FROM dbo.REF_DUTY_STATIONS ds
      JOIN dbo.REF_COUNTRIES c ON c.country_id = ds.country_id
      WHERE ds.is_active = 1
      ORDER BY ds.duty_station_name
    `);
    res.json(result.recordset);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
