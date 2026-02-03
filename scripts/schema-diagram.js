#!/usr/bin/env node
/**
 * Generate a Mermaid ER diagram of the CostPlans schema.
 * Run: cd backend && node ../scripts/schema-diagram.js
 * Output: schema-diagram.md in repo root. Open in VS Code and use Mermaid preview.
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

const outPath = path.resolve(__dirname, '../schema-diagram.md');

// Mermaid-safe table/column name (no spaces, no special chars)
function safe(s) {
  return String(s).replace(/\s+/g, '_').replace(/[^a-zA-Z0-9_]/g, '') || 'col';
}

async function run() {
  const pool = await sql.connect(config);

  const tables = await pool.request().query(`
    SELECT t.TABLE_SCHEMA, t.TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES t
    WHERE t.TABLE_TYPE = 'BASE TABLE'
    ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME
  `);

  const fks = await pool.request().query(`
    SELECT
      OBJECT_NAME(fk.parent_object_id) AS child_table,
      OBJECT_NAME(fk.referenced_object_id) AS parent_table
    FROM sys.foreign_keys fk
    INNER JOIN sys.tables pt ON pt.object_id = fk.referenced_object_id
    INNER JOIN sys.schemas ps ON ps.schema_id = pt.schema_id
    WHERE ps.name = 'dbo'
    ORDER BY child_table, parent_table
  `);

  let md = `# CostPlans schema diagram\n\n`;
  md += `Open this file in VS Code and use **Mermaid** preview (e.g. "Markdown Preview Mermaid Support" or "Mermaid Preview" extension).\n\n`;
  md += "```mermaid\nerDiagram\n";

  const tableNames = new Set();
  for (const t of tables.recordset) {
    const name = t.TABLE_NAME;
    tableNames.add(name);
    const req = pool.request();
    req.input('schema', t.TABLE_SCHEMA);
    req.input('name', name);
    const cols = await req.query(`
      SELECT c.COLUMN_NAME, c.DATA_TYPE
      FROM INFORMATION_SCHEMA.COLUMNS c
      WHERE c.TABLE_SCHEMA = @schema AND c.TABLE_NAME = @name
      ORDER BY c.ORDINAL_POSITION
    `);
    const shortName = safe(name);
    md += `  ${shortName} {\n`;
    for (const c of cols.recordset) {
      const type = (c.DATA_TYPE || 'unknown').substring(0, 12);
      md += `    ${type} ${safe(c.COLUMN_NAME)}\n`;
    }
    md += `  }\n`;
  }

  const seen = new Set();
  for (const fk of fks.recordset) {
    const child = safe(fk.child_table);
    const parent = safe(fk.parent_table);
    if (!tableNames.has(fk.child_table) || !tableNames.has(fk.parent_table)) continue;
    const key = `${parent}-${child}`;
    if (seen.has(key)) continue;
    seen.add(key);
    md += `  ${parent} ||--o{ ${child} : "FK"\n`;
  }

  md += "```\n";

  fs.writeFileSync(outPath, md, 'utf8');
  console.log('Written:', outPath);
  console.log('Open in VS Code and use a Mermaid preview extension to view the diagram.');
  process.exit(0);
}

run().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
