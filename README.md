# Cost Plans System – Full-Stack

Full-stack **Cost Plans System** with **React** (JavaScript), **Node.js/Express**, and **MS SQL Server**. The app supports year-scoped planning, reference data, and (over time) staffing, OPC, scenarios, and reporting as described in `requirements.txt`.

## What’s in the repo

| Path | Description |
|------|-------------|
| `backend/` | Node.js + Express API; connects to MS SQL, exposes REST endpoints |
| `frontend/` | React (JavaScript) + Vite; Dashboard, Planning Years, Reference Data |
| `CostPlans-DDL.sql` | Main DB schema: reference tables, cost_plan_years, CWSP, deployment, staff_costing, OPC_ITEMS, etc. |
| `sql/00-approved-projects-and-cwsp-views.sql` | Stub tables/views so DDL runs: `approved_projects`, `cwsp_header`, `cwsp_grade_rates` |
| `requirements.txt` | Product and flow description (not a pip/package file) |

## Prerequisites

- **Node.js** 18+ (for backend and frontend)
- **MS SQL Server** (local or remote) with a database for Cost Plans
- SQL client (e.g. SSMS, Azure Data Studio) to run the DDL scripts

## 1. Database setup

1. Create a database (e.g. `CostPlans`) in MS SQL Server.

2. Run **CostPlans-DDL.sql** in order, but **stop before** the `deployment` table section.  
   That means: run all reference tables, `cost_plan_years`, `CWSP_PARAMETER_SETS`, `CWSP_GRADE_AMOUNTS`, and the CWSP sample load (MERGE/INSERT for CWSP).  
   Do **not** run the `deployment` table creation/insert yet (it depends on `approved_projects`).

3. Run **sql/00-approved-projects-and-cwsp-views.sql**.  
   This creates:
   - `approved_projects`
   - `cwsp_header` (table, synced from `CWSP_PARAMETER_SETS`)
   - `cwsp_grade_rates` (table, synced from `CWSP_GRADE_AMOUNTS`)

4. Run the **rest of CostPlans-DDL.sql**: `deployment`, `staff_costing`, `OPC_ITEMS`, `project_positions`, `position_assignments`, and any remaining objects.

5. (Optional) Insert at least one row into `approved_projects` for a given `cost_plan_year_id` so the deployment insert in the DDL can succeed. If you skip the deployment insert, the app will still run; planning years and reference APIs will work.

## 2. Backend

```bash
cd backend
cp .env.example .env
# Edit .env: DB_SERVER, DB_USER, DB_PASSWORD, DB_NAME, etc.
npm install
npm run dev
```

API runs at **http://localhost:5000**. Endpoints:

- `GET /api/health` – health check  
- `GET /api/planning-years` – list planning years  
- `GET /api/planning-years/:id` – one planning year  
- `GET /api/reference/countries` – countries  
- `GET /api/reference/grades` – grades  
- `GET /api/reference/post-categories` – post categories  
- `GET /api/reference/umoja-classes` – Umoja classes  
- `GET /api/reference/cost-categories` – cost categories  
- `GET /api/reference/duty-stations` – duty stations  

## 3. Frontend

```bash
cd frontend
npm install
npm run dev
```

App runs at **http://localhost:3000**. Vite proxies `/api` to the backend (http://localhost:5000).

- **Dashboard** – API status and planning years summary  
- **Planning Years** – table of planning years  
- **Reference Data** – tabs for countries, grades, post categories, Umoja classes, cost categories, duty stations  

## 4. Tech stack

- **Frontend:** React 18, JavaScript, React Router, Vite  
- **Backend:** Node.js, Express, `mssql` driver, CORS, `dotenv`  
- **Database:** MS SQL Server; schema and seed in `CostPlans-DDL.sql` and `sql/00-approved-projects-and-cwsp-views.sql`  

## 5. If you need something else

- **Auth / RBAC:** not implemented yet; add when you’re ready (e.g. JWT, “My Projects” by user).  
- **More APIs:** add routes under `backend/src/routes/` and tables/views as in the DDL (e.g. projects, deployment, OPC, scenarios).  
- **Calculation engine:** requirements describe a deterministic recompute; implement as a separate service or backend module that reads from deployment/CWSP/OPC and writes to staff_costing, summary_lines, etc.  

If you want a different stack (e.g. TypeScript, different DB driver, or deployment steps), say what you prefer and we can adjust.
