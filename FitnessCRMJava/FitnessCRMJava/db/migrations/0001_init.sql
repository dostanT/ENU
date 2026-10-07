-- ============================================================================
--  FitnessCRM — начальная схема (5 таблиц для квиза по СУБД)
--  Диалект: SQL Server (T-SQL). База: FitnessCRM.
--  Кодировка файла: UTF-8 with BOM (иначе кириллица испортится в SSMS).
-- ============================================================================

USE FitnessCRM;
GO

-- На случай повторного запуска — сносим в правильном порядке (сначала дети).
IF OBJECT_ID('dbo.payments',         'U') IS NOT NULL DROP TABLE dbo.payments;
IF OBJECT_ID('dbo.memberships',      'U') IS NOT NULL DROP TABLE dbo.memberships;
IF OBJECT_ID('dbo.clients',          'U') IS NOT NULL DROP TABLE dbo.clients;
IF OBJECT_ID('dbo.membership_types', 'U') IS NOT NULL DROP TABLE dbo.membership_types;
IF OBJECT_ID('dbo.branches',         'U') IS NOT NULL DROP TABLE dbo.branches;
GO

-- ----------------------------------------------------------------------------
-- 1. branches — филиалы
-- ----------------------------------------------------------------------------
CREATE TABLE dbo.branches
(
    id       INT           IDENTITY(1,1) NOT NULL,
    code     VARCHAR(10)   NOT NULL,
    name     NVARCHAR(100) NOT NULL,
    address  NVARCHAR(200) NOT NULL,
    CONSTRAINT pk_branches      PRIMARY KEY (id),
    CONSTRAINT uq_branches_code UNIQUE (code)
);
GO

-- ----------------------------------------------------------------------------
-- 2. membership_types — виды абонементов
-- ----------------------------------------------------------------------------
CREATE TABLE dbo.membership_types
(
    id         INT            IDENTITY(1,1) NOT NULL,
    code       VARCHAR(20)    NOT NULL,
    kind       VARCHAR(10)    NOT NULL,   -- UNLIM / STD / BASE
    months     INT            NOT NULL,   -- 1 / 3 / 6 / 12
    base_price DECIMAL(12,2)  NOT NULL,
    is_active  BIT            NOT NULL CONSTRAINT df_mt_active DEFAULT (1),
    CONSTRAINT pk_membership_types      PRIMARY KEY (id),
    CONSTRAINT uq_membership_types_code UNIQUE (code),
    CONSTRAINT ck_mt_kind   CHECK (kind   IN ('UNLIM','STD','BASE')),
    CONSTRAINT ck_mt_months CHECK (months IN (1,3,6,12)),
    CONSTRAINT ck_mt_price  CHECK (base_price > 0)
);
GO

-- ----------------------------------------------------------------------------
-- 3. clients — клиенты
--    birth_date допускает NULL: у юрлиц (KRP) даты рождения нет.
-- ----------------------------------------------------------------------------
CREATE TABLE dbo.clients
(
    id          INT           IDENTITY(1,1) NOT NULL,
    code        VARCHAR(20)   NOT NULL,   -- FIZ_01_00001 / KRP_01_00001
    client_type VARCHAR(3)    NOT NULL,   -- FIZ / KRP
    full_name   NVARCHAR(150) NOT NULL,
    phone       VARCHAR(20)   NULL,
    email       VARCHAR(100)  NULL,       -- у части клиентов NULL — для вопроса 3
    birth_date  DATE          NULL,       -- у KRP — NULL
    branch_id   INT           NOT NULL,
    created_at  DATETIME2(0)  NOT NULL CONSTRAINT df_clients_created DEFAULT (SYSDATETIME()),
    CONSTRAINT pk_clients        PRIMARY KEY (id),
    CONSTRAINT uq_clients_code   UNIQUE (code),
    CONSTRAINT fk_clients_branch FOREIGN KEY (branch_id) REFERENCES dbo.branches(id),
    CONSTRAINT ck_clients_type   CHECK (client_type IN ('FIZ','KRP')),
    -- Физлицо обязано иметь дату рождения, юрлицо — нет.
    CONSTRAINT ck_clients_birth  CHECK (
        (client_type = 'FIZ' AND birth_date IS NOT NULL)
            OR (client_type = 'KRP')
        )
);
GO

CREATE INDEX ix_clients_branch ON dbo.clients(branch_id);
GO

-- ----------------------------------------------------------------------------
-- 4. memberships — абонементы клиентов
-- ----------------------------------------------------------------------------
CREATE TABLE dbo.memberships
(
    id         INT           IDENTITY(1,1) NOT NULL,
    client_id  INT           NOT NULL,
    type_id    INT           NOT NULL,
    branch_id  INT           NOT NULL,
    status     VARCHAR(10)   NOT NULL,   -- ACTIVE / FROZEN / EXPIRED / CANCELLED
    start_date DATE          NOT NULL,
    end_date   DATE          NOT NULL,
    price_paid DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_memberships         PRIMARY KEY (id),
    CONSTRAINT fk_mem_client          FOREIGN KEY (client_id) REFERENCES dbo.clients(id),
    CONSTRAINT fk_mem_type            FOREIGN KEY (type_id)   REFERENCES dbo.membership_types(id),
    CONSTRAINT fk_mem_branch          FOREIGN KEY (branch_id) REFERENCES dbo.branches(id),
    CONSTRAINT ck_mem_status          CHECK (status IN ('ACTIVE','FROZEN','EXPIRED','CANCELLED')),
    CONSTRAINT ck_mem_dates           CHECK (end_date >= start_date),
    CONSTRAINT ck_mem_price           CHECK (price_paid >= 0)
);
GO

-- Уникальный фильтрованный индекс: у клиента не может быть двух
-- одновременно открытых (ACTIVE/FROZEN) абонементов ОДНОГО ВИДА.
-- Это правило из лабы 2 (операция 3): клиент может купить,
-- например, групповой абонемент вместе с бассейном (разные type_id),
-- но не два одинаковых открытых абонемента.
CREATE UNIQUE INDEX ux_mem_one_open_per_client_type
    ON dbo.memberships(client_id, type_id)
    WHERE status IN ('ACTIVE','FROZEN');
GO

CREATE INDEX ix_mem_branch ON dbo.memberships(branch_id);
CREATE INDEX ix_mem_status ON dbo.memberships(status);
GO

-- ----------------------------------------------------------------------------
-- 5. payments — платежи
-- ----------------------------------------------------------------------------
CREATE TABLE dbo.payments
(
    id            INT           IDENTITY(1,1) NOT NULL,
    membership_id INT           NOT NULL,
    client_id     INT           NOT NULL,
    branch_id     INT           NOT NULL,
    amount        DECIMAL(12,2) NOT NULL,
    method        VARCHAR(10)   NOT NULL,   -- CARD / CASH
    status        VARCHAR(10)   NOT NULL,   -- PAID / DECLINED
    paid_at       DATETIME2(0)  NOT NULL,
    CONSTRAINT pk_payments            PRIMARY KEY (id),
    CONSTRAINT fk_pay_membership      FOREIGN KEY (membership_id) REFERENCES dbo.memberships(id),
    CONSTRAINT fk_pay_client          FOREIGN KEY (client_id)     REFERENCES dbo.clients(id),
    CONSTRAINT fk_pay_branch          FOREIGN KEY (branch_id)     REFERENCES dbo.branches(id),
    CONSTRAINT ck_pay_method          CHECK (method IN ('CARD','CASH')),
    CONSTRAINT ck_pay_status          CHECK (status IN ('PAID','DECLINED')),
    CONSTRAINT ck_pay_amount          CHECK (amount > 0)
);
GO

CREATE INDEX ix_pay_branch   ON dbo.payments(branch_id);
CREATE INDEX ix_pay_paid_at  ON dbo.payments(paid_at);
CREATE INDEX ix_pay_status   ON dbo.payments(status);
GO