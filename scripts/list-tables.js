#!/usr/bin/env node
/**
 * List tables in CostPlans database. Run from backend (so mssql/dotenv are available):
 *   cd backend && npm run list-tables
 * Or: cd backend && node ../scripts/list-tables.js
 * Requires: backend/.env with DB_* and npm install in backend
 */
require('dotenv').config({ path: require('path').resolve(__dirname, '../backend/.env') });
const sql = require('mssql');

const config = {
  server: process.env.DB_SERVER || 'localhost',
  port: parseInt(process.env.DB_PORT || '1433', 10),
  database: process.env.DB_NAME || 'CostPlans',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  options: {
    encrypt: true,
    trustServerCertificate: process.env.DB_TRUST_CERTIFICATE === 'true',
    enableArithAbort: true,
  },
  pool: { max: 2 },
};

const query = `
  SELECT TABLE_SCHEMA AS [Schema], TABLE_NAME AS [Table]
  FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_TYPE = 'BASE TABLE'
  ORDER BY TABLE_SCHEMA, TABLE_NAME;
`;

sql
  .connect(config)
  .then((pool) => pool.request().query(query))
  .then((result) => {
    console.log('Tables in', config.database, ':\n');
    result.recordset.forEach((r) => console.log('  ', r.Schema + '.' + r.Table));
    process.exit(0);
  })
  .catch((err) => {
    console.error('Error:', err.message);
    process.exit(1);
  });
