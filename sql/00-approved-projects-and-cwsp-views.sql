-- ============================================================
-- Stub / compatibility objects for CostPlans-DDL.sql
-- Run this BEFORE the sections in CostPlans-DDL.sql that reference
-- approved_projects, cwsp_header, and cwsp_grade_rates.
-- ============================================================

-- 1) approved_projects (referenced by deployment, staff_costing, OPC_ITEMS, project_positions)
IF OBJECT_ID('dbo.approved_projects', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.approved_projects (
        approved_project_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_approved_projects PRIMARY KEY,

        cost_plan_year_id   INT NOT NULL,
        project_code        NVARCHAR(50) NOT NULL,
        project_name        NVARCHAR(200) NULL,
        country_id          INT NULL,
        division            NVARCHAR(100) NULL,
        branch              NVARCHAR(100) NULL,
        section_country     NVARCHAR(200) NULL,
        trust_fund          NVARCHAR(100) NULL,
        grant_code          NVARCHAR(50) NULL,
        earmarking          NVARCHAR(100) NULL,
        is_active           BIT NOT NULL CONSTRAINT DF_approved_projects_is_active DEFAULT (1),
        created_at          DATETIME2(0) NOT NULL CONSTRAINT DF_approved_projects_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at          DATETIME2(0) NOT NULL CONSTRAINT DF_approved_projects_updated_at DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT FK_approved_projects_year
            FOREIGN KEY (cost_plan_year_id)
            REFERENCES dbo.cost_plan_years(cost_plan_year_id),
        CONSTRAINT FK_approved_projects_country
            FOREIGN KEY (country_id)
            REFERENCES dbo.REF_COUNTRIES(country_id),
        CONSTRAINT UQ_approved_projects_year_code
            UNIQUE (cost_plan_year_id, project_code)
    );

    CREATE INDEX IX_approved_projects_year
        ON dbo.approved_projects(cost_plan_year_id);
END
GO

-- 2) cwsp_header table (staff_costing FK references cwsp_header(cwsp_id); SQL Server cannot FK to a view)
IF OBJECT_ID('dbo.cwsp_header', 'V') IS NOT NULL
    DROP VIEW dbo.cwsp_header;
GO
IF OBJECT_ID('dbo.cwsp_header', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.cwsp_header (
        cwsp_id              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_cwsp_header PRIMARY KEY,
        cost_plan_year_id    INT NOT NULL,
        country_id           INT NOT NULL,
        post_adjustment_pct  DECIMAL(6,3) NULL,
        common_staff_cost_prof_pct DECIMAL(6,3) NULL,
        common_staff_cost_gen_pct  DECIMAL(6,3) NULL,
        common_staff_cost_no_pct   DECIMAL(6,3) NULL,
        exchange_rate        DECIMAL(18,6) NULL,
        appendix_pct         DECIMAL(6,3) NULL,
        ashi_pct              DECIMAL(6,3) NULL,
        local_currency       NVARCHAR(3) NULL,
        is_active            BIT NOT NULL CONSTRAINT DF_cwsp_header_is_active DEFAULT (1),
        created_at           DATETIME2(0) NOT NULL CONSTRAINT DF_cwsp_header_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at           DATETIME2(0) NOT NULL CONSTRAINT DF_cwsp_header_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_cwsp_header_year FOREIGN KEY (cost_plan_year_id) REFERENCES dbo.cost_plan_years(cost_plan_year_id),
        CONSTRAINT FK_cwsp_header_country FOREIGN KEY (country_id) REFERENCES dbo.REF_COUNTRIES(country_id)
    );
    CREATE UNIQUE INDEX UQ_cwsp_header_year_country ON dbo.cwsp_header(cost_plan_year_id, country_id);
END
GO

-- Sync from CWSP_PARAMETER_SETS into cwsp_header (run after CWSP seed in CostPlans-DDL.sql)
IF OBJECT_ID('dbo.CWSP_PARAMETER_SETS', 'U') IS NOT NULL
BEGIN
    MERGE dbo.cwsp_header AS t
    USING (
        SELECT cost_plan_year_id, country_id,
               post_adjustment_pct, common_staff_cost_prof_pct, common_staff_cost_gen_pct, common_staff_cost_no_pct,
               exchange_rate_to_usd, appendix_pct, ashi_pct, local_currency, is_active, created_at, updated_at
        FROM dbo.CWSP_PARAMETER_SETS
    ) AS s
    ON t.cost_plan_year_id = s.cost_plan_year_id AND t.country_id = s.country_id
    WHEN NOT MATCHED THEN
        INSERT (cost_plan_year_id, country_id, post_adjustment_pct, common_staff_cost_prof_pct, common_staff_cost_gen_pct,
                common_staff_cost_no_pct, exchange_rate, appendix_pct, ashi_pct, local_currency, is_active, created_at, updated_at)
        VALUES (s.cost_plan_year_id, s.country_id, s.post_adjustment_pct, s.common_staff_cost_prof_pct, s.common_staff_cost_gen_pct,
                s.common_staff_cost_no_pct, s.exchange_rate_to_usd, s.appendix_pct, s.ashi_pct, s.local_currency, s.is_active, s.created_at, s.updated_at);
END
GO

-- cwsp_grade_rates: table so staff_costing FK and inserts work (map CWSP_GRADE_AMOUNTS via cwsp_header)
IF OBJECT_ID('dbo.cwsp_grade_rates', 'V') IS NOT NULL
    DROP VIEW dbo.cwsp_grade_rates;
GO
IF OBJECT_ID('dbo.cwsp_grade_rates', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.cwsp_grade_rates (
        cwsp_grade_rate_id   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_cwsp_grade_rates PRIMARY KEY,
        cwsp_id              INT NOT NULL,
        grade_id             INT NOT NULL,
        annual_salary_amount DECIMAL(18,2) NOT NULL,
        local_currency       NVARCHAR(3) NULL,
        is_active            BIT NOT NULL CONSTRAINT DF_cwsp_grade_rates_is_active DEFAULT (1),
        created_at           DATETIME2(0) NOT NULL CONSTRAINT DF_cwsp_grade_rates_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at           DATETIME2(0) NOT NULL CONSTRAINT DF_cwsp_grade_rates_updated_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_cwsp_grade_rates_header FOREIGN KEY (cwsp_id) REFERENCES dbo.cwsp_header(cwsp_id),
        CONSTRAINT FK_cwsp_grade_rates_grade FOREIGN KEY (grade_id) REFERENCES dbo.REF_GRADES(grade_id),
        CONSTRAINT UQ_cwsp_grade_rates_pair UNIQUE (cwsp_id, grade_id)
    );
END
GO

-- Populate cwsp_grade_rates from CWSP_GRADE_AMOUNTS (run after CWSP seed)
IF OBJECT_ID('dbo.CWSP_GRADE_AMOUNTS', 'U') IS NOT NULL AND OBJECT_ID('dbo.cwsp_header', 'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.cwsp_grade_rates (cwsp_id, grade_id, annual_salary_amount, local_currency, is_active)
    SELECT h.cwsp_id, g.grade_id, g.annual_amount, g.local_currency, g.is_active
    FROM dbo.CWSP_GRADE_AMOUNTS g
    JOIN dbo.CWSP_PARAMETER_SETS p ON p.cwsp_set_id = g.cwsp_set_id
    JOIN dbo.cwsp_header h ON h.cost_plan_year_id = p.cost_plan_year_id AND h.country_id = p.country_id
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.cwsp_grade_rates r
        WHERE r.cwsp_id = h.cwsp_id AND r.grade_id = g.grade_id
    );
END
GO
