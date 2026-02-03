IF OBJECT_ID('dbo.deployment', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.deployment (
        deployment_id        INT IDENTITY(1,1) PRIMARY KEY,

        cost_plan_year_id    INT NOT NULL,
        approved_project_id  INT NOT NULL,

        post_category_id     INT NOT NULL,
        grade_id             INT NOT NULL,

        -- Monthly planned post-months (finance editable)
        jan_posts DECIMAL(6,2) NULL,
        feb_posts DECIMAL(6,2) NULL,
        mar_posts DECIMAL(6,2) NULL,
        apr_posts DECIMAL(6,2) NULL,
        may_posts DECIMAL(6,2) NULL,
        jun_posts DECIMAL(6,2) NULL,
        jul_posts DECIMAL(6,2) NULL,
        aug_posts DECIMAL(6,2) NULL,
        sep_posts DECIMAL(6,2) NULL,
        oct_posts DECIMAL(6,2) NULL,
        nov_posts DECIMAL(6,2) NULL,
        dec_posts DECIMAL(6,2) NULL,

        -- Derived total (can be computed or materialized later)
        total_post_months AS (
            ISNULL(jan_posts,0) + ISNULL(feb_posts,0) + ISNULL(mar_posts,0) +
            ISNULL(apr_posts,0) + ISNULL(may_posts,0) + ISNULL(jun_posts,0) +
            ISNULL(jul_posts,0) + ISNULL(aug_posts,0) + ISNULL(sep_posts,0) +
            ISNULL(oct_posts,0) + ISNULL(nov_posts,0) + ISNULL(dec_posts,0)
        ),

        is_active BIT NOT NULL CONSTRAINT DF_deployment_is_active DEFAULT (1),

        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_deployment_created_at DEFAULT SYSUTCDATETIME(),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_deployment_updated_at DEFAULT SYSUTCDATETIME(),

        CONSTRAINT FK_deployment_year
            FOREIGN KEY (cost_plan_year_id)
            REFERENCES dbo.cost_plan_years(cost_plan_year_id),

        CONSTRAINT FK_deployment_project
            FOREIGN KEY (approved_project_id)
            REFERENCES dbo.approved_projects(approved_project_id),

        CONSTRAINT FK_deployment_post_category
            FOREIGN KEY (post_category_id)
            REFERENCES dbo.REF_POST_CATEGORIES(post_category_id),

        CONSTRAINT FK_deployment_grade
            FOREIGN KEY (grade_id)
            REFERENCES dbo.REF_GRADES(grade_id),

        -- Prevent duplicate planning rows
        CONSTRAINT UQ_deployment_unique_row
            UNIQUE (cost_plan_year_id, approved_project_id, post_category_id, grade_id)
    );
END
GO

INSERT INTO dbo.deployment
(
    cost_plan_year_id,
    approved_project_id,
    post_category_id,
    grade_id
)
SELECT
    y.cost_plan_year_id,
    p.approved_project_id,
    pc.post_category_id,
    g.grade_id
FROM dbo.cost_plan_years y
JOIN dbo.approved_projects p
    ON p.cost_plan_year_id = y.cost_plan_year_id
JOIN dbo.REF_POST_CATEGORIES pc
    ON pc.is_active = 1
JOIN dbo.REF_GRADES g
    ON g.is_active = 1
WHERE y.year_code = 2026;


IF OBJECT_ID('dbo.staff_costing', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.staff_costing (
        staff_costing_id     INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_staff_costing PRIMARY KEY,

        cost_plan_year_id    INT NOT NULL,
        approved_project_id  INT NOT NULL,

        post_category_id     INT NOT NULL,
        grade_id             INT NOT NULL,

        cwsp_id              INT NOT NULL,           -- CWSP row used
        local_currency       NVARCHAR(10) NULL,      -- from CWSP
        exchange_rate        DECIMAL(18,6) NULL,     -- from CWSP (local->USD or 1)

        -- Store multipliers used (traceability)
        post_adjustment_pct      DECIMAL(9,4) NULL,  -- e.g. 0.6400
        common_staff_cost_pct    DECIMAL(9,4) NULL,  -- e.g. 0.6500
        appendix_pct             DECIMAL(9,4) NULL,  -- e.g. 0.0100
        ashi_pct                 DECIMAL(9,4) NULL,  -- e.g. 0.0600

        -- Annual base salary for this grade (from CWSP)
        annual_salary_amount     DECIMAL(18,2) NOT NULL,

        -- Derived amounts (computed by backend)
        annual_cost_per_post     DECIMAL(18,2) NULL,

        -- Quarterly totals (computed by backend, typically based on deployment counts)
        q1_cost DECIMAL(18,2) NULL,
        q2_cost DECIMAL(18,2) NULL,
        q3_cost DECIMAL(18,2) NULL,
        q4_cost DECIMAL(18,2) NULL,

        -- Stored total (backend-calculated)
        total_cost DECIMAL(18,2) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_staff_costing_created_at DEFAULT SYSUTCDATETIME(),
        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_staff_costing_updated_at DEFAULT SYSUTCDATETIME(),

        CONSTRAINT FK_staff_costing_year
            FOREIGN KEY (cost_plan_year_id)
            REFERENCES dbo.cost_plan_years(cost_plan_year_id),

        CONSTRAINT FK_staff_costing_project
            FOREIGN KEY (approved_project_id)
            REFERENCES dbo.approved_projects(approved_project_id),

        CONSTRAINT FK_staff_costing_post_category
            FOREIGN KEY (post_category_id)
            REFERENCES dbo.REF_POST_CATEGORIES(post_category_id),

        CONSTRAINT FK_staff_costing_grade
            FOREIGN KEY (grade_id)
            REFERENCES dbo.REF_GRADES(grade_id),

        CONSTRAINT FK_staff_costing_cwsp
            FOREIGN KEY (cwsp_id)
            REFERENCES dbo.cwsp_header(cwsp_id),

        CONSTRAINT UQ_staff_costing_unique_row
            UNIQUE (cost_plan_year_id, approved_project_id, post_category_id, grade_id)
    );

    -- Helpful indexes
    CREATE INDEX IX_staff_costing_year_project
        ON dbo.staff_costing(cost_plan_year_id, approved_project_id);

    CREATE INDEX IX_staff_costing_cat_grade
        ON dbo.staff_costing(post_category_id, grade_id);

    CREATE INDEX IX_staff_costing_cwsp
        ON dbo.staff_costing(cwsp_id);
END
GO


-- Optional: delete existing computed costing rows for one year
-- DELETE FROM dbo.staff_costing WHERE cost_plan_year_id = @year_id;

INSERT INTO dbo.staff_costing
(
    cost_plan_year_id,
    approved_project_id,
    post_category_id,
    grade_id,
    cwsp_id,
    local_currency,
    exchange_rate,
    post_adjustment_pct,
    common_staff_cost_pct,
    appendix_pct,
    ashi_pct,
    annual_salary_amount,
    annual_cost_per_post,
    q1_cost, q2_cost, q3_cost, q4_cost
)
SELECT
    d.cost_plan_year_id,
    d.approved_project_id,
    d.post_category_id,
    d.grade_id,

    h.cwsp_id,
    h.local_currency,
    h.exchange_rate,

    h.post_adjustment_pct,

    CASE pc.category_code
        WHEN 'PROF' THEN h.common_staff_cost_prof_pct
        WHEN 'GEN'  THEN h.common_staff_cost_gen_pct
        WHEN 'NO'   THEN h.common_staff_cost_no_pct
        ELSE 0
    END AS common_staff_cost_pct,

    h.appendix_pct,
    h.ashi_pct,

    r.annual_salary_amount,

    -- annual_cost_per_post (stacked multipliers)
    r.annual_salary_amount
      * (1 + ISNULL(h.post_adjustment_pct,0))
      * (1 + ISNULL(
            CASE pc.category_code
                WHEN 'PROF' THEN h.common_staff_cost_prof_pct
                WHEN 'GEN'  THEN h.common_staff_cost_gen_pct
                WHEN 'NO'   THEN h.common_staff_cost_no_pct
                ELSE 0
            END, 0))
      * (1 + ISNULL(h.appendix_pct,0))
      * (1 + ISNULL(h.ashi_pct,0)) AS annual_cost_per_post,

    -- Q1 cost
    (
      (ISNULL(d.jan_posts,0) + ISNULL(d.feb_posts,0) + ISNULL(d.mar_posts,0))
      * (
          (r.annual_salary_amount
            * (1 + ISNULL(h.post_adjustment_pct,0))
            * (1 + ISNULL(CASE pc.category_code
                    WHEN 'PROF' THEN h.common_staff_cost_prof_pct
                    WHEN 'GEN'  THEN h.common_staff_cost_gen_pct
                    WHEN 'NO'   THEN h.common_staff_cost_no_pct
                    ELSE 0 END,0))
            * (1 + ISNULL(h.appendix_pct,0))
            * (1 + ISNULL(h.ashi_pct,0))
          ) / 12.0
        )
    ) AS q1_cost,

    -- Q2 cost
    (
      (ISNULL(d.apr_posts,0) + ISNULL(d.may_posts,0) + ISNULL(d.jun_posts,0))
      * (
          (r.annual_salary_amount
            * (1 + ISNULL(h.post_adjustment_pct,0))
            * (1 + ISNULL(CASE pc.category_code
                    WHEN 'PROF' THEN h.common_staff_cost_prof_pct
                    WHEN 'GEN'  THEN h.common_staff_cost_gen_pct
                    WHEN 'NO'   THEN h.common_staff_cost_no_pct
                    ELSE 0 END,0))
            * (1 + ISNULL(h.appendix_pct,0))
            * (1 + ISNULL(h.ashi_pct,0))
          ) / 12.0
        )
    ) AS q2_cost,

    -- Q3 cost
    (
      (ISNULL(d.jul_posts,0) + ISNULL(d.aug_posts,0) + ISNULL(d.sep_posts,0))
      * (
          (r.annual_salary_amount
            * (1 + ISNULL(h.post_adjustment_pct,0))
            * (1 + ISNULL(CASE pc.category_code
                    WHEN 'PROF' THEN h.common_staff_cost_prof_pct
                    WHEN 'GEN'  THEN h.common_staff_cost_gen_pct
                    WHEN 'NO'   THEN h.common_staff_cost_no_pct
                    ELSE 0 END,0))
            * (1 + ISNULL(h.appendix_pct,0))
            * (1 + ISNULL(h.ashi_pct,0))
          ) / 12.0
        )
    ) AS q3_cost,

    -- Q4 cost
    (
      (ISNULL(d.oct_posts,0) + ISNULL(d.nov_posts,0) + ISNULL(d.dec_posts,0))
      * (
          (r.annual_salary_amount
            * (1 + ISNULL(h.post_adjustment_pct,0))
            * (1 + ISNULL(CASE pc.category_code
                    WHEN 'PROF' THEN h.common_staff_cost_prof_pct
                    WHEN 'GEN'  THEN h.common_staff_cost_gen_pct
                    WHEN 'NO'   THEN h.common_staff_cost_no_pct
                    ELSE 0 END,0))
            * (1 + ISNULL(h.appendix_pct,0))
            * (1 + ISNULL(h.ashi_pct,0))
          ) / 12.0
        )
    ) AS q4_cost

FROM dbo.deployment d
JOIN dbo.approved_projects ap
    ON ap.approved_project_id = d.approved_project_id
JOIN dbo.REF_POST_CATEGORIES pc
    ON pc.post_category_id = d.post_category_id
JOIN dbo.cwsp_header h
    ON h.cost_plan_year_id = d.cost_plan_year_id
   AND h.country_id = ap.country_id
JOIN dbo.cwsp_grade_rates r
    ON r.cwsp_id = h.cwsp_id
   AND r.grade_id = d.grade_id;


/* ============================================================
   OPC_ITEMS (Option 1) - Columns Only (No computed columns)
   - Stores project-year OPC inputs and saved totals
   - References REF_OPC_CATEGORIES for template line selection
   - Backend handles computations and special-case overrides
   ============================================================ */

IF OBJECT_ID('dbo.OPC_ITEMS', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.OPC_ITEMS
    (
        opc_item_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_OPC_ITEMS PRIMARY KEY,

        -- Context
        cost_plan_year_id   INT NOT NULL,
        approved_project_id INT NOT NULL,

        -- Reference line (subcat + commitment + umoja class via ref)
        opc_category_id     INT NOT NULL,

        -- Inputs
        number_of_units DECIMAL(18,2) NULL,
        duration        DECIMAL(18,2) NULL,
        rate_per_unit   DECIMAL(18,2) NULL,

        -- Stored annual cost (backend-calculated)
        annual_cost DECIMAL(18,2) NULL,

        -- Quarter allocations (manual or backend-derived)
        q1 DECIMAL(18,2) NULL,
        q2 DECIMAL(18,2) NULL,
        q3 DECIMAL(18,2) NULL,
        q4 DECIMAL(18,2) NULL,

        -- Stored quarter total (backend-calculated)
        total_quarters DECIMAL(18,2) NULL,

        -- Budget tracking
        released_budget_approved DECIMAL(18,2) NULL,
        this_request             DECIMAL(18,2) NULL,

        -- Stored total released budget (backend-calculated)
        total_released_budget DECIMAL(18,2) NULL,

        -- Optional free text for rare-case overrides / justification
        notes NVARCHAR(500) NULL,

        -- Housekeeping
        is_active  BIT NOT NULL
            CONSTRAINT DF_OPC_ITEMS_is_active DEFAULT (1),

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_OPC_ITEMS_created_at DEFAULT (SYSUTCDATETIME()),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_OPC_ITEMS_updated_at DEFAULT (SYSUTCDATETIME())
    );

    /* -------------------------
       Foreign Keys
       ------------------------- */
    ALTER TABLE dbo.OPC_ITEMS
        ADD CONSTRAINT FK_OPC_ITEMS_cost_plan_year
            FOREIGN KEY (cost_plan_year_id)
            REFERENCES dbo.cost_plan_years(cost_plan_year_id);

    ALTER TABLE dbo.OPC_ITEMS
        ADD CONSTRAINT FK_OPC_ITEMS_approved_project
            FOREIGN KEY (approved_project_id)
            REFERENCES dbo.approved_projects(approved_project_id);

    ALTER TABLE dbo.OPC_ITEMS
        ADD CONSTRAINT FK_OPC_ITEMS_ref_opc_categories
            FOREIGN KEY (opc_category_id)
            REFERENCES dbo.REF_OPC_CATEGORIES(opc_category_id);

    /* -------------------------
       Helpful indexes
       ------------------------- */
    CREATE INDEX IX_OPC_ITEMS_year_project
        ON dbo.OPC_ITEMS(cost_plan_year_id, approved_project_id);

    CREATE INDEX IX_OPC_ITEMS_opc_category
        ON dbo.OPC_ITEMS(opc_category_id);

    CREATE INDEX IX_OPC_ITEMS_active
        ON dbo.OPC_ITEMS(is_active);

END
GO

IF OBJECT_ID('dbo.project_positions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.project_positions (
        project_position_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_project_positions PRIMARY KEY,

        cost_plan_year_id   INT NOT NULL,
        approved_project_id INT NOT NULL,

        position_id         NVARCHAR(50) NOT NULL,     -- Umoja Position ID
        position_title      NVARCHAR(150) NULL,

        post_category_id    INT NOT NULL,
        grade_id            INT NOT NULL,

        duty_station_id     INT NULL,
        country_id          INT NULL,

        is_active BIT NOT NULL
            CONSTRAINT DF_project_positions_is_active DEFAULT (1),

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_project_positions_created_at DEFAULT SYSUTCDATETIME(),
        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_project_positions_updated_at DEFAULT SYSUTCDATETIME(),

        CONSTRAINT FK_project_positions_year
            FOREIGN KEY (cost_plan_year_id)
            REFERENCES dbo.cost_plan_years(cost_plan_year_id),

        CONSTRAINT FK_project_positions_project
            FOREIGN KEY (approved_project_id)
            REFERENCES dbo.approved_projects(approved_project_id),

        CONSTRAINT FK_project_positions_post_category
            FOREIGN KEY (post_category_id)
            REFERENCES dbo.REF_POST_CATEGORIES(post_category_id),

        CONSTRAINT FK_project_positions_grade
            FOREIGN KEY (grade_id)
            REFERENCES dbo.REF_GRADES(grade_id),

        CONSTRAINT FK_project_positions_duty_station
            FOREIGN KEY (duty_station_id)
            REFERENCES dbo.REF_DUTY_STATIONS(duty_station_id),

        CONSTRAINT FK_project_positions_country
            FOREIGN KEY (country_id)
            REFERENCES dbo.REF_COUNTRIES(country_id),

        CONSTRAINT UQ_project_positions_unique
            UNIQUE (cost_plan_year_id, approved_project_id, position_id)
    );

    CREATE INDEX IX_project_positions_year_project
        ON dbo.project_positions(cost_plan_year_id, approved_project_id);

    CREATE INDEX IX_project_positions_position
        ON dbo.project_positions(position_id);
END
GO

IF OBJECT_ID('dbo.position_assignments', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.position_assignments (
        position_assignment_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_position_assignments PRIMARY KEY,

        project_position_id INT NOT NULL,              -- links to project_positions

        person_identifier NVARCHAR(80) NULL,           -- can be staff index no / employee id / placeholder
        person_name       NVARCHAR(150) NULL,          -- optional display

        encumbered BIT NULL,                           -- filled or not (if you want explicit)
        assignment_start_date DATE NULL,
        assignment_end_date   DATE NULL,

        remarks NVARCHAR(500) NULL,

        is_active BIT NOT NULL
            CONSTRAINT DF_position_assignments_is_active DEFAULT (1),

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_position_assignments_created_at DEFAULT SYSUTCDATETIME(),
        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_position_assignments_updated_at DEFAULT SYSUTCDATETIME(),

        CONSTRAINT FK_position_assignments_project_position
            FOREIGN KEY (project_position_id)
            REFERENCES dbo.project_positions(project_position_id)
    );

    CREATE INDEX IX_position_assignments_project_position
        ON dbo.position_assignments(project_position_id);

    CREATE INDEX IX_position_assignments_person_identifier
        ON dbo.position_assignments(person_identifier);
END
GO