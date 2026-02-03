#!/usr/bin/env node
/**
 * Dump CostPlans schema (tables + columns) to a markdown file.
 * Run: cd backend && node ../scripts/schema-to-file.js
 * Output: schema-overview.md in repo root (open in VS Code).
 */
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../backend/.env') });
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

const outPath = path.resolve(__dirname, '../schema-overview.md');

async function run() {
  const pool = await sql.connect(config);

  const tables = await pool.request().query(`
    SELECT t.TABLE_SCHEMA, t.TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES t
    WHERE t.TABLE_TYPE = 'BASE TABLE'
    ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME
  `);

  let md = `# CostPlans schema overview\n\nGenerated from database: ${config.database}\n\n`;

  for (const table of tables.recordset) {
    const fullName = `${table.TABLE_SCHEMA}.${table.TABLE_NAME}`;
    const req = pool.request();
    req.input('schema', table.TABLE_SCHEMA);
    req.input('name', table.TABLE_NAME);
    const cols = await req.query(`
      SELECT c.COLUMN_NAME, c.DATA_TYPE, c.CHARACTER_MAXIMUM_LENGTH, c.IS_NULLABLE, c.COLUMN_DEFAULT
      FROM INFORMATION_SCHEMA.COLUMNS c
      WHERE c.TABLE_SCHEMA = @schema AND c.TABLE_NAME = @name
      ORDER BY c.ORDINAL_POSITION
    `);

    md += `## ${fullName}\n\n`;
    md += `| Column | Type | Nullable | Default |\n|--------|------|----------|--------|\n`;
    for (const c of cols.recordset) {
      const type = c.CHARACTER_MAXIMUM_LENGTH != null
        ? `${c.DATA_TYPE}(${c.CHARACTER_MAXIMUM_LENGTH})`
        : c.DATA_TYPE;
      md += `| ${c.COLUMN_NAME} | ${type} | ${c.IS_NULLABLE} | ${c.COLUMN_DEFAULT ?? '—'} |\n`;
    }
    md += '\n';
  }

  fs.writeFileSync(outPath, md, 'utf8');
  console.log('Written:', outPath);
  process.exit(0);
}

run().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
