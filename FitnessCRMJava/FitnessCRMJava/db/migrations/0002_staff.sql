-- ============================================================================
--  FitnessCRM — таблица сотрудников (staff)
--  Второй файл миграции. Запускать ПОСЛЕ 0001_init.sql.
--  Кодировка: UTF-8 with BOM.
-- ============================================================================

USE FitnessCRM;
GO

IF OBJECT_ID('dbo.staff', 'U') IS NOT NULL
DROP TABLE dbo.staff;
GO

CREATE TABLE dbo.staff
(
    id            INT           IDENTITY(1,1) NOT NULL,
    username      VARCHAR(50)   NOT NULL,
    password_hash VARCHAR(100)  NOT NULL,   -- BCrypt-хэш, ~60 символов
    full_name     NVARCHAR(150) NOT NULL,
    role          VARCHAR(30)   NOT NULL,   -- одно из 8 значений (FitLife)
    branch_id     INT           NULL,       -- для директора — NULL
    is_active     BIT           NOT NULL CONSTRAINT df_staff_active DEFAULT (1),
    CONSTRAINT pk_staff          PRIMARY KEY (id),
    CONSTRAINT uq_staff_username UNIQUE (username),
    CONSTRAINT fk_staff_branch   FOREIGN KEY (branch_id) REFERENCES dbo.branches(id),
    CONSTRAINT ck_staff_role     CHECK (role IN (
                                                 'DIRECTOR', 'MANAGER', 'RECEPTION', 'COACH',
                                                 'STOREKEEPER', 'ACCOUNTANT', 'MARKETER', 'ADMIN'
        ))
);
GO