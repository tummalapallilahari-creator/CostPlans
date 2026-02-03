-- ============================================================
-- 1) REF_COUNTRIES (Sample data entered)
-- ============================================================
IF OBJECT_ID('dbo.REF_COUNTRIES', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.REF_COUNTRIES (
    country_id     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    country_name   NVARCHAR(120) NOT NULL,
    iso2_code      CHAR(2) NULL,
    iso3_code      CHAR(3) NULL,
    is_active      BIT NOT NULL CONSTRAINT DF_REF_COUNTRIES_is_active DEFAULT (1),
    created_at     DATETIME2(0) NOT NULL CONSTRAINT DF_REF_COUNTRIES_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at     DATETIME2(0) NOT NULL CONSTRAINT DF_REF_COUNTRIES_updated_at DEFAULT (SYSUTCDATETIME())
  );

  ALTER TABLE dbo.REF_COUNTRIES
    ADD CONSTRAINT UQ_REF_COUNTRIES_country_name UNIQUE (country_name);

  ALTER TABLE dbo.REF_COUNTRIES
    ADD CONSTRAINT UQ_REF_COUNTRIES_iso2 UNIQUE (iso2_code);

  ALTER TABLE dbo.REF_COUNTRIES
    ADD CONSTRAINT UQ_REF_COUNTRIES_iso3 UNIQUE (iso3_code);
END
GO

-- ============================================================
-- 2) REF_DUTY_STATIONS (mapped to country)
-- ============================================================
IF OBJECT_ID('dbo.REF_DUTY_STATIONS', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.REF_DUTY_STATIONS (
    duty_station_id   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    duty_station_name NVARCHAR(120) NOT NULL,
    country_id        INT NOT NULL,
    is_active         BIT NOT NULL CONSTRAINT DF_REF_DUTY_STATIONS_is_active DEFAULT (1),
    created_at        DATETIME2(0) NOT NULL CONSTRAINT DF_REF_DUTY_STATIONS_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at        DATETIME2(0) NOT NULL CONSTRAINT DF_REF_DUTY_STATIONS_updated_at DEFAULT (SYSUTCDATETIME())
  );

  ALTER TABLE dbo.REF_DUTY_STATIONS
    ADD CONSTRAINT UQ_REF_DUTY_STATIONS_name UNIQUE (duty_station_name);

  ALTER TABLE dbo.REF_DUTY_STATIONS
    ADD CONSTRAINT FK_REF_DUTY_STATIONS_country
    FOREIGN KEY (country_id) REFERENCES dbo.REF_COUNTRIES(country_id);
END
GO

-- ============================================================
-- 3) REF_POST_CATEGORIES (Sample data entered)
-- Examples: PROFESSIONAL, GENERAL_SERVICE, NATIONAL_OFFICER, UNV_INTL, UNV_NATIONAL
-- ============================================================
IF OBJECT_ID('dbo.REF_POST_CATEGORIES', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.REF_POST_CATEGORIES (
    post_category_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    category_code    NVARCHAR(40) NOT NULL,
    category_name    NVARCHAR(120) NOT NULL,
    description      NVARCHAR(255) NULL,
    is_active        BIT NOT NULL CONSTRAINT DF_REF_POST_CATEGORIES_is_active DEFAULT (1),
    created_at       DATETIME2(0) NOT NULL CONSTRAINT DF_REF_POST_CATEGORIES_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at       DATETIME2(0) NOT NULL CONSTRAINT DF_REF_POST_CATEGORIES_updated_at DEFAULT (SYSUTCDATETIME())
  );

  ALTER TABLE dbo.REF_POST_CATEGORIES
    ADD CONSTRAINT UQ_REF_POST_CATEGORIES_code UNIQUE (category_code);

  ALTER TABLE dbo.REF_POST_CATEGORIES
    ADD CONSTRAINT UQ_REF_POST_CATEGORIES_name UNIQUE (category_name);
END
GO

-- ============================================================
-- 4) REF_GRADES (Sample data entered)
-- Examples: D-1, P-5, GS7, NO-A, etc.
-- ============================================================
IF OBJECT_ID('dbo.REF_GRADES', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.REF_GRADES (
    grade_id       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    grade_code     NVARCHAR(20) NOT NULL,
    grade_family   NVARCHAR(20) NULL,   -- P, D, GS, NO, UNV
    display_order  INT NULL,
    is_active      BIT NOT NULL CONSTRAINT DF_REF_GRADES_is_active DEFAULT (1),
    created_at     DATETIME2(0) NOT NULL CONSTRAINT DF_REF_GRADES_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at     DATETIME2(0) NOT NULL CONSTRAINT DF_REF_GRADES_updated_at DEFAULT (SYSUTCDATETIME())
  );

  ALTER TABLE dbo.REF_GRADES
    ADD CONSTRAINT UQ_REF_GRADES_code UNIQUE (grade_code);
END
GO


-- ============================================================
-- 6) REF_UMOJA_CLASSES (Sample data entered)
-- Examples: 010, 155, etc.
-- ============================================================
IF OBJECT_ID('dbo.REF_UMOJA_CLASSES', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.REF_UMOJA_CLASSES (
    umoja_class_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    class_code     NVARCHAR(10) NOT NULL,
    class_name     NVARCHAR(120) NULL,
    description    NVARCHAR(255) NULL,
    is_active      BIT NOT NULL CONSTRAINT DF_REF_UMOJA_CLASSES_is_active DEFAULT (1),
    created_at     DATETIME2(0) NOT NULL CONSTRAINT DF_REF_UMOJA_CLASSES_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at     DATETIME2(0) NOT NULL CONSTRAINT DF_REF_UMOJA_CLASSES_updated_at DEFAULT (SYSUTCDATETIME())
  );

  ALTER TABLE dbo.REF_UMOJA_CLASSES
    ADD CONSTRAINT UQ_REF_UMOJA_CLASSES_code UNIQUE (class_code);
END
GO

-- ============================================================
-- 7) REF_COST_CATEGORIES
-- Examples: Staff Personnel, Activities & Operating Costs, Grants, PSC, TOTAL
-- ============================================================
IF OBJECT_ID('dbo.REF_COST_CATEGORIES', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.REF_COST_CATEGORIES (
    cost_category_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    category_code    NVARCHAR(40) NOT NULL,
    category_name    NVARCHAR(120) NOT NULL,
    display_order    INT NULL,
    is_active        BIT NOT NULL CONSTRAINT DF_REF_COST_CATEGORIES_is_active DEFAULT (1),
    created_at       DATETIME2(0) NOT NULL CONSTRAINT DF_REF_COST_CATEGORIES_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at       DATETIME2(0) NOT NULL CONSTRAINT DF_REF_COST_CATEGORIES_updated_at DEFAULT (SYSUTCDATETIME())
  );

  ALTER TABLE dbo.REF_COST_CATEGORIES
    ADD CONSTRAINT UQ_REF_COST_CATEGORIES_code UNIQUE (category_code);

  ALTER TABLE dbo.REF_COST_CATEGORIES
    ADD CONSTRAINT UQ_REF_COST_CATEGORIES_name UNIQUE (category_name);
END
GO

-- ============================================================
-- 8) REF_COST_SUBCATEGORIES (belongs to a category)
-- ============================================================
IF OBJECT_ID('dbo.REF_COST_SUBCATEGORIES', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.REF_COST_SUBCATEGORIES (
    cost_subcategory_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    cost_category_id    INT NOT NULL,
    subcategory_code    NVARCHAR(60) NOT NULL,
    subcategory_name    NVARCHAR(160) NOT NULL,
    display_order       INT NULL,
    is_active           BIT NOT NULL CONSTRAINT DF_REF_COST_SUBCATEGORIES_is_active DEFAULT (1),
    created_at          DATETIME2(0) NOT NULL CONSTRAINT DF_REF_COST_SUBCATEGORIES_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at          DATETIME2(0) NOT NULL CONSTRAINT DF_REF_COST_SUBCATEGORIES_updated_at DEFAULT (SYSUTCDATETIME())
  );

  ALTER TABLE dbo.REF_COST_SUBCATEGORIES
    ADD CONSTRAINT UQ_REF_COST_SUBCATEGORIES_code UNIQUE (subcategory_code);

  ALTER TABLE dbo.REF_COST_SUBCATEGORIES
    ADD CONSTRAINT FK_REF_COST_SUBCATEGORIES_category
    FOREIGN KEY (cost_category_id) REFERENCES dbo.REF_COST_CATEGORIES(cost_category_id);
END
GO




-- ============================================================
-- REF_OPC_CATEGORIES
-- Parent: REF_UMOJA_CLASSES(class_code)
-- ============================================================

IF OBJECT_ID('dbo.REF_OPC_CATEGORIES', 'U') IS NOT NULL DROP TABLE dbo.REF_OPC_CATEGORIES;
BEGIN
    CREATE TABLE dbo.REF_OPC_CATEGORIES
    (
        opc_category_id        INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_REF_OPC_CATEGORIES PRIMARY KEY,

        umoja_class_code       NVARCHAR(10) NOT NULL,   -- FK to REF_UMOJA_CLASSES.class_code
        category_name          NVARCHAR(120) NOT NULL,  -- e.g. "Contract Service"
        subcategory_name       NVARCHAR(200) NOT NULL,  -- e.g. "Individual contractor"
        commitment_item_code   NVARCHAR(20) NULL,       -- Commitment Item code (IMIS may be missing)

        sort_order             INT NULL,
        is_active              BIT NOT NULL
            CONSTRAINT DF_REF_OPC_CATEGORIES_is_active DEFAULT (1),

        created_at             DATETIME2(0) NOT NULL
            CONSTRAINT DF_REF_OPC_CATEGORIES_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at             DATETIME2(0) NOT NULL
            CONSTRAINT DF_REF_OPC_CATEGORIES_updated_at DEFAULT (SYSUTCDATETIME())
    );

    -- Uniqueness: don't allow duplicate template rows
    ALTER TABLE dbo.REF_OPC_CATEGORIES
        ADD CONSTRAINT UQ_REF_OPC_CATEGORIES_unique
        UNIQUE (umoja_class_code, category_name, subcategory_name);

    -- FK: parent umoja class
    ALTER TABLE dbo.REF_OPC_CATEGORIES
        ADD CONSTRAINT FK_REF_OPC_CATEGORIES_UMOJA_CLASS_CODE
        FOREIGN KEY (umoja_class_code)
        REFERENCES dbo.REF_UMOJA_CLASSES (class_code);

    -- Helpful index for reporting / filtering by class + category
    CREATE INDEX IX_REF_OPC_CATEGORIES_class_category
        ON dbo.REF_OPC_CATEGORIES (umoja_class_code, category_name);
END
GO




-- ============================================================
-- UPDATED_AT TRIGGERS FOR REFERENCE TABLES
-- ============================================================

-- 1) REF_COUNTRIES
IF OBJECT_ID('dbo.TR_REF_COUNTRIES_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_REF_COUNTRIES_updated_at;
GO
CREATE TRIGGER dbo.TR_REF_COUNTRIES_updated_at
ON dbo.REF_COUNTRIES
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE t
    SET updated_at = SYSUTCDATETIME()
  FROM dbo.REF_COUNTRIES t
  INNER JOIN inserted i ON i.country_id = t.country_id;
END
GO

-- 2) REF_DUTY_STATIONS
IF OBJECT_ID('dbo.TR_REF_DUTY_STATIONS_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_REF_DUTY_STATIONS_updated_at;
GO
CREATE TRIGGER dbo.TR_REF_DUTY_STATIONS_updated_at
ON dbo.REF_DUTY_STATIONS
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE t
    SET updated_at = SYSUTCDATETIME()
  FROM dbo.REF_DUTY_STATIONS t
  INNER JOIN inserted i ON i.duty_station_id = t.duty_station_id;
END
GO

-- 3) REF_POST_CATEGORIES
IF OBJECT_ID('dbo.TR_REF_POST_CATEGORIES_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_REF_POST_CATEGORIES_updated_at;
GO
CREATE TRIGGER dbo.TR_REF_POST_CATEGORIES_updated_at
ON dbo.REF_POST_CATEGORIES
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE t
    SET updated_at = SYSUTCDATETIME()
  FROM dbo.REF_POST_CATEGORIES t
  INNER JOIN inserted i ON i.post_category_id = t.post_category_id;
END
GO

-- 4) REF_GRADES
IF OBJECT_ID('dbo.TR_REF_GRADES_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_REF_GRADES_updated_at;
GO
CREATE TRIGGER dbo.TR_REF_GRADES_updated_at
ON dbo.REF_GRADES
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE t
    SET updated_at = SYSUTCDATETIME()
  FROM dbo.REF_GRADES t
  INNER JOIN inserted i ON i.grade_id = t.grade_id;
END
GO



-- 6) REF_UMOJA_CLASSES
IF OBJECT_ID('dbo.TR_REF_UMOJA_CLASSES_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_REF_UMOJA_CLASSES_updated_at;
GO
CREATE TRIGGER dbo.TR_REF_UMOJA_CLASSES_updated_at
ON dbo.REF_UMOJA_CLASSES
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE t
    SET updated_at = SYSUTCDATETIME()
  FROM dbo.REF_UMOJA_CLASSES t
  INNER JOIN inserted i ON i.umoja_class_id = t.umoja_class_id;
END
GO

-- 7) REF_COST_CATEGORIES
IF OBJECT_ID('dbo.TR_REF_COST_CATEGORIES_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_REF_COST_CATEGORIES_updated_at;
GO
CREATE TRIGGER dbo.TR_REF_COST_CATEGORIES_updated_at
ON dbo.REF_COST_CATEGORIES
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE t
    SET updated_at = SYSUTCDATETIME()
  FROM dbo.REF_COST_CATEGORIES t
  INNER JOIN inserted i ON i.cost_category_id = t.cost_category_id;
END
GO

-- 8) REF_COST_SUBCATEGORIES
IF OBJECT_ID('dbo.TR_REF_COST_SUBCATEGORIES_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_REF_COST_SUBCATEGORIES_updated_at;
GO
CREATE TRIGGER dbo.TR_REF_COST_SUBCATEGORIES_updated_at
ON dbo.REF_COST_SUBCATEGORIES
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE t
    SET updated_at = SYSUTCDATETIME()
  FROM dbo.REF_COST_SUBCATEGORIES t
  INNER JOIN inserted i ON i.cost_subcategory_id = t.cost_subcategory_id;
END
GO


-- 11) REF_OPC_CATEGORIES
IF OBJECT_ID('dbo.TR_REF_OPC_CATEGORIES_updated_at', 'TR') IS NOT NULL
  DROP TRIGGER dbo.TR_REF_OPC_CATEGORIES_updated_at;
GO
CREATE TRIGGER dbo.TR_REF_OPC_CATEGORIES_updated_at
ON dbo.REF_OPC_CATEGORIES
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE t
    SET updated_at = SYSUTCDATETIME()
  FROM dbo.REF_OPC_CATEGORIES t
  INNER JOIN inserted i ON i.opc_category_id = t.opc_category_id;
END
GO




-------------------------------------INSERT------------------------------
INSERT INTO dbo.REF_COUNTRIES (country_name, iso2_code, iso3_code)
VALUES
('Afghanistan', 'AF', 'AFG'),
('Albania', 'AL', 'ALB'),
('Algeria', 'DZ', 'DZA'),
('Andorra', 'AD', 'AND'),
('Angola', 'AO', 'AGO'),
('Antigua and Barbuda', 'AG', 'ATG'),
('Argentina', 'AR', 'ARG'),
('Armenia', 'AM', 'ARM'),
('Australia', 'AU', 'AUS'),
('Austria', 'AT', 'AUT'),
('Azerbaijan', 'AZ', 'AZE'),
('Bahamas', 'BS', 'BHS'),
('Bahrain', 'BH', 'BHR'),
('Bangladesh', 'BD', 'BGD'),
('Barbados', 'BB', 'BRB'),
('Belarus', 'BY', 'BLR'),
('Belgium', 'BE', 'BEL'),
('Belize', 'BZ', 'BLZ'),
('Benin', 'BJ', 'BEN'),
('Bhutan', 'BT', 'BTN'),
('Bolivia', 'BO', 'BOL'),
('Bosnia and Herzegovina', 'BA', 'BIH'),
('Botswana', 'BW', 'BWA'),
('Brazil', 'BR', 'BRA'),
('Brunei', 'BN', 'BRN'),
('Bulgaria', 'BG', 'BGR'),
('Burkina Faso', 'BF', 'BFA'),
('Burundi', 'BI', 'BDI'),
('Cabo Verde', 'CV', 'CPV'),
('Cambodia', 'KH', 'KHM'),
('Cameroon', 'CM', 'CMR'),
('Canada', 'CA', 'CAN'),
('Central African Republic', 'CF', 'CAF'),
('Chad', 'TD', 'TCD'),
('Chile', 'CL', 'CHL'),
('China', 'CN', 'CHN'),
('Colombia', 'CO', 'COL'),
('Comoros', 'KM', 'COM'),
('Congo', 'CG', 'COG'),
('Costa Rica', 'CR', 'CRI'),
('Côte d’Ivoire', 'CI', 'CIV'),
('Croatia', 'HR', 'HRV'),
('Cuba', 'CU', 'CUB'),
('Cyprus', 'CY', 'CYP'),
('Czech Republic', 'CZ', 'CZE'),
('North Korea', 'KP', 'PRK'),
('Democratic Republic of the Congo', 'CD', 'COD'),
('Denmark', 'DK', 'DNK'),
('Djibouti', 'DJ', 'DJI'),
('Dominica', 'DM', 'DMA'),
('Dominican Republic', 'DO', 'DOM'),
('Ecuador', 'EC', 'ECU'),
('Egypt', 'EG', 'EGY'),
('El Salvador', 'SV', 'SLV'),
('Equatorial Guinea', 'GQ', 'GNQ'),
('Eritrea', 'ER', 'ERI'),
('Estonia', 'EE', 'EST'),
('Eswatini', 'SZ', 'SWZ'),
('Ethiopia', 'ET', 'ETH'),
('Fiji', 'FJ', 'FJI'),
('Finland', 'FI', 'FIN'),
('France', 'FR', 'FRA'),
('Gabon', 'GA', 'GAB'),
('Gambia', 'GM', 'GMB'),
('Georgia', 'GE', 'GEO'),
('Germany', 'DE', 'DEU'),
('Ghana', 'GH', 'GHA'),
('Greece', 'GR', 'GRC'),
('Grenada', 'GD', 'GRD'),
('Guatemala', 'GT', 'GTM'),
('Guinea', 'GN', 'GIN'),
('Guinea-Bissau', 'GW', 'GNB'),
('Guyana', 'GY', 'GUY'),
('Haiti', 'HT', 'HTI'),
('Honduras', 'HN', 'HND'),
('Hungary', 'HU', 'HUN'),
('Iceland', 'IS', 'ISL'),
('India', 'IN', 'IND'),
('Indonesia', 'ID', 'IDN'),
('Iran', 'IR', 'IRN'),
('Iraq', 'IQ', 'IRQ'),
('Ireland', 'IE', 'IRL'),
('Israel', 'IL', 'ISR'),
('Italy', 'IT', 'ITA'),
('Jamaica', 'JM', 'JAM'),
('Japan', 'JP', 'JPN'),
('Jordan', 'JO', 'JOR'),
('Kazakhstan', 'KZ', 'KAZ'),
('Kenya', 'KE', 'KEN'),
('Kiribati', 'KI', 'KIR'),
('Kuwait', 'KW', 'KWT'),
('Kyrgyzstan', 'KG', 'KGZ'),
('Laos', 'LA', 'LAO'),
('Latvia', 'LV', 'LVA'),
('Lebanon', 'LB', 'LBN'),
('Lesotho', 'LS', 'LSO'),
('Liberia', 'LR', 'LBR'),
('Libya', 'LY', 'LBY'),
('Liechtenstein', 'LI', 'LIE'),
('Lithuania', 'LT', 'LTU'),
('Luxembourg', 'LU', 'LUX'),
('Madagascar', 'MG', 'MDG'),
('Malawi', 'MW', 'MWI'),
('Malaysia', 'MY', 'MYS'),
('Maldives', 'MV', 'MDV'),
('Mali', 'ML', 'MLI'),
('Malta', 'MT', 'MLT'),
('Marshall Islands', 'MH', 'MHL'),
('Mauritania', 'MR', 'MRT'),
('Mauritius', 'MU', 'MUS'),
('Mexico', 'MX', 'MEX'),
('Micronesia', 'FM', 'FSM'),
('Monaco', 'MC', 'MCO'),
('Mongolia', 'MN', 'MNG'),
('Montenegro', 'ME', 'MNE'),
('Morocco', 'MA', 'MAR'),
('Mozambique', 'MZ', 'MOZ'),
('Myanmar', 'MM', 'MMR'),
('Namibia', 'NA', 'NAM'),
('Nauru', 'NR', 'NRU'),
('Nepal', 'NP', 'NPL'),
('Netherlands', 'NL', 'NLD'),
('New Zealand', 'NZ', 'NZL'),
('Nicaragua', 'NI', 'NIC'),
('Niger', 'NE', 'NER'),
('Nigeria', 'NG', 'NGA'),
('North Macedonia', 'MK', 'MKD'),
('Norway', 'NO', 'NOR'),
('Oman', 'OM', 'OMN'),
('Pakistan', 'PK', 'PAK'),
('Palau', 'PW', 'PLW'),
('Panama', 'PA', 'PAN'),
('Papua New Guinea', 'PG', 'PNG'),
('Paraguay', 'PY', 'PRY'),
('Peru', 'PE', 'PER'),
('Philippines', 'PH', 'PHL'),
('Poland', 'PL', 'POL'),
('Portugal', 'PT', 'PRT'),
('Qatar', 'QA', 'QAT'),
('South Korea', 'KR', 'KOR'),
('Moldova', 'MD', 'MDA'),
('Romania', 'RO', 'ROU'),
('Russia', 'RU', 'RUS'),
('Rwanda', 'RW', 'RWA'),
('Saint Kitts and Nevis', 'KN', 'KNA'),
('Saint Lucia', 'LC', 'LCA'),
('Saint Vincent and the Grenadines', 'VC', 'VCT'),
('Samoa', 'WS', 'WSM'),
('San Marino', 'SM', 'SMR'),
('Sao Tome and Principe', 'ST', 'STP'),
('Saudi Arabia', 'SA', 'SAU'),
('Senegal', 'SN', 'SEN'),
('Serbia', 'RS', 'SRB'),
('Seychelles', 'SC', 'SYC'),
('Sierra Leone', 'SL', 'SLE'),
('Singapore', 'SG', 'SGP'),
('Slovakia', 'SK', 'SVK'),
('Slovenia', 'SI', 'SVN'),
('Solomon Islands', 'SB', 'SLB'),
('Somalia', 'SO', 'SOM'),
('South Africa', 'ZA', 'ZAF'),
('South Sudan', 'SS', 'SSD'),
('Spain', 'ES', 'ESP'),
('Sri Lanka', 'LK', 'LKA'),
('Sudan', 'SD', 'SDN'),
('Suriname', 'SR', 'SUR'),
('Sweden', 'SE', 'SWE'),
('Switzerland', 'CH', 'CHE'),
('Syria', 'SY', 'SYR'),
('Tajikistan', 'TJ', 'TJK'),
('Thailand', 'TH', 'THA'),
('Timor-Leste', 'TL', 'TLS'),
('Togo', 'TG', 'TGO'),
('Tonga', 'TO', 'TON'),
('Trinidad and Tobago', 'TT', 'TTO'),
('Tunisia', 'TN', 'TUN'),
('Turkey', 'TR', 'TUR'),
('Turkmenistan', 'TM', 'TKM'),
('Tuvalu', 'TV', 'TUV'),
('Uganda', 'UG', 'UGA'),
('Ukraine', 'UA', 'UKR'),
('United Arab Emirates', 'AE', 'ARE'),
('United Kingdom', 'GB', 'GBR'),
('Tanzania', 'TZ', 'TZA'),
('United States', 'US', 'USA'),
('Uruguay', 'UY', 'URY'),
('Uzbekistan', 'UZ', 'UZB'),
('Vanuatu', 'VU', 'VUT'),
('Venezuela', 'VE', 'VEN'),
('Vietnam', 'VN', 'VNM'),
('Yemen', 'YE', 'YEM'),
('Zambia', 'ZM', 'ZMB'),
('Zimbabwe', 'ZW', 'ZWE'),
('Vatican City', 'VA', 'VAT'),
('Palestine', 'PS', 'PSE'),
('Cook Islands', 'CK', 'COK'),
('Niue', 'NU', 'NIU');


select * from dbo.REF_COUNTRIES;
SELECT name AS TableName, schema_name(schema_id) AS SchemaName
FROM sys.tables
ORDER BY SchemaName, TableName;

INSERT INTO dbo.REF_POST_CATEGORIES
(category_code, category_name, description)
VALUES
('PRO', 'Professional and above', 'Professional staff including P and D grades'),
('GS',  'General Service',        'General Service staff'),
('NO',  'National Officers',      'National Officer staff'),
('UNV', 'UNV',                    'United Nations Volunteers (both international and national)');

DELETE FROM dbo.REF_GRADES;

INSERT INTO dbo.REF_GRADES
(grade_code, grade_family, display_order)
VALUES
-- Professional
('D-2', 'PROF', 1),
('D-1', 'PROF', 2),
('P-5', 'PROF', 3),
('P-4', 'PROF', 4),
('P-3', 'PROF', 5),
('P-2', 'PROF', 6),
('P-1', 'PROF', 7),

-- General Service
('GS-7', 'GS',  10),
('GS-6', 'GS',  11),
('GS-5', 'GS',  12),
('GS-4', 'GS',  13),
('GS-3', 'GS',  14),
('GS-2', 'GS',  15),
('GS-1', 'GS',  16),

-- National Officers
('NO-D', 'NO', 20),
('NO-C', 'NO', 21),
('NO-B', 'NO', 22),
('NO-A', 'NO', 23),

-- UNV
('UNV_INT', 'UNV', 30),
('UNV_NAT', 'UNV', 31);

-- CWSP sample load expects grade_code 'GS-2/1' (REF_GRADES has GS-2 and GS-1 only)
IF NOT EXISTS (SELECT 1 FROM dbo.REF_GRADES WHERE grade_code = 'GS-2/1')
  INSERT INTO dbo.REF_GRADES (grade_code, grade_family, display_order) VALUES ('GS-2/1', 'GS', 16);
GO

INSERT INTO dbo.REF_UMOJA_CLASSES (class_code, class_name, description, is_active)
VALUES
('010', 'Staff Personnel', 'Umoja class 010', 1),
('120', 'Contract Services', 'Umoja class 120', 1),
('125', 'Operating Other Costs', 'Umoja class 125', 1),
('130', 'Supplies, Materials', 'Umoja class 130', 1),
('135', 'Equipment, Vehicles, Furniture', 'Umoja class 135', 1),
('140', 'Transfers / Grant to IP', 'Umoja class 140', 1),
('145', 'Grants Out', 'Umoja class 145', 1),
('160', 'Travel', 'Umoja class 160', 1),
('155', 'Programme Support Costs', 'Umoja class 155 (PSC)', 1);

ALTER TABLE dbo.REF_UMOJA_CLASSES
ADD CONSTRAINT CK_REF_UMOJA_CLASSES_numeric
CHECK (class_code NOT LIKE '%[^0-9]%');


-- ============================================================
-- Seed data for REF_OPC_CATEGORIES (from OPC_COMBOS)
-- Note: IMIS codes intentionally not stored; commitment_item_code used
-- ============================================================

INSERT INTO dbo.REF_OPC_CATEGORIES
(
    umoja_class_code,
    category_name,
    subcategory_name,
    commitment_item_code,
    sort_order,
    is_active
)
VALUES
-- 010
(N'010', N'Staff Personnel', N'GTA -',                              N'71113110',  1, 1),

-- 120 (Contract Service)
(N'120', N'Contract Service', N'Individual contractor',             N'74181010',  2, 1),
(N'120', N'Contract Service', N'Other contractual services',        N'74181010',  3, 1),

-- 125 (Operating Other Costs)
(N'125', N'Operating Other Costs', N'Contractual Security Services',                 N'75003010',  4, 1),
(N'125', N'Operating Other Costs', N'Rental and maintenance of premises',            N'74102010',  5, 1),
(N'125', N'Operating Other Costs', N'Minor Alteration to premises',                  N'74105010',  6, 1),
(N'125', N'Operating Other Costs', N'Contractual cleaning services and cleaning supplies', N'74101010',  7, 1),
(N'125', N'Operating Other Costs', N'Office utilities (electricity, etc)',           N'74103040',  8, 1),
(N'125', N'Operating Other Costs', N'Rental of office furniture & equipment',        N'74111010',  9, 1),
(N'125', N'Operating Other Costs', N'Local transportation - Rental of vehicles',     N'74191072', 10, 1),
(N'125', N'Operating Other Costs', N'General insurance',                             N'79202570', 11, 1),
(N'125', N'Operating Other Costs', N'Maintenance of vehicle',                        N'74191070', 12, 1),
(N'125', N'Operating Other Costs', N'Maintenance of office furniture and equipment', N'74112010', 13, 1),
(N'125', N'Operating Other Costs', N'Freight and related costs',                     N'74202530', 14, 1),
(N'125', N'Operating Other Costs', N'Bank charges',                                  N'74251010', 15, 1),
(N'125', N'Operating Other Costs', N'Office communication costs',                    N'74121020', 16, 1),
(N'125', N'Operating Other Costs', N'Pouches',                                       N'74201010', 17, 1),
(N'125', N'Operating Other Costs', N'Office supplies, stationary & photocopy paper', N'77003510', 18, 1),
(N'125', N'Operating Other Costs', N'Inter-organizational UN global security',       N'75003010', 19, 1),
(N'125', N'Operating Other Costs', N'Joint housing services - UN Common Services',   N'75331050', 20, 1),

-- 130 (Supplies, Materials)
(N'130', N'Supplies, Materials', N'Petrol for vehicles',             N'77008110', 21, 1),
(N'130', N'Supplies, Materials', N'Medical Supplies',                N'77002510', 22, 1),
(N'130', N'Supplies, Materials', N'Books and Supplies',              N'74161010', 23, 1),

-- 135 (Equipment, Vehicles, Furniture)
(N'135', N'Equipment, Vehicles, Furniture', N'Acquisition of office furniture (desk, chair, closet, shelve)', N'77152010', 24, 1),
(N'135', N'Equipment, Vehicles, Furniture', N'Acquisition of office equipment (photocopier, electric equip.)', N'77151010', 25, 1),
(N'135', N'Equipment, Vehicles, Furniture', N'Acquisition of office automation equipment (PCs, printers)',     N'77171020', 26, 1),
(N'135', N'Equipment, Vehicles, Furniture', N'Acquisition of transportation equipment (vehicles)',             N'77177012', 27, 1),
(N'135', N'Equipment, Vehicles, Furniture', N'Acquisition of communication equipment (radio,mobile,fax)',      N'77171510', 28, 1),
(N'135', N'Equipment, Vehicles, Furniture', N'Acquisition of public information equipt. (TV,VCR,Audio)',       N'77172010', 29, 1),
(N'135', N'Equipment, Vehicles, Furniture', N'Acquisition of software',                                        N'77202510', 30, 1),
(N'135', N'Equipment, Vehicles, Furniture', N'Acquisition of security & safety equipment',                     N'77173010', 31, 1),
(N'135', N'Equipment, Vehicles, Furniture', N'Acquisition of other miscellaneous equipment',                   N'77151010', 32, 1);
GO

EXEC sp_tables @table_type = "'TABLE'";

SELECT * FROM REF_POST_CATEGORIES;

SELECT * FROM REF_GRADES;

-- ============================================================
-- COST PLAN YEARS
-- Authoritative master table for cost planning years
-- ============================================================

IF OBJECT_ID('dbo.cost_plan_years', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.cost_plan_years (
        cost_plan_year_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_cost_plan_years PRIMARY KEY,

        year_code INT NOT NULL,
        -- Example: 2025, 2026

        year_name NVARCHAR(50) NULL,
        -- Optional display name (e.g. 'Cost Plan 2025')

        status NVARCHAR(20) NOT NULL,
        -- Allowed values:
        -- CLOSED  : past years (read-only)
        -- CURRENT : active working year
        -- FUTURE  : template/design only, limited edits

        start_date DATE NOT NULL,
        end_date   DATE NOT NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_cost_plan_years_created_at DEFAULT (SYSUTCDATETIME()),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_cost_plan_years_updated_at DEFAULT (SYSUTCDATETIME()),

        created_by INT NULL,
        updated_by INT NULL
    );

    -- Ensure one row per year
    ALTER TABLE dbo.cost_plan_years
        ADD CONSTRAINT UQ_cost_plan_years_year_code UNIQUE (year_code);

    -- Status constraint (explicit, readable, future-safe)
    ALTER TABLE dbo.cost_plan_years
        ADD CONSTRAINT CK_cost_plan_years_status
        CHECK (status IN ('CLOSED', 'CURRENT', 'FUTURE'));
END
GO

INSERT INTO dbo.cost_plan_years
(
    year_code,
    year_name,
    status,
    start_date,
    end_date
)
VALUES
-- Current active year
(2025, 'Cost Plan 2025', 'CURRENT', '2025-01-01', '2025-12-31'),

-- Next year (planning allowed, limited inputs)
(2026, 'Cost Plan 2026', 'FUTURE',  '2026-01-01', '2026-12-31'),

-- Forward-looking placeholder
(2027, 'Cost Plan 2027', 'FUTURE',  '2027-01-01', '2027-12-31');

-- ============================================================
-- CWSP_PARAMETER_SETS
-- One row per (year, country). Holds % parameters and FX context.
-- ============================================================
IF OBJECT_ID('dbo.CWSP_PARAMETER_SETS', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.CWSP_PARAMETER_SETS (
    cwsp_set_id                 INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    cost_plan_year_id           INT NOT NULL,  -- FK -> dbo.cost_plan_years
    country_id                  INT NOT NULL,  -- FK -> dbo.REF_COUNTRIES

    post_adjustment_pct         DECIMAL(6,3) NULL,
    common_staff_cost_prof_pct  DECIMAL(6,3) NULL,
    common_staff_cost_gen_pct   DECIMAL(6,3) NULL,
    common_staff_cost_no_pct    DECIMAL(6,3) NULL,

    exchange_rate_to_usd        DECIMAL(18,6) NULL,

    appendix_pct                DECIMAL(6,3) NULL,
    ashi_pct                    DECIMAL(6,3) NULL,

    -- renamed from currency_code
    local_currency              NVARCHAR(3) NULL,   -- e.g., USD, KES, HTG

    is_active                   BIT NOT NULL CONSTRAINT DF_CWSP_PARAMETER_SETS_is_active DEFAULT (1),
    created_at                  DATETIME2(0) NOT NULL CONSTRAINT DF_CWSP_PARAMETER_SETS_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at                  DATETIME2(0) NOT NULL CONSTRAINT DF_CWSP_PARAMETER_SETS_updated_at DEFAULT (SYSUTCDATETIME())
  );

  -- One CWSP set per year per country
  ALTER TABLE dbo.CWSP_PARAMETER_SETS
    ADD CONSTRAINT UQ_CWSP_PARAMETER_SETS_year_country UNIQUE (cost_plan_year_id, country_id);

  ALTER TABLE dbo.CWSP_PARAMETER_SETS
    ADD CONSTRAINT FK_CWSP_PARAMETER_SETS_year
    FOREIGN KEY (cost_plan_year_id) REFERENCES dbo.cost_plan_years(cost_plan_year_id);

  ALTER TABLE dbo.CWSP_PARAMETER_SETS
    ADD CONSTRAINT FK_CWSP_PARAMETER_SETS_country
    FOREIGN KEY (country_id) REFERENCES dbo.REF_COUNTRIES(country_id);
END
GO


-- ============================================================
-- CWSP_GRADE_AMOUNTS
-- One row per (cwsp_set, grade). Holds annual amounts (incl UNV grades).
-- ============================================================
IF OBJECT_ID('dbo.CWSP_GRADE_AMOUNTS', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.CWSP_GRADE_AMOUNTS (
    cwsp_grade_amount_id  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    cwsp_set_id           INT NOT NULL,  -- FK -> dbo.CWSP_PARAMETER_SETS
    grade_id              INT NOT NULL,  -- FK -> dbo.REF_GRADES

    annual_amount         DECIMAL(18,2) NOT NULL,

    -- renamed from currency_code
    local_currency        NVARCHAR(3) NULL,  -- optional override if needed

    is_active             BIT NOT NULL CONSTRAINT DF_CWSP_GRADE_AMOUNTS_is_active DEFAULT (1),
    created_at            DATETIME2(0) NOT NULL CONSTRAINT DF_CWSP_GRADE_AMOUNTS_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at            DATETIME2(0) NOT NULL CONSTRAINT DF_CWSP_GRADE_AMOUNTS_updated_at DEFAULT (SYSUTCDATETIME())
  );

  ALTER TABLE dbo.CWSP_GRADE_AMOUNTS
    ADD CONSTRAINT UQ_CWSP_GRADE_AMOUNTS_pair UNIQUE (cwsp_set_id, grade_id);

  ALTER TABLE dbo.CWSP_GRADE_AMOUNTS
    ADD CONSTRAINT FK_CWSP_GRADE_AMOUNTS_set
    FOREIGN KEY (cwsp_set_id) REFERENCES dbo.CWSP_PARAMETER_SETS(cwsp_set_id);

  ALTER TABLE dbo.CWSP_GRADE_AMOUNTS
    ADD CONSTRAINT FK_CWSP_GRADE_AMOUNTS_grade
    FOREIGN KEY (grade_id) REFERENCES dbo.REF_GRADES(grade_id);
END
GO


/* ============================================================
   CWSP sample load (Sets + Grade Amounts)
   Assumptions:
   - dbo.cost_plan_years exists and has year_code
   - dbo.REF_COUNTRIES exists and contains country_name values that match Section/Country
   - dbo.REF_GRADES exists with grade_code:
       D-1, P-5, P-4, P-3, P-2,
       GS-7, GS-6, GS-5, GS-4, GS-3, GS-2/1,
       NO-D, NO-C, NO-B, NO-A,
       UNV-INT, UNV-NAT
   ============================================================ */

-- CWSP @src references 'East Africa (Addis Ababa)' - ensure it exists in REF_COUNTRIES
IF NOT EXISTS (SELECT 1 FROM dbo.REF_COUNTRIES WHERE country_name = N'East Africa (Addis Ababa)')
  INSERT INTO dbo.REF_COUNTRIES (country_name, iso2_code, iso3_code) VALUES (N'East Africa (Addis Ababa)', 'ET', 'ETH');
GO

DECLARE @year_code INT = 2026;

DECLARE @cost_plan_year_id INT;
SELECT @cost_plan_year_id = cost_plan_year_id
FROM dbo.cost_plan_years
WHERE year_code = @year_code;

IF @cost_plan_year_id IS NULL
  THROW 50010, 'cost_plan_years row not found for the given year_code.', 1;

---------------------------------------------------------------
-- 1) Stage the incoming sample data
---------------------------------------------------------------
DECLARE @src TABLE (
  section_country                   NVARCHAR(200) NOT NULL,
  post_adjustment_pct               DECIMAL(6,3)  NULL,
  common_staff_cost_prof_pct        DECIMAL(6,3)  NULL,
  common_staff_cost_gen_pct         DECIMAL(6,3)  NULL,
  common_staff_cost_no_pct          DECIMAL(6,3)  NULL,
  exchange_rate_to_usd              DECIMAL(18,6) NULL,
  appendix_pct                      DECIMAL(6,3)  NULL,
  ashi_pct                          DECIMAL(6,3)  NULL,

  d1                                DECIMAL(18,2) NULL,
  p5                                DECIMAL(18,2) NULL,
  p4                                DECIMAL(18,2) NULL,
  p3                                DECIMAL(18,2) NULL,
  p2                                DECIMAL(18,2) NULL,

  gs7                               DECIMAL(18,2) NULL,
  gs6                               DECIMAL(18,2) NULL,
  gs5                               DECIMAL(18,2) NULL,
  gs4                               DECIMAL(18,2) NULL,
  gs3                               DECIMAL(18,2) NULL,
  gs2_1                             DECIMAL(18,2) NULL,

  no_d                              DECIMAL(18,2) NULL,
  no_c                              DECIMAL(18,2) NULL,
  no_b                              DECIMAL(18,2) NULL,
  no_a                              DECIMAL(18,2) NULL,

  unv_int                            DECIMAL(18,2) NULL,
  unv_nat                            DECIMAL(18,2) NULL
);

-- Insert your sample rows (already cleaned into numbers)
INSERT INTO @src VALUES
-- East Africa (Addis Ababa)
(N'East Africa (Addis Ababa)', 62.6,  82.0,  50.0,  50.0,   1.000000, 1.0, 6.0,
 118321, 103193, 89104, 75022, 60125,
 29666, 26983, 22656, 18719, 15659, 12177,
 58070, 52791, 47981, 43615,
 58000, 0),

-- Kenya
(N'Kenya', 53.0, 105.0, 39.0, 28.0, 128.350000, 1.0, 6.0,
 118321, 103193, 89104, 75022, 60125,
 4949332, 3991405, 3218877, 2595866, 1922865, 1424342,
 14742840, 11599407, 9126193, 7180340,
 0, 0),

-- Niger
(N'Niger', 39.4, 150.0, 140.0, 55.0, 595.350000, 1.0, 6.0,
 118321, 103193, 89104, 75022, 60125,
 21437000, 17432000, 14171000, 10992000, 8386000, 6394000,
 30242000, 25846000, 22093000, 19209000,
 0, 22681),

-- Haiti
(N'Haiti', 64.0, 65.0, 50.0, 90.0, 1.000000, 1.0, 6.0,
 118321, 103193, 89104, 75022, 60125,
 24182, 18601, 14532, 11443, 9228, 7442,
 68426, 56318, 40810, 29572,
 23000, 75000),

-- Honduras
(N'Honduras', 43.8, 83.0, 24.0, 27.0, 24.576000, 1.0, 0.0,
 118321, 103193, 89104, 75022, 60125,
 1115179, 857830, 659871, 507590, 390452, 289225,
 2709933, 2185432, 1762440, 1421328,
 57250, 18960),

-- Kazakhstan
(N'Kazakhstan', 42.8, 50.0, 51.0, 50.0, 1.000000, 1.0, 6.0,
 118321, 103193, 89104, 75022, 60125,
 31404, 27307, 23743, 20647, 18110, 15904,
 64724, 55043, 46802, 40767,
 0, 4000),

-- Saudi Arabia
(N'Saudi Arabia', 59.1, 54.0, 19.0, 0.0, 3.753000, 1.0, 6.0,
 118321, 103193, 89104, 75022, 60125,
 395950, 316760, 266184, 223682, 191184, 163402,
 957007, 736163, 566278, 464163,
 0, 36000);

---------------------------------------------------------------
-- 2) Validate that Section/Country exists in REF_COUNTRIES
---------------------------------------------------------------
IF EXISTS (
  SELECT 1
  FROM @src s
  LEFT JOIN dbo.REF_COUNTRIES c ON c.country_name = s.section_country
  WHERE c.country_id IS NULL
)
BEGIN
  SELECT s.section_country AS missing_in_REF_COUNTRIES
  FROM @src s
  LEFT JOIN dbo.REF_COUNTRIES c ON c.country_name = s.section_country
  WHERE c.country_id IS NULL;

  THROW 50011, 'Some Section/Country values do not exist in REF_COUNTRIES.country_name. Insert them first.', 1;
END;

---------------------------------------------------------------
-- 3) Upsert CWSP_PARAMETER_SETS
---------------------------------------------------------------
;WITH resolved AS (
  SELECT
    @cost_plan_year_id AS cost_plan_year_id,
    c.country_id,
    s.post_adjustment_pct,
    s.common_staff_cost_prof_pct,
    s.common_staff_cost_gen_pct,
    s.common_staff_cost_no_pct,
    s.exchange_rate_to_usd,
    s.appendix_pct,
    s.ashi_pct,
    CAST(NULL AS NVARCHAR(3)) AS local_currency
  FROM @src s
  JOIN dbo.REF_COUNTRIES c
    ON c.country_name = s.section_country
)
MERGE dbo.CWSP_PARAMETER_SETS AS tgt
USING resolved AS src
ON tgt.cost_plan_year_id = src.cost_plan_year_id
AND tgt.country_id = src.country_id
WHEN MATCHED THEN
  UPDATE SET
    post_adjustment_pct        = src.post_adjustment_pct,
    common_staff_cost_prof_pct = src.common_staff_cost_prof_pct,
    common_staff_cost_gen_pct  = src.common_staff_cost_gen_pct,
    common_staff_cost_no_pct   = src.common_staff_cost_no_pct,
    exchange_rate_to_usd       = src.exchange_rate_to_usd,
    appendix_pct               = src.appendix_pct,
    ashi_pct                   = src.ashi_pct,
    local_currency             = src.local_currency,
    updated_at                 = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
  INSERT (
    cost_plan_year_id, country_id,
    post_adjustment_pct,
    common_staff_cost_prof_pct, common_staff_cost_gen_pct, common_staff_cost_no_pct,
    exchange_rate_to_usd,
    appendix_pct, ashi_pct,
    local_currency
  )
  VALUES (
    src.cost_plan_year_id, src.country_id,
    src.post_adjustment_pct,
    src.common_staff_cost_prof_pct, src.common_staff_cost_gen_pct, src.common_staff_cost_no_pct,
    src.exchange_rate_to_usd,
    src.appendix_pct, src.ashi_pct,
    src.local_currency
  );

---------------------------------------------------------------
-- 4) Upsert CWSP_GRADE_AMOUNTS (unpivot stage -> grade rows)
---------------------------------------------------------------
DECLARE @grade_map TABLE (src_col NVARCHAR(50), grade_code NVARCHAR(20));
INSERT INTO @grade_map VALUES
('d1',     'D-1'),
('p5',     'P-5'),
('p4',     'P-4'),
('p3',     'P-3'),
('p2',     'P-2'),
('gs7',    'GS-7'),
('gs6',    'GS-6'),
('gs5',    'GS-5'),
('gs4',    'GS-4'),
('gs3',    'GS-3'),
('gs2_1',  'GS-2/1'),
('no_d',   'NO-D'),
('no_c',   'NO-C'),
('no_b',   'NO-B'),
('no_a',   'NO-A'),
('unv_int','UNV-INT'),
('unv_nat','UNV-NAT');

;WITH sets AS (
  SELECT
    s.section_country,
    c.country_id,
    ps.cwsp_set_id,
    s.*
  FROM @src s
  JOIN dbo.REF_COUNTRIES c
    ON c.country_name = s.section_country
  JOIN dbo.CWSP_PARAMETER_SETS ps
    ON ps.cost_plan_year_id = @cost_plan_year_id
   AND ps.country_id = c.country_id
),
unpivoted AS (
  SELECT
    sets.cwsp_set_id,
    gm.grade_code,
    CAST(v.amount AS DECIMAL(18,2)) AS annual_amount,
    CAST(NULL AS NVARCHAR(3)) AS local_currency
  FROM sets
  CROSS APPLY (VALUES
    ('d1',     sets.d1),
    ('p5',     sets.p5),
    ('p4',     sets.p4),
    ('p3',     sets.p3),
    ('p2',     sets.p2),
    ('gs7',    sets.gs7),
    ('gs6',    sets.gs6),
    ('gs5',    sets.gs5),
    ('gs4',    sets.gs4),
    ('gs3',    sets.gs3),
    ('gs2_1',  sets.gs2_1),
    ('no_d',   sets.no_d),
    ('no_c',   sets.no_c),
    ('no_b',   sets.no_b),
    ('no_a',   sets.no_a),
    ('unv_int',sets.unv_int),
    ('unv_nat',sets.unv_nat)
  ) v(src_col, amount)
  JOIN @grade_map gm
    ON gm.src_col = v.src_col
  WHERE v.amount IS NOT NULL
),
resolved_grades AS (
  SELECT
    u.cwsp_set_id,
    g.grade_id,
    u.annual_amount,
    u.local_currency,
    u.grade_code
  FROM unpivoted u
  LEFT JOIN dbo.REF_GRADES g
    ON g.grade_code = u.grade_code
)
-- Fail fast if any grade missing
IF EXISTS (SELECT 1 FROM resolved_grades WHERE grade_id IS NULL)
BEGIN
  SELECT DISTINCT grade_code AS missing_grade_code
  FROM resolved_grades
  WHERE grade_id IS NULL;

  THROW 50012, 'One or more grade codes not found in REF_GRADES. Insert them first.', 1;
END;

MERGE dbo.CWSP_GRADE_AMOUNTS AS tgt
USING (
  SELECT cwsp_set_id, grade_id, annual_amount, local_currency
  FROM resolved_grades
) AS src
ON tgt.cwsp_set_id = src.cwsp_set_id
AND tgt.grade_id = src.grade_id
WHEN MATCHED THEN
  UPDATE SET
    annual_amount  = src.annual_amount,
    local_currency = src.local_currency,
    updated_at     = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
  INSERT (cwsp_set_id, grade_id, annual_amount, local_currency)
  VALUES (src.cwsp_set_id, src.grade_id, src.annual_amount, src.local_currency);

-- quick sanity check output
SELECT
  c.country_name,
  ps.post_adjustment_pct,
  ps.common_staff_cost_prof_pct,
  ps.common_staff_cost_gen_pct,
  ps.common_staff_cost_no_pct,
  ps.exchange_rate_to_usd,
  ps.appendix_pct,
  ps.ashi_pct
FROM dbo.CWSP_PARAMETER_SETS ps
JOIN dbo.REF_COUNTRIES c ON c.country_id = ps.country_id
WHERE ps.cost_plan_year_id = @cost_plan_year_id
ORDER BY c.country_name;


