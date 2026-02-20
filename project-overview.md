# Cost Plans Management Platform — Technical Overview

## 1. What This Application Does

This is a full-stack web application for managing OHCHR (UN Human Rights) annual cost plans. It allows finance officers to:

- Define **financial years** and approved projects for each year
- Configure **salary parameters** per country (exchange rates, post adjustments, grade salaries)
- Set **project-level parameters** (Programme Support Costs, Common Staff Costs, ASHI, Appendix)
- Manage **staffing positions** per project (grade, country, duty station, monthly deployment)
- Enter **operating costs** and **activity costs** with quarterly breakdowns
- **Automatically compute staff costing** from staffing data + salary parameters
- View a **budget summary** combining all cost sources
- **Import** data from prior financial years
- **Export** a full project cost plan to PDF

---

## 2. Architecture

```
                  ┌─────────────────────────────────┐
                  │         React Frontend           │
                  │   (Vite + TypeScript + AG Grid)  │
                  │         localhost:5173            │
                  └────────────┬────────────────────┘
                               │ HTTP (REST JSON)
                               ▼
                  ┌─────────────────────────────────┐
                  │      Node.js / Express API       │
                  │   (TypeScript, tsx watch)         │
                  │         localhost:3001            │
                  └────────────┬────────────────────┘
                               │ ODBC (Windows Auth)
                               ▼
                  ┌──────────────────────────────────────────┐
                  │          SQL Server Database              │
                  │      (SSDT Project — costPlanDB)          │
                  │  26 tables, 6 views, 47 SPs, 7 TVPs      │
                  └──────────────────────────────────────────┘
```

**Why these choices:**
- **React + AG Grid**: Complex editable grids with features like cascading dropdowns, multi-cell paste from Excel, column pinning, grouping, and inline validation.
- **Node.js + Express**: Lightweight API layer that calls stored procedures for all data access. Uses `mssql/msnodesqlv8` for native Windows Authentication (no passwords in code). Bulk write operations use Table-Valued Parameters (TVPs) to pass entire data sets to SPs in a single call.
- **SQL Server + SSDT**: Enterprise database with schema version control. The SSDT project allows publishing schema changes from Visual Studio and seeding reference data through post-deployment scripts.

---

## 3. Database Design

The database has **26 tables**, **47 stored procedures**, and **7 user-defined table types** organized into logical groups (see `schema.puml` for the full diagram):

**Reference Tables (12)** — Lookup data that rarely changes:
- Organizational hierarchy: `ref_divisions` → `ref_branches` → `ref_sections`
- Geographic: `ref_countries`, `ref_duty_stations`
- Post classification: `ref_post_categories` (PRO, GS, NO, UNV) → `ref_post_grades` (D-2, P-5, G-7, NO-C, etc.)
- Cost classification: `ref_umoja_classes`, `ref_operating_cost_categories`, `ref_activity_categories`
- Projects and roles: `ref_projects`, `ref_user_roles`

**Transactional Tables (12)** — Data that users create and edit:
- `fact_cost_plan_years` — Financial years (2025, 2026...)
- `fact_approved_projects` — Projects approved for a specific year
- `fact_project_positions` — Individual staff positions with monthly deployment (Jan-Dec)
- `fact_operating_costs` — Operating cost line items (units, duration, rate, Q1-Q4)
- `fact_activity_costs` — Activity cost line items (Q1-Q4 amounts)
- `fact_costing` — Staff costing (auto-generated amounts + user-editable budget fields)
- `fact_year_project_parameters` — PSC, CSC rates, ASHI, Appendix per project
- `fact_country_wise_salary_parameter_sets` — Country salary config (FX rate, post adjustment)
- `fact_country_specific_grade_salaries` — Base salary per grade per country
- `fact_users`, `fact_position_assignments`, `fact_deployment` (supporting/legacy)

**Mapping Tables (2):** `map_user_role_assignments`, `map_section_country`

---

## 4. Application Pages and Data Flow

### 4.1 Financial Years Page (`/financial-years`)

Displays all financial years as cards. Each year links to a sub-menu with three options: Projects, Salary Parameters, Project Parameters.

**Data:** `fact_cost_plan_years`

### 4.2 Approved Projects Page (`/financial-years/:year/projects`)

Shows all projects approved for a financial year in a filterable grid. Super users can add/remove projects.

**Data:** `fact_approved_projects` ← `ref_projects` ← `ref_sections` ← `ref_branches` ← `ref_divisions`

### 4.3 Salary Parameters Page (`/financial-years/:year/salary-parameters`)

A pivot-style grid where rows are countries and columns are: exchange rate, post adjustment, inflation rate, then one column per grade (salary amounts). Users can add countries, import from another year, and edit all values.

**Data:** `fact_country_wise_salary_parameter_sets` + `fact_country_specific_grade_salaries`

### 4.4 Project Parameters Page (`/financial-years/:year/project-parameters`)

A grid showing all projects for the year with editable percentage columns: PSC, CSC Professional, CSC General Service, CSC National Officers, ASHI, Appendix.

**Data:** `fact_year_project_parameters` (one row per approved project)

### 4.5 Cost Plan Editor (`/financial-years/:year/projects/:wbse`)

The main editor for a single project's cost plan. Has four tabs:

#### Staffing Tab
Each row is a staff position. Columns: Category, Grade (cascading dropdown), Country, Duty Station (cascading dropdown), Position Number, Encumbered (employee name), Start/End dates, Jan through Dec deployment (0-1 per month).

- **Reads from:** `fact_project_positions`
- **Writes to:** `fact_project_positions`
- Supports: Add Row, Duplicate Row, Delete Selected, paste from Excel

#### Operating Costs Tab
Pre-populated template from `ref_operating_cost_categories`, grouped by Umoja class (010 Staff, 120 Contractual, 125 Operating, 130 Supplies, 135 Equipment). Editable: units, duration, rate, Q1-Q4 amounts.

- **Reads from:** `fact_operating_costs` + `ref_operating_cost_categories`
- **Writes to:** `fact_operating_costs`

#### Activity Costs Tab
Fully user-managed rows for project activities. Columns include Umoja class, activity type, description, responsibility, gender marker, Q1-Q4 amounts.

- **Reads from:** `fact_activity_costs`
- **Writes to:** `fact_activity_costs`

#### Costing Tab
**Auto-generated.** When opened, the backend runs `sp_compute_costing` which:
1. Aggregates monthly deployment from `fact_project_positions` by (grade, country)
2. Looks up salary data from `fact_country_specific_grade_salaries`
3. Applies CSC rates from `fact_year_project_parameters`
4. Computes quarterly cost amounts per the formula (varies by category: PRO, GS, NO, UNV)
5. Returns detail rows (LEFT JOINed with saved budget fields from `fact_costing`) and category summaries with ASHI/Appendix surcharges

Users can only edit budget tracking fields (Released Budget, This Request, Total Released).

#### Summary Panel
Aggregates all costs into a budget summary: Staff Costs (by category) + Activities & Operating Costs (by Umoja class) + Grants, then Subtotal + PSC + Grand Total, broken down by Q1-Q4.

---

## 5. Key Design Decisions

### Costing is computed, not stored
Staff cost amounts are **never manually entered**. They are always computed live by `sp_compute_costing` from the staffing positions, salary parameters, and project parameters. The `fact_costing` table only stores user-editable budget tracking fields. This ensures costing always reflects current data.

### Month values live on positions, not deployment
Monthly deployment values (Jan-Dec) are stored directly on `fact_project_positions` (per individual position). The stored procedure aggregates them by (grade, country) for costing. This prevents data integrity issues that would occur if aggregated values were stored separately.

### Country determines salary
A position's `country_id` determines which salary parameters are used for costing. This allows a project based in Kenya to have an employee stationed in Switzerland, costed at Swiss salary rates.

### Percentage storage
All percentage values (PSC, CSC, ASHI, Appendix) are stored as decimals (e.g., 27.619% stored as 0.27619) in `DECIMAL(18,6)` columns. The frontend handles conversion for display.

### Import mechanism
The `sp_import_cost_plan_data` stored procedure copies data from one approved project to another (e.g., from 2025 to 2026), but only into tables that are empty for the target project. This allows carrying forward last year's cost plan as a starting point.

---

## 6. Stored Procedures & Table Types

The project follows a **"no inline SQL"** architecture. All data access from the Node.js API goes through stored procedures. There are **47 stored procedures** organized into three groups:

### Core / Computation (2 SPs)

| Procedure | Purpose |
|-----------|---------|
| `sp_compute_costing` | Computes all staff costing from positions + salary params + project params. Returns per-grade rows and per-category summaries. Called on every Costing tab load and save. |
| `sp_import_cost_plan_data` | Imports cost plan data from a source project to a target project (year-to-year). Only imports into empty tables. |

### Read SPs (26 `usp_get_*`)
Every GET endpoint calls a dedicated `usp_get_*` stored procedure. Examples: `usp_get_all_projects`, `usp_get_project_staffing`, `usp_get_salary_parameters_by_year`, `usp_get_cost_plan_years`, etc.

### Write SPs (15 `usp_save_*` / `usp_create_*` / `usp_delete_*` / `usp_import_*`)
Every PUT/POST/DELETE endpoint calls a dedicated write SP. Bulk operations use **Table-Valued Parameters (TVPs)** — the Node.js code builds a `sql.Table` object matching a User-Defined Table Type, then passes it as a parameter to the SP. This eliminates client-side loops and transactions.

**7 User-Defined Table Types (TVPs):**

| Type | Used by | Purpose |
|------|---------|---------|
| `StaffingRowType` | `usp_save_staffing` | Bulk MERGE positions (metadata + months) |
| `DeploymentRowType` | `usp_save_deployment` | Bulk MERGE deployment rows |
| `OperatingCostRowType` | `usp_save_operating_costs` | Bulk MERGE operating cost rows |
| `ActivityCostRowType` | `usp_save_activity_costs` | Bulk MERGE activity cost rows |
| `CostingEditRowType` | `usp_save_costing` | Bulk MERGE budget fields on costing rows |
| `GradeSalaryRowType` | `usp_save_salary_parameters` | Bulk MERGE grade salaries per CWSP set |
| `IntIdListType` | `usp_delete_staffing_rows` | Pass list of IDs for bulk delete |

### Legacy SPs (4, not used by Node.js)
`sp_get_operating_costs`, `sp_get_approved_projects`, `sp_get_user_permissions`, `sp_get_costing_by_project` — these wrap database views and were part of the original design.

---

## 7. API Structure

The backend has 5 route files mounting ~40 endpoints. **All endpoints call stored procedures** — there is no inline SQL in the route files.

| Route File | Base Path | Purpose |
|-----------|-----------|---------|
| `ref.ts` | `/api/ref` | 10 GET endpoints → `usp_get_*` SPs for dropdown/lookup data |
| `costPlanYears.ts` | `/api/cost-plan-years` | Year management, approved projects, salary import → `usp_*` SPs |
| `projects.ts` | `/api/projects` | Per-project data: staffing, costing, operating, activity, params → `usp_*` SPs with TVPs for bulk writes |
| `salaryParameters.ts` | `/api/salary-parameters` | Save salary params → `usp_save_salary_parameters` with `GradeSalaryRowType` TVP |
| `health.ts` | `/api/health` | Database connectivity check |

All endpoints follow REST conventions: GET for reads, PUT for upserts, POST for creates, DELETE for removals.

> **Architecture note:** Route files import `sql` and `getPool` from `../config/db.js` (not from the `mssql` package directly) to ensure compatibility with the `msnodesqlv8` ODBC driver. For bulk write operations, the route constructs a `sql.Table` matching the appropriate TVP type, populates it with rows from the request body, and passes it to the SP via `.input('rows', tvp).execute('dbo.usp_...')`.

---

## 8. Testing

The backend has 6 test files covering all major endpoints:

| Test File | Coverage |
|-----------|----------|
| `ref.test.ts` | All reference data endpoints |
| `costPlanYears.test.ts` | Years, approved projects, salary/project parameters |
| `staffing.test.ts` | Staffing CRUD + month summary |
| `costing.test.ts` | Costing computation, SP output validation, budget field saves |
| `salaryChain.test.ts` | End-to-end: salary params → staffing → costing chain |
| `operatingAndActivity.test.ts` | Operating costs, activity costs, project params, linked years |

Tests run against a live database using the same connection as production (Windows Auth).

---

## 9. PDF Export

The PDF generator (`generatePdf.ts`) creates a landscape A4 document with:
1. Project details header
2. Project parameters table
3. Country salary parameters
4. Deployment summary (monthly posts by grade)
5. Staff costing breakdown (by category, with subtotals)
6. Operating costs (by Umoja class)
7. Activity costs
8. Staffing roster
9. Full budget summary (Staff + AOC + Grants + PSC = Grand Total)

---

## 10. Security and Access Control

- **Database auth:** Windows Authentication (Trusted Connection) — no passwords in code
- **Role-based UI:** The frontend loads roles from the database and toggles edit capabilities. Regular users have read-only access; Super Users and Admins can edit and manage projects.
- **No authentication layer yet:** The current implementation trusts the Windows identity from the ODBC connection. User authentication middleware is planned for future phases.
