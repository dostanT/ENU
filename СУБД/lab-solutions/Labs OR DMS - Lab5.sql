USE master;
GO
SELECT @@VERSION AS server_version;
SELECT SUSER_NAME() AS login_name, IS_SRVROLEMEMBER(N'sysadmin') AS is_sysadmin, DB_NAME() AS current_db;
EXEC sp_helpsrvrole;
GO
EXEC sp_addlogin N'TempUser', N'Password!';
EXEC sp_helplogins N'TempUser';
GO
EXEC sp_addsrvrolemember N'TempUser', N'securityadmin';
EXEC sp_helpsrvrolemember N'securityadmin';
GO
EXECUTE AS LOGIN = N'TempUser';
SELECT SUSER_NAME() AS login_name, IS_SRVROLEMEMBER(N'securityadmin') AS is_securityadmin;
REVERT;
GO

USE FitnessCRM;
GO
EXEC sp_helprole;
EXEC sp_helprolemember N'db_owner';
GO
EXEC sp_adduser N'TempUser', N'MyFirstUser';
EXEC sp_helpuser N'MyFirstUser';
GO
EXEC sp_addrolemember N'db_datareader', N'MyFirstUser';
EXEC sp_helprolemember N'db_datareader';
GO

USE FitnessCRM;
GO
CREATE LOGIN Andy WITH PASSWORD = N'Lab5#Passw0rd', DEFAULT_DATABASE = FitnessCRM;
CREATE LOGIN TestUser WITH PASSWORD = N'Lab5#Passw0rd', DEFAULT_DATABASE = FitnessCRM;
CREATE USER Andy FOR LOGIN Andy;
CREATE USER TestUser FOR LOGIN TestUser;
GO
GRANT SELECT, UPDATE ON dbo.memberships TO TestUser;
GRANT SELECT ON dbo.clients (id, code, full_name) TO TestUser;
GRANT SELECT ON dbo.membership_types TO Andy;
GRANT UPDATE ON dbo.membership_types (base_price, is_active) TO Andy;
GO
SELECT dp.name AS grantee, p.permission_name, p.state_desc, OBJECT_NAME(p.major_id) AS table_name, COL_NAME(p.major_id, p.minor_id) AS column_name
FROM sys.database_permissions AS p
JOIN sys.database_principals AS dp ON dp.principal_id = p.grantee_principal_id
WHERE p.class = 1 AND dp.name IN (N'Andy', N'TestUser')
ORDER BY dp.name, table_name, column_name, p.permission_name;
GO
EXECUTE AS USER = N'Andy';
SELECT id, code, base_price FROM dbo.membership_types ORDER BY id;
BEGIN TRAN;
UPDATE dbo.membership_types SET base_price = base_price WHERE id = 1;
ROLLBACK;
UPDATE dbo.membership_types SET code = code WHERE id = 1;
SELECT id FROM dbo.clients;
REVERT;
GO
EXECUTE AS USER = N'TestUser';
SELECT TOP (3) id, code, full_name FROM dbo.clients ORDER BY id;
SELECT phone FROM dbo.clients;
REVERT;
GO

USE FitnessCRM;
GO
EXEC sp_droprolemember N'db_datareader', N'MyFirstUser';
EXEC sp_dropuser N'MyFirstUser';
GO
EXEC sp_dropsrvrolemember N'TempUser', N'securityadmin';
EXEC sp_droplogin N'TempUser';
GO
SELECT name FROM sys.server_principals WHERE name = N'TempUser';
SELECT name FROM sys.database_principals WHERE name = N'MyFirstUser';
SELECT name FROM sys.schemas WHERE name = N'MyFirstUser';
GO

USE master;
GO
EXEC sp_helpsrvrole;
EXEC sp_srvrolepermission N'dbcreator';
GO
EXEC sp_helpsrvrolemember N'sysadmin';
SELECT m.name AS member_name, r.name AS server_role, m.is_disabled
FROM sys.server_role_members AS rm
JOIN sys.server_principals AS r ON r.principal_id = rm.role_principal_id
JOIN sys.server_principals AS m ON m.principal_id = rm.member_principal_id
WHERE m.name = N'sa';
GO

USE master;
GO
EXEC sp_srvrolepermission N'securityadmin';
GO
CREATE LOGIN lab5_sec WITH PASSWORD = N'Lab5#Passw0rd';
ALTER SERVER ROLE securityadmin ADD MEMBER lab5_sec;
GO
EXECUTE AS LOGIN = N'lab5_sec';
SELECT permission_name FROM sys.fn_my_permissions(NULL, N'SERVER') ORDER BY permission_name;
CREATE LOGIN lab5_sec_made WITH PASSWORD = N'Lab5#Passw0rd';
SELECT name, type_desc FROM sys.server_principals WHERE name = N'lab5_sec_made';
DROP LOGIN lab5_sec_made;
SELECT name FROM sys.server_principals WHERE name = N'lab5_sec_made';
REVERT;
GO
DROP LOGIN lab5_sec;
GO

USE master;
GO
CREATE LOGIN lab5_pwd WITH PASSWORD = N'Lab5#Passw0rd';
GO
SELECT name, PWDCOMPARE(N'Lab5#Passw0rd', password_hash) AS old_matches, PWDCOMPARE(N'Lab5#NewPassw0rd', password_hash) AS new_matches FROM sys.sql_logins WHERE name = N'lab5_pwd';
EXEC sp_password @old = N'Lab5#Passw0rd', @new = N'Lab5#NewPassw0rd', @loginame = N'lab5_pwd';
SELECT name, PWDCOMPARE(N'Lab5#Passw0rd', password_hash) AS old_matches, PWDCOMPARE(N'Lab5#NewPassw0rd', password_hash) AS new_matches FROM sys.sql_logins WHERE name = N'lab5_pwd';
GO

USE master;
GO
CREATE LOGIN lab5_dev WITH PASSWORD = N'Lab5#Passw0rd', DEFAULT_DATABASE = FitnessCRM;
SELECT name, type_desc, default_database_name, is_disabled FROM sys.server_principals WHERE name = N'lab5_dev';
GO
ALTER SERVER ROLE dbcreator ADD MEMBER lab5_dev;
EXEC sp_helpsrvrolemember N'dbcreator';
GO
EXECUTE AS LOGIN = N'lab5_dev';
SELECT SUSER_NAME() AS login_name, IS_SRVROLEMEMBER(N'dbcreator') AS is_dbcreator, IS_SRVROLEMEMBER(N'securityadmin') AS is_securityadmin;
SELECT permission_name FROM sys.fn_my_permissions(NULL, N'SERVER') ORDER BY permission_name;
CREATE DATABASE lab5_dev_db;
ALTER DATABASE lab5_dev_db SET RECOVERY SIMPLE;
SELECT name, SUSER_SNAME(owner_sid) AS owner_login, recovery_model_desc FROM sys.databases WHERE name = N'lab5_dev_db';
CREATE LOGIN lab5_other WITH PASSWORD = N'Lab5#Passw0rd';
REVERT;
GO

USE FitnessCRM;
GO
CREATE USER manager FOR LOGIN lab5_dev;
GO
EXEC sp_helpuser N'manager';
SELECT dp.name AS db_user, dp.type_desc, sp.name AS login_name, dp.default_schema_name
FROM sys.database_principals AS dp
JOIN sys.server_principals AS sp ON sp.sid = dp.sid
WHERE dp.name = N'manager';
GO
EXECUTE AS USER = N'manager';
SELECT USER_NAME() AS db_user, SUSER_NAME() AS login_name, DB_NAME() AS current_db;
REVERT;
GO

USE FitnessCRM;
GO
ALTER ROLE db_datareader ADD MEMBER manager;
EXEC sp_helprolemember N'db_datareader';
GO
EXECUTE AS USER = N'manager';
SELECT TOP (5) * FROM dbo.memberships ORDER BY id;
INSERT INTO dbo.branches (code, name, address) VALUES (N'ZZ', N'test', N'test');
REVERT;
GO

USE FitnessCRM;
GO
ALTER ROLE db_denydatareader ADD MEMBER manager;
GO
SELECT r.name AS role_name, m.name AS member_name
FROM sys.database_role_members AS rm
JOIN sys.database_principals AS r ON r.principal_id = rm.role_principal_id
JOIN sys.database_principals AS m ON m.principal_id = rm.member_principal_id
WHERE m.name = N'manager'
ORDER BY r.name;
GO
EXECUTE AS USER = N'manager';
SELECT TOP (5) * FROM dbo.memberships ORDER BY id;
SELECT HAS_PERMS_BY_NAME(N'dbo.memberships', N'OBJECT', N'SELECT') AS can_select_memberships;
REVERT;
GO

USE FitnessCRM;
GO
CREATE USER manager2 FOR LOGIN lab5_dev;
GO
USE master;
GO
CREATE DATABASE lab5_scratch;
GO
USE lab5_scratch;
GO
CREATE USER manager2 FOR LOGIN lab5_dev;
GO
SELECT DB_NAME() AS db, dp.name AS db_user, sp.name AS login_name FROM sys.database_principals AS dp JOIN sys.server_principals AS sp ON sp.sid = dp.sid WHERE sp.name = N'lab5_dev';
GO
USE FitnessCRM;
GO
SELECT DB_NAME() AS db, dp.name AS db_user, sp.name AS login_name FROM sys.database_principals AS dp JOIN sys.server_principals AS sp ON sp.sid = dp.sid WHERE sp.name = N'lab5_dev';
GO

USE master;
GO
CREATE LOGIN lab5_disk WITH PASSWORD = N'Lab5#Passw0rd', DEFAULT_DATABASE = FitnessCRM;
ALTER SERVER ROLE diskadmin ADD MEMBER lab5_disk;
GO
SELECT sp.name, sp.type_desc, sp.default_database_name, sl.is_policy_checked
FROM sys.server_principals AS sp
JOIN sys.sql_logins AS sl ON sl.principal_id = sp.principal_id
WHERE sp.name = N'lab5_disk';
EXEC sp_helpsrvrolemember N'diskadmin';
EXEC sp_srvrolepermission N'diskadmin';
GO
EXECUTE AS LOGIN = N'lab5_disk';
SELECT permission_name FROM sys.fn_my_permissions(NULL, N'SERVER') ORDER BY permission_name;
REVERT;
GO

USE FitnessCRM;
GO
CREATE USER diskuser FOR LOGIN lab5_disk;
GO
EXEC sp_helpuser N'diskuser';
GO
EXECUTE AS USER = N'diskuser';
SELECT IS_MEMBER(N'public') AS in_public, IS_MEMBER(N'db_datareader') AS in_db_datareader;
SELECT * FROM dbo.membership_types;
SELECT HAS_PERMS_BY_NAME(N'dbo.membership_types', N'OBJECT', N'SELECT') AS can_select;
REVERT;
GO

USE FitnessCRM;
GO
CREATE ROLE managers;
GRANT SELECT ON dbo.membership_types TO managers;
ALTER ROLE managers ADD MEMBER diskuser;
GO
EXECUTE AS USER = N'diskuser';
SELECT IS_MEMBER(N'managers') AS in_managers;
SELECT id, code, kind, months, base_price FROM dbo.membership_types ORDER BY id;
SELECT TOP (1) * FROM dbo.clients;
REVERT;
GO
DECLARE @t TABLE (table_name sysname);
INSERT INTO @t SELECT name FROM sys.tables;
EXECUTE AS USER = N'diskuser';
SELECT table_name,
       HAS_PERMS_BY_NAME(N'dbo.' + table_name, N'OBJECT', N'SELECT') AS can_select,
       HAS_PERMS_BY_NAME(N'dbo.' + table_name, N'OBJECT', N'INSERT') AS can_insert,
       HAS_PERMS_BY_NAME(N'dbo.' + table_name, N'OBJECT', N'UPDATE') AS can_update,
       HAS_PERMS_BY_NAME(N'dbo.' + table_name, N'OBJECT', N'DELETE') AS can_delete
FROM @t ORDER BY table_name;
SELECT name AS visible_table FROM sys.tables ORDER BY name;
REVERT;
GO

USE FitnessCRM;
GO
DROP USER IF EXISTS Andy;
DROP USER IF EXISTS TestUser;
DROP USER IF EXISTS manager;
DROP USER IF EXISTS diskuser;
DROP ROLE IF EXISTS managers;
GO
USE master;
GO
DROP DATABASE IF EXISTS lab5_scratch;
DROP DATABASE IF EXISTS lab5_dev_db;
GO
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'Andy') DROP LOGIN Andy;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'TestUser') DROP LOGIN TestUser;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'lab5_pwd') DROP LOGIN lab5_pwd;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'lab5_dev') DROP LOGIN lab5_dev;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'lab5_disk') DROP LOGIN lab5_disk;
GO
SELECT name FROM sys.server_principals WHERE name IN (N'TempUser', N'Andy', N'TestUser', N'lab5_sec', N'lab5_pwd', N'lab5_dev', N'lab5_disk');
SELECT name FROM sys.databases WHERE name IN (N'lab5_scratch', N'lab5_dev_db');
GO
