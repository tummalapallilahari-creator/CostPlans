# Cost Plans — Developer Cheatsheet

Quick reference for every page, route, table, and operation.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 18 + TypeScript, Vite, AG Grid Community, React Router v6 |
| Backend | Node.js + Express + TypeScript, `mssql/msnodesqlv8` (Windows Auth) |
| Database | SQL Server (SSDT project), 26 tables, 6 views, 47 stored procedures, 7 table types (TVPs) |
| PDF | jsPDF + jspdf-autotable |
| Dev server | `tsx watch` (backend), Vite dev server (frontend), port 3001 / 5173 |

---

## Frontend Routes → Pages

| Route | Page Component | What it does |
|-------|---------------|--------------|
| `/` | HomePage | Landing page with hero, feature cards, quick links |
| `/projects` | AllProjectsPage | Master project list with filter panel (div/branch/section/country) |
| `/financial-years` | CostPlanYearsPage | Grid of financial year cards (2025, 2026...) |
| `/financial-years/:yearCode` | YearOptionsPage | Three cards: Projects, Salary Params, Project Params |
| `/financial-years/:yearCode/projects` | ApprovedProjectsPage | AG Grid of approved projects for that year + manage projects modal |
| `/financial-years/:yearCode/projects/:wbse` | CostPlanEditorPage | **Main editor** — 4 tabs: Staffing, Operating Costs, Activity Costs, Costing + Summary panel |
| `/financial-years/:yearCode/salary-parameters` | SalaryParametersPage | AG Grid pivot table of salary params by country × grade |
| `/financial-years/:yearCode/project-parameters` | ProjectParametersPage | AG Grid of PSC/CSC/ASHI/Appendix per project |

---

## Page → API Calls → Tables (The Full Chain)

### HomePage
- No API calls. Static content.

### AllProjectsPage
- `GET /api/projects` → `usp_get_all_projects`
- `POST /api/projects` → `usp_create_project`
- `GET /api/ref/divisions`, `/ref/branches/:id`, `/ref/sections/:id` → `usp_get_*` SPs for filter dropdowns

### CostPlanYearsPage
- `GET /api/cost-plan-years` → `usp_get_cost_plan_years`

### YearOptionsPage
- `GET /api/cost-plan-years/:yearCode` → `usp_get_cost_plan_year_by_code`

### ApprovedProjectsPage
- `GET /api/cost-plan-years/:yearCode/projects` → `usp_get_approved_projects_by_year`
- `POST /api/cost-plan-years/:yearCode/projects` → `usp_add_project_to_year`
- `DELETE /api/cost-plan-years/:yearCode/projects/:id` → `usp_remove_project_from_year`
- `POST /api/cost-plan-years/:yearCode/projects/create-new` → `usp_create_new_project_for_year`
- `GET /api/cost-plan-years/:yearCode/available-projects` → `usp_get_available_projects_for_year`

### CostPlanEditorPage (the big one)

**On load:**
- `GET /projects/:id/parameters` → `usp_get_project_parameters`
- `GET /projects/:id/country-salary-params` → `usp_get_project_country_salary_params`
- `GET /projects/:id/linked-years` → `usp_get_project_linked_years`

**Staffing Tab:**
- `GET /projects/:id/staffing` → `usp_get_project_staffing` → `fact_project_positions` + ref tables
- `PUT /projects/:id/staffing` → builds `StaffingRowType` TVP → `usp_save_staffing` (months clamped 0-1)
- `DELETE /projects/:id/staffing/rows` → builds `IntIdListType` TVP → `usp_delete_staffing_rows`
- Add Row / Duplicate Row / Delete Selected → local state + save

**Operating Costs Tab:**
- `GET /projects/:id/operating-costs` → `usp_get_project_operating_costs` → template + `fact_operating_costs`
- `PUT /projects/:id/operating-costs` → builds `OperatingCostRowType` TVP → `usp_save_operating_costs`

**Activity Costs Tab:**
- `GET /projects/:id/activity-costs` → `usp_get_project_activity_costs` → `fact_activity_costs` + refs
- `PUT /projects/:id/activity-costs` → builds `ActivityCostRowType` TVP → `usp_save_activity_costs`

**Costing Tab:**
- `GET /projects/:id/costing` → executes `sp_compute_costing` → returns live-computed rows + summary
- `PUT /projects/:id/costing` → builds `CostingEditRowType` TVP → `usp_save_costing` → re-runs `sp_compute_costing` → returns fresh data

**Save button (top-level):**
- Saves project parameters → `PUT /projects/:id/parameters` → `usp_save_project_parameters`
- Saves CWSP → `PUT /projects/:id/country-salary-params` → `usp_save_project_country_salary_params`
- Triggers `saveSignal` to all 4 tabs simultaneously

**Import button:**
- `POST /projects/:targetId/import-from/:sourceId` → `sp_import_cost_plan_data`

**PDF button:**
- Fetches all data (staffing-month-summary, operating, activity, costing, staffing)
- Generates PDF client-side with jsPDF

### SalaryParametersPage
- `GET /api/cost-plan-years/:yearCode/salary-parameters` → `usp_get_salary_parameters_by_year` (pivoted)
- `PUT /api/salary-parameters/:cwspSetId` → builds `GradeSalaryRowType` TVP → `usp_save_salary_parameters`
- `POST /api/cost-plan-years/:yearCode/salary-parameters` → `usp_create_salary_parameter_set`
- `POST /api/cost-plan-years/:yearCode/salary-parameters/import-from/:sourceYearCode` → `usp_import_salary_parameters`

### ProjectParametersPage
- `GET /api/cost-plan-years/:yearCode/project-parameters` → `usp_get_project_parameters_by_year`
- `PUT /api/projects/:id/parameters` → `usp_save_project_parameters`

---

## Stored Procedures

### Core / Computation SPs

| SP | Called by | What it does |
|----|----------|-------------|
| `sp_compute_costing` | GET/PUT `/projects/:id/costing` | Aggregates months from `fact_project_positions` by (grade, country), looks up salaries from CWSP, computes quarterly costs using CSC/post-adj/FX rates. Returns 2 result sets: detail rows + category summaries with ASHI/appendix. |
| `sp_import_cost_plan_data` | POST `/projects/:id/import-from/:sourceId` | Copies deployment, positions, operating costs, activity costs, costing, project params from source to target project. Only copies if target table is empty. |

### Read SPs (`usp_get_*`) — All GET endpoints now route through these

| SP | Route | Returns |
|----|-------|---------|
| `usp_get_cost_plan_years` | `GET /api/cost-plan-years` | All financial years |
| `usp_get_cost_plan_year_by_code` | `GET /api/cost-plan-years/:yearCode` | Single year by code |
| `usp_get_approved_projects_by_year` | `GET /api/cost-plan-years/:yearCode/projects` | Projects for a year + org hierarchy |
| `usp_get_available_projects_for_year` | `GET /api/cost-plan-years/:yearCode/available-projects` | Projects not yet in this year |
| `usp_get_salary_parameters_by_year` | `GET /api/cost-plan-years/:yearCode/salary-parameters` | CWSP sets + grade salaries (pivoted) |
| `usp_get_project_parameters_by_year` | `GET /api/cost-plan-years/:yearCode/project-parameters` | All project params for a year |
| `usp_get_all_projects` | `GET /api/projects` | All projects + org hierarchy |
| `usp_get_project_parameters` | `GET /projects/:id/parameters` | Single project's params |
| `usp_get_project_country_salary_params` | `GET /projects/:id/country-salary-params` | CWSP sets for project's year/country |
| `usp_get_project_linked_years` | `GET /projects/:id/linked-years` | Other years for same project |
| `usp_get_project_staffing` | `GET /projects/:id/staffing` | Positions + ref joins |
| `usp_get_project_staffing_month_summary` | `GET /projects/:id/staffing-month-summary` | Aggregated months by grade |
| `usp_get_project_deployment` | `GET /projects/:id/deployment` | Deployment rows |
| `usp_get_project_operating_costs` | `GET /projects/:id/operating-costs` | Template + saved operating costs |
| `usp_get_project_activity_costs` | `GET /projects/:id/activity-costs` | Activity costs + umoja refs |
| `usp_get_countries` | `GET /api/ref/countries` | All countries |
| `usp_get_duty_stations` | `GET /api/ref/duty-stations` | All duty stations |
| `usp_get_divisions` | `GET /api/ref/divisions` | All divisions |
| `usp_get_branches_by_division` | `GET /api/ref/branches/:divisionId` | Branches for division |
| `usp_get_sections_by_branch` | `GET /api/ref/sections/:branchId` | Sections for branch |
| `usp_get_post_categories` | `GET /api/ref/post-categories` | All post categories |
| `usp_get_post_grades` | `GET /api/ref/post-grades` | All post grades |
| `usp_get_umoja_classes` | `GET /api/ref/umoja-classes` | All umoja classes |
| `usp_get_operating_cost_categories` | `GET /api/ref/operating-cost-categories` | All operating cost categories |
| `usp_get_user_roles` | `GET /api/ref/user-roles` | All user roles |
| `usp_get_costing_grade_template` | (internal) | Grade template for costing |

### Write SPs (`usp_save_*`, `usp_create_*`, `usp_delete_*`, `usp_import_*`) — All PUT/POST/DELETE endpoints

| SP | Route | TVP Used | What it does |
|----|-------|----------|-------------|
| `usp_create_project` | `POST /api/projects` | — | Inserts `ref_projects`, checks unique WBSE |
| `usp_add_project_to_year` | `POST /.../projects` | — | Links project to year in `fact_approved_projects` |
| `usp_remove_project_from_year` | `DELETE /.../projects/:id` | — | Soft-deletes `fact_approved_projects` |
| `usp_create_new_project_for_year` | `POST /.../projects/create-new` | — | Creates `ref_projects` + `fact_approved_projects` |
| `usp_create_salary_parameter_set` | `POST /.../salary-parameters` | — | Creates new CWSP set for a country |
| `usp_import_salary_parameters` | `POST /.../salary-parameters/import-from/:src` | — | Bulk copies CWSP from another year |
| `usp_save_salary_parameters` | `PUT /api/salary-parameters/:id` | `GradeSalaryRowType` | Updates CWSP header + MERGE grade salaries |
| `usp_save_deployment` | `PUT /projects/:id/deployment` | `DeploymentRowType` | MERGE `fact_deployment` |
| `usp_save_operating_costs` | `PUT /projects/:id/operating-costs` | `OperatingCostRowType` | MERGE `fact_operating_costs` |
| `usp_save_activity_costs` | `PUT /projects/:id/activity-costs` | `ActivityCostRowType` | MERGE `fact_activity_costs` |
| `usp_save_costing` | `PUT /projects/:id/costing` | `CostingEditRowType` | MERGE `fact_costing` budget fields |
| `usp_save_staffing` | `PUT /projects/:id/staffing` | `StaffingRowType` | MERGE `fact_project_positions` |
| `usp_delete_staffing_rows` | `DELETE /projects/:id/staffing/rows` | `IntIdListType` | Deletes positions by ID list |
| `usp_save_project_country_salary_params` | `PUT /projects/:id/country-salary-params` | — | Updates project's CWSP set |
| `usp_save_project_parameters` | `PUT /projects/:id/parameters` | — | MERGE `fact_year_project_parameters` |

### Legacy SPs (not called by Node.js)

| SP | What it does |
|----|-------------|
| `sp_get_operating_costs` | Returns operating costs via `vw_operating_costs_detail` |
| `sp_get_approved_projects` | Returns approved projects via `vw_approved_projects_detail` |
| `sp_get_user_permissions` | Returns user roles via `vw_user_roles` |
| `sp_get_costing_by_project` | Returns costing via `vw_costing_detail` |

---

## User-Defined Table Types (TVPs)

| Type | Used by SP | Matches table |
|------|-----------|---------------|
| `DeploymentRowType` | `usp_save_deployment` | `fact_deployment` |
| `OperatingCostRowType` | `usp_save_operating_costs` | `fact_operating_costs` |
| `ActivityCostRowType` | `usp_save_activity_costs` | `fact_activity_costs` |
| `CostingEditRowType` | `usp_save_costing` | `fact_costing` (budget fields only) |
| `StaffingRowType` | `usp_save_staffing` | `fact_project_positions` |
| `GradeSalaryRowType` | `usp_save_salary_parameters` | `fact_country_specific_grade_salaries` |
| `IntIdListType` | `usp_delete_staffing_rows` | Generic ID list for bulk deletes |

---

## Costing Formula (the hardest question)

```
For each unique (grade, country) aggregated from fact_project_positions:

  nb   = net base salary (from fact_country_specific_grade_salaries)
  padj = post adjustment multiplier (from CWSP for that country)
  fx   = exchange rate to USD (from CWSP for that country)
  csc  = common staff cost rate (from fact_year_project_parameters, varies by PRO/GS/NO)

  Quarter months = SUM of 3 monthly posts across all positions with same grade+country

  PRO:  q = (nb + nb*padj/100 + csc*nb) * quarter_months / 12
  GS:   q = ((nb + csc*nb) * quarter_months / 12) / fx
  NO:   q = ((nb + csc*nb) * quarter_months / 12) / fx
  UNV:  q = nb * quarter_months / 12 [/ fx if National UNV]

Summary adds:
  ASHI     = ashi_rate * subtotal
  Appendix = appendix_rate * (subtotal + ASHI)  [GS/NO only]
```

---

## Key Data Flow Diagram

```
User enters staffing positions (Staffing Tab)
    ↓ PUT /staffing
    ↓ writes → fact_project_positions (months + metadata)
    ↓
User opens Costing Tab
    ↓ GET /costing
    ↓ executes sp_compute_costing
    ↓ reads → fact_project_positions (aggregates months)
    ↓ reads → fact_country_wise_salary_parameter_sets (FX, post adj)
    ↓ reads → fact_country_specific_grade_salaries (base salary)
    ↓ reads → fact_year_project_parameters (CSC rates)
    ↓ LEFT JOINs → fact_costing (saved budget fields)
    ↓ returns → live-computed amounts + saved budget fields
    ↓
Summary Panel aggregates costing + operating + activity costs
```

---

## Table Quick Reference

| Table | Written by | Read by |
|-------|-----------|---------|
| `ref_countries` | Seed only | Everywhere (dropdowns) |
| `ref_duty_stations` | Seed only | Staffing Tab dropdown |
| `ref_post_grades` / `ref_post_categories` | Seed only | Staffing, Costing |
| `ref_umoja_classes` | Seed only | Activity Costs, Costing |
| `ref_operating_cost_categories` | Seed only | Operating Costs |
| `ref_projects` | AllProjectsPage, ApprovedProjectsPage | Project lists |
| `fact_cost_plan_years` | Seed only | Year pages |
| `fact_approved_projects` | ApprovedProjectsPage | Everywhere per-project |
| `fact_project_positions` | Staffing Tab | Staffing Tab, sp_compute_costing |
| `fact_deployment` | sp_import (legacy) | Deployment Tab (legacy) |
| `fact_operating_costs` | Operating Costs Tab | Operating Costs Tab, Summary |
| `fact_activity_costs` | Activity Costs Tab | Activity Costs Tab, Summary |
| `fact_costing` | Costing Tab (budget fields only) | Costing Tab (LEFT JOIN with SP) |
| `fact_year_project_parameters` | CostPlanEditor, ProjectParametersPage | sp_compute_costing, CostPlanEditor |
| `fact_country_wise_salary_parameter_sets` | SalaryParametersPage, CostPlanEditor | sp_compute_costing, CostPlanEditor |
| `fact_country_specific_grade_salaries` | SalaryParametersPage | sp_compute_costing |
| `fact_position_assignments` | Nothing (future use) | Nothing |

---

## Role System

- Roles loaded from `ref_user_roles` via `GET /api/ref/user-roles`
- `RoleContext` provides `activeRole` and `canEdit` (true unless `REGULAR_USER`)
- Edit buttons, Save, Add Row etc. hidden when `!canEdit`

---

## Percentage Fields (gotcha)

- PSC, CSC PRO/GS/NO, ASHI, Appendix are stored as **decimals** (e.g. `0.27619` = 27.619%)
- Frontend divides by 100 on input, multiplies by 100 on display
- DB type: `DECIMAL(18,6)` for all percentage columns

---

## Backend File Map

| File | What it does |
|------|-------------|
| `server/src/index.ts` | Express setup, mounts routers, port 3001 |
| `server/src/config/db.ts` | SQL Server connection pool (Windows Auth, ODBC). Exports `sql` (from `msnodesqlv8`) and `getPool()` |
| `server/src/routes/ref.ts` | 10 GET endpoints → `usp_get_*` SPs for reference/dropdown data |
| `server/src/routes/costPlanYears.ts` | Year CRUD, approved projects, salary import → all via `usp_*` SPs |
| `server/src/routes/projects.ts` | Per-project data: staffing, costing, operating, activity, params → all via `usp_*` SPs with TVPs for bulk writes |
| `server/src/routes/salaryParameters.ts` | PUT salary params → `usp_save_salary_parameters` with `GradeSalaryRowType` TVP |
| `server/src/routes/health.ts` | Health check endpoint |
| `server/src/middleware/errorHandler.ts` | Global error handler (500 + console.error) |

> **Important:** All route files import `sql` and `getPool` from `../config/db.js` (not from `mssql` directly) to ensure compatibility with the `msnodesqlv8` driver.

---

## Frontend File Map

| File | What it does |
|------|-------------|
| `client/src/App.tsx` | Router config, RoleProvider wrapper |
| `client/src/services/api.ts` | All API calls (axios, baseURL `/api`) |
| `client/src/types/index.ts` | All TypeScript interfaces |
| `client/src/context/RoleContext.tsx` | Role state management |
| `client/src/utils/generatePdf.ts` | PDF generation with jsPDF |
| `client/src/components/Layout.tsx` | App shell: header, nav, outlet |
| `client/src/components/SummaryPanel.tsx` | Budget summary aggregation |
| `client/src/components/ColumnToggle.tsx` | Show/hide AG Grid columns |
