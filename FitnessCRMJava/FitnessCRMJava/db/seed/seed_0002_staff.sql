-- ============================================================================
--  FitnessCRM — тестовые сотрудники
--  Запускать ПОСЛЕ 0001_init.sql, 0002_staff.sql и seed_001.sql.
--  Кодировка: UTF-8 with BOM.
--
--  Тестовый пароль для ВСЕХ: 123456789
--  (только для локальной разработки — в публичный репозиторий настоящие
--   пароли не попадают, хранится только BCrypt-хэш)
-- ============================================================================

USE FitnessCRM;
GO

-- На случай повторного запуска — чистим и начинаем заново.
DELETE FROM dbo.staff;
DBCC CHECKIDENT ('dbo.staff', RESEED, 0) WITH NO_INFOMSGS;
GO

INSERT INTO dbo.staff (username, password_hash, full_name, role, branch_id, is_active) VALUES
 ('director',    '$2a$10$Z.zbDzZQJonE3UWEYONoceuRrUPl1DDeXqeYXPWs3w5.Ni0w7M7Hu', N'Смагулов Асет Болатович',   'DIRECTOR',    NULL, 1),
 ('manager01',   '$2a$10$Z.zbDzZQJonE3UWEYONoceuRrUPl1DDeXqeYXPWs3w5.Ni0w7M7Hu', N'Иванова Ольга Петровна',   'MANAGER',     1,    1),
 ('reception01', '$2a$10$Z.zbDzZQJonE3UWEYONoceuRrUPl1DDeXqeYXPWs3w5.Ni0w7M7Hu', N'Петрова Анна Сергеевна',   'RECEPTION',   1,    1),
 ('coach01',     '$2a$10$Z.zbDzZQJonE3UWEYONoceuRrUPl1DDeXqeYXPWs3w5.Ni0w7M7Hu', N'Смирнов Дмитрий Павлович', 'COACH',       2,    1),
 ('storekeeper01','$2a$10$Z.zbDzZQJonE3UWEYONoceuRrUPl1DDeXqeYXPWs3w5.Ni0w7M7Hu',N'Кузнецова Мария Олеговна', 'STOREKEEPER', 2,    1),
 ('accountant01','$2a$10$Z.zbDzZQJonE3UWEYONoceuRrUPl1DDeXqeYXPWs3w5.Ni0w7M7Hu', N'Соколов Никита Андреевич', 'ACCOUNTANT',  NULL, 1),
 ('marketer01',  '$2a$10$Z.zbDzZQJonE3UWEYONoceuRrUPl1DDeXqeYXPWs3w5.Ni0w7M7Hu', N'Морозов Артём Игоревич',   'MARKETER',    NULL, 1),
 ('admin',       '$2a$10$Z.zbDzZQJonE3UWEYONoceuRrUPl1DDeXqeYXPWs3w5.Ni0w7M7Hu', N'Администратор Системы',    'ADMIN',       NULL, 1);
GO

-- ----------------------------------------------------------------------------
-- Контроль: должно быть 8 сотрудников, все активные
-- ----------------------------------------------------------------------------
SELECT username, full_name, role, branch_id, is_active
FROM dbo.staff
ORDER BY id;
GO