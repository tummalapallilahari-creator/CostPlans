#!/usr/bin/env bash
# Run DDL in correct order against SQL Server in Docker.
# Prereq: container named "sqlserver" running, CostPlans database created.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

SA_PASSWORD="${SA_PASSWORD:-YourStrong@Pass123}"

echo "Creating CostPlans database if not exists..."
docker exec sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C -Q "IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'CostPlans') CREATE DATABASE CostPlans;" 2>/dev/null || true

echo "Running DDL part1 (ref tables, cost_plan_years, CWSP)..."
cat sql/ddl-part1.sql | docker exec -i sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -d CostPlans -C

echo "Running 00 stub (approved_projects, cwsp_header, cwsp_grade_rates)..."
cat sql/00-approved-projects-and-cwsp-views.sql | docker exec -i sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -d CostPlans -C

echo "Running DDL part2 (deployment, staff_costing, OPC_ITEMS, etc.)..."
cat sql/ddl-part2.sql | docker exec -i sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -d CostPlans -C

echo "Done."
