Лабораторная работа 5 - Система безопасности MS SQL Server (на базе FitnessCRM)

Файл с кодом

Чистая версия без комментариев - файл "Labs OR DMS - Lab5.sql" рядом с этим разбором (всего строк: 272). Здесь та же программа с комментариями, разбитая на 16 блоков; блоки идут в том же порядке, что и в файле, у каждого указаны его строки в .sql. Блоки 1-4 - задания 1-8 из методички, блоки 5-15 - 14 пунктов самостоятельной работы (СРС = самостоятельная работа студента, раздел Independent work методички), блок 16 - очистка.

Что это за лаба, коротко

Лаба про то, кого пускать в SQL Server и что ему там разрешать. Три слоя: логин (кто вообще может зайти на сервер), пользователь базы (кто может зайти в конкретную базу) и права (что можно делать внутри: выдать, запретить, собрать в роль). Методичка написана под SQL Server 2008 и базу AdventureWorks2008. Здесь она сделана на SQL Server 2025 Express и на базе проекта FitnessCRM, в SSMS.

Сначала картинка из жизни

Сервер - это бизнес-центр, база данных - один кабинет внутри него.
- Логин - пропуск на проходной. С ним пускают в здание, но ни в один кабинет сам по себе он не пустит.
- Пользователь базы - карточка доступа в конкретный кабинет, привязанная к твоему пропуску. Нет карточки - в кабинет не зайти, даже если пропуск есть.
- Роль - связка ключей: выдал связку, и человек сразу получил весь набор. Есть связки на всё здание (серверные роли: sysadmin - хозяин здания, securityadmin - выдаёт пропуска, dbcreator - строит новые кабинеты, diskadmin - ведает дисками) и связки на один кабинет (роли базы: db_owner - хозяин кабинета, db_datareader - читать всё, db_denydatareader - читать запрещено). Роль public - ключ, который автоматически есть у всех.
- GRANT - выдать право. DENY - запретить: запрет сильнее любой выдачи, если в одной связке читать разрешено, а в другой запрещено, победит запрет. REVOKE - стереть запись и вернуться к «ничего не сказано» (доступа нет, но и запрета нет).

Что на что заменено (материал проекта)

- База AdventureWorks2008 - база FitnessCRM.
- Таблица Production.Product (поля Name и ListPrice) - dbo.membership_types (виды абонементов: code, base_price, is_active), то есть каталог «что продаём и за сколько». «Название» тут - code, но код - это ключ, менять его как имя нельзя, поэтому для задания «менять только два поля» взяты base_price и is_active: именно их директор правит в прайс-листе.
- Таблица Production.WorkOrder (для проверки через SELECT *) - dbo.memberships (абонементы клиентов).
- Подключение под sa без пароля - подключение своей учётной записью Windows (в SSMS это Windows Authentication). На этом сервере sa отключён (см. блок 5), поэтому входим по Windows.
- SQL Server 2008 - SQL Server 2025 Express. Процедуры из методички (sp_addlogin, sp_adduser, sp_addrolemember и другие) считаются устаревшими, но в 2025 работают (проверено), поэтому в заданиях 1-8 оставлены именно они. В самостоятельной работе чаще современные команды. Соответствие:
  sp_addlogin - CREATE LOGIN; sp_droplogin - DROP LOGIN;
  sp_password - ALTER LOGIN ... WITH PASSWORD = новый OLD_PASSWORD = старый;
  sp_addsrvrolemember / sp_dropsrvrolemember - ALTER SERVER ROLE роль ADD MEMBER / DROP MEMBER логин;
  sp_adduser - CREATE USER имя FOR LOGIN логин (разница: sp_adduser заодно создаёт одноимённую схему, CREATE USER - нет);
  sp_dropuser - DROP USER;
  sp_addrolemember / sp_droprolemember - ALTER ROLE роль ADD MEMBER / DROP MEMBER пользователь.

Как запускать

1. В SSMS подключиться к серверу .\SQLEXPRESS через Windows Authentication, под учётной записью с правами sysadmin. Не под fitnesscrm_app: у него права только внутри FitnessCRM, а команды лабы (CREATE LOGIN, серверные роли) серверные.
2. File - Open - File..., выбрать "Labs OR DMS - Lab5.sql". Выделять блок целиком (с его строками GO) и нажимать F5. Номера строк блока указаны в его названии, текущую строку SSMS показывает внизу окна (Ln).
3. Блоки идут по порядку: пользователи и роли одного блока нужны следующим. Блок 16 удаляет всё созданное, запускать его последним, когда скриншоты сделаны. Если начинаешь заново - сначала блок 16.
4. Красный текст в Messages в блоках 3, 8, 10, 11, 12, 14 и 15 - не поломка: это ожидаемые отказы («permission denied», «login already has an account»), они и есть доказательство.
5. Скрипт не меняет данные FitnessCRM: UPDATE в блоке 3 присваивает значению само себя внутри транзакции и откатывается, INSERT в блоке 10 отклоняется. Он создаёт и удаляет только свои логины, пользователей, роль managers и две временные базы lab5_scratch и lab5_dev_db. Пароли в скрипте учебные.
6. Ловушка EXECUTE AS: блок «примеряет» чужого пользователя до команды REVERT. Обычные отказы (нет права на SELECT, INSERT, UPDATE, на создание логина) пакет не обрывают, REVERT выполняется. Но отказ на DDL (например CREATE TABLE) обрывает пакет целиком, и окно остаётся «под чужим пользователем». Лечится отдельной командой REVERT; в блоках лабы таких команд нет.

Схема: кто с кем связан

Блоки 1-4 (задания методички):
- логин TempUser (роль securityadmin) - пользователь MyFirstUser в FitnessCRM (роль db_datareader); в блоке 4 всё это удаляется;
- логины Andy и TestUser - одноимённые пользователи с правами на таблицы (остаются до блока 16).
Блоки 5-15 (самостоятельная работа):
- логины lab5_sec и lab5_pwd - одноразовые, для вопросов про securityadmin и смену пароля;
- логин lab5_dev (роль dbcreator, стартовая база FitnessCRM) - пользователь manager (роли db_datareader и db_denydatareader), в блоке 12 ещё пользователь manager2 во временной базе lab5_scratch;
- логин lab5_disk (роль diskadmin) - пользователь diskuser (сначала только public, потом роль managers с одним правом: SELECT на membership_types).

Блок 1. Задания 1-3: подключение, роли сервера, логин TempUser (строки 1-16 в .sql)

```sql
-- Задания 1-2: кто мы на сервере и какие встроенные роли есть
USE master;
GO
SELECT @@VERSION AS server_version;
-- под каким логином подключены и есть ли права главного администратора
SELECT SUSER_NAME() AS login_name, IS_SRVROLEMEMBER(N'sysadmin') AS is_sysadmin, DB_NAME() AS current_db;
-- список встроенных серверных ролей
EXEC sp_helpsrvrole;
GO
-- Задание 3: создаём логин TempUser (имя и пароль из методички)
EXEC sp_addlogin N'TempUser', N'Password!';
-- проверка: логин появился
EXEC sp_helplogins N'TempUser';
GO
-- кладём логин во встроенную роль securityadmin
EXEC sp_addsrvrolemember N'TempUser', N'securityadmin';
EXEC sp_helpsrvrolemember N'securityadmin';
GO
-- "входим" под TempUser прямо в этом окне, потом возвращаемся
EXECUTE AS LOGIN = N'TempUser';
SELECT SUSER_NAME() AS login_name, IS_SRVROLEMEMBER(N'securityadmin') AS is_securityadmin;
REVERT;
GO
```

Что делает блок. SUSER_NAME() возвращает имя логина текущего подключения, IS_SRVROLEMEMBER(N'sysadmin') даёт 1, если мы в роли главного администратора (для лабы нужен именно он). sp_helpsrvrole показывает встроенные серверные роли: 8 классических (sysadmin ... bulkadmin, как на рис. 5.1 методички) и ещё 10 с именами в ##...## - они появились в SQL Server 2022 как узкие роли (читатели состояния сервера и т. п.; это по документации Microsoft, не проверено), в этой лабе не нужны.

Задание 3. sp_addlogin N'TempUser', N'Password!' - первый параметр имя логина, второй пароль; стартовая база у логина - master. sp_helplogins выводит два списка: строку самого логина (SID - его внутренний номер) и список баз, где у логина есть пользователь (пока пусто). sp_addsrvrolemember кладёт логин в роль securityadmin. Шаг «попробуйте войти под созданной учётной записью» в одном окне выполнен через EXECUTE AS LOGIN (окно примеряет чужой логин до команды REVERT); настоящий вход через новое подключение - ниже.

Результат:

```
Changed database context to 'master'.
server_version
--------------
Microsoft SQL Server 2025 (RTM) - 17.0.1000.7 (X64) 
	Oct 21 2025 12:05:57 
	Copyright (C) 2025 Microsoft Corporation
	Express Edition (64-bit) on Windows 10 Home 10.0 <X64> (Build 26200: )


(1 rows affected)
login_name|is_sysadmin|current_db
----------|-----------|----------
DOMAIN\admin|1|master

(1 rows affected)
ServerRole|Description
----------|-----------
sysadmin|System Administrators
securityadmin|Security Administrators
serveradmin|Server Administrators
setupadmin|Setup Administrators
processadmin|Process Administrators
diskadmin|Disk Administrators
dbcreator|Database Creators
bulkadmin|Bulk Insert Administrators
##MS_ServerStateReader##|Server State Readers
##MS_ServerStateManager##|Server State Managers
##MS_DefinitionReader##|Definition Readers
##MS_DatabaseConnector##|Database Connectors
##MS_DatabaseManager##|Database Managers
##MS_LoginManager##|Login Managers
##MS_SecurityDefinitionReader##|Security Definition Readers
##MS_PerformanceDefinitionReader##|Performance Definition Readers
##MS_ServerSecurityStateReader##|Server Security State Readers
##MS_ServerPerformanceStateReader##|Server Performance State Readers

(18 rows affected)
LoginName|SID|DefDBName|DefLangName|AUser|ARemote
---------|---|---------|-----------|-----|-------
TempUser|0x8261461BEA11D14DB7B7EAE58E07DFAA|master|us_english|NO   |no     

(1 rows affected)
LoginName|DBName|UserName|UserOrAlias
---------|------|--------|-----------

(0 rows affected)
ServerRole|MemberName|MemberSID
----------|----------|---------
securityadmin|TempUser|0x8261461BEA11D14DB7B7EAE58E07DFAA

(1 rows affected)
login_name|is_securityadmin
----------|----------------
TempUser|1

(1 rows affected)
```

Настоящий вход под TempUser. В SSMS: Connect - Database Engine - Authentication: SQL Server Authentication, Login TempUser, Password Password!. То же из командной строки (так проверял я); в третьем запуске пароль неверный:

```
sqlcmd -S .\SQLEXPRESS -U TempUser -P Password! -C -W -s "|" -Q "SELECT SUSER_NAME() AS login_name, DB_NAME() AS current_db, IS_SRVROLEMEMBER('securityadmin') AS is_securityadmin"
login_name|current_db|is_securityadmin
----------|----------|----------------
TempUser|master|1

(1 rows affected)

sqlcmd -S .\SQLEXPRESS -U TempUser -P WrongPassword1! -C -W -Q "SELECT 1"
Sqlcmd: Error: Microsoft ODBC Driver 18 for SQL Server : Login failed for user 'TempUser'..
```

Блок 2. Задания 4-5: роли базы, пользователь MyFirstUser (строки 18-28 в .sql)

```sql
-- Задание 4: роли базы данных и владельцы базы
USE FitnessCRM;
GO
-- все роли базы: встроенные (db_...) и public
EXEC sp_helprole;
-- кто входит в db_owner (хозяева базы)
EXEC sp_helprolemember N'db_owner';
GO
-- Задание 5: пользователь базы для логина TempUser
-- первый параметр - логин, второй - имя пользователя внутри базы
EXEC sp_adduser N'TempUser', N'MyFirstUser';
-- проверка: к какой роли отнесён пользователь
EXEC sp_helpuser N'MyFirstUser';
GO
-- добавляем в роль "читать все таблицы" (в методичке опечатка в кавычках)
EXEC sp_addrolemember N'db_datareader', N'MyFirstUser';
EXEC sp_helprolemember N'db_datareader';
GO
```

Что делает блок. sp_helprole - 10 ролей базы: public и 9 встроенных (db_owner, db_accessadmin, db_securityadmin, db_ddladmin, db_backupoperator, db_datareader, db_datawriter, db_denydatareader, db_denydatawriter). sp_helprolemember N'db_owner' показывает хозяев базы: dbo (владелец базы) и fitnesscrm_app - логин приложения из недели 1 проекта: он сейчас db_owner в FitnessCRM, то есть может в этой базе всё (к этому вернёмся в «Как применить в проекте»).

sp_adduser N'TempUser', N'MyFirstUser' - логин TempUser получает в базе пользователя MyFirstUser. Ответ на вопрос методички «какая роль назначена пользователю»: public (столбец RoleName у sp_helpuser) - в неё автоматически входят все. Заметь DefSchemaName = MyFirstUser: sp_adduser заодно создал одноимённую схему, а CREATE USER (дальше в лабе) по умолчанию кладёт пользователя в схему dbo. sp_addrolemember N'db_datareader', N'MyFirstUser' - роль идёт первым параметром, пользователь вторым; в методичке при этом пропущена кавычка.

Результат:

```
Changed database context to 'FitnessCRM'.
RoleName|RoleId|IsAppRole
--------|------|---------
public|0|0
db_owner|16384|0
db_accessadmin|16385|0
db_securityadmin|16386|0
db_ddladmin|16387|0
db_backupoperator|16389|0
db_datareader|16390|0
db_datawriter|16391|0
db_denydatareader|16392|0
db_denydatawriter|16393|0

(10 rows affected)
DbRole|MemberName|MemberSID
------|----------|---------
db_owner|dbo|0x0105000000000005150000007F30B689CC9E9350D7B2EC9EEB030000
db_owner|fitnesscrm_app|0xC4823DC23888EF48A8E24976999FD227

(2 rows affected)
UserName|RoleName|LoginName|DefDBName|DefSchemaName|UserID|SID
--------|--------|---------|---------|-------------|------|---
MyFirstUser|public|TempUser|master|MyFirstUser|6         |0x8261461BEA11D14DB7B7EAE58E07DFAA
DbRole|MemberName|MemberSID
------|----------|---------
db_datareader|MyFirstUser|0x8261461BEA11D14DB7B7EAE58E07DFAA

(1 rows affected)
```

Настоящее подключение сразу в базу под этим логином (пользователь MyFirstUser из роли db_datareader читает таблицу):

```
sqlcmd -S .\SQLEXPRESS -U TempUser -P Password! -d FitnessCRM -C -W -s "|" -Q "SELECT USER_NAME() AS db_user, DB_NAME() AS current_db; SELECT TOP (2) id, code, kind, months, base_price FROM dbo.membership_types ORDER BY id;"
db_user|current_db
-------|----------
MyFirstUser|FitnessCRM

(1 rows affected)
id|code|kind|months|base_price
--|----|----|------|----------
1|BASE_1|BASE|1|15000.00
2|STD_3|STD|3|39000.00

(2 rows affected)
```

Блок 3. Задание 6: права Andy и TestUser (строки 30-61 в .sql)

```sql
-- Задание 6: права для Andy и TestUser (в методичке они "уже есть", поэтому сначала создаём)
USE FitnessCRM;
GO
-- два логина и два пользователя базы
CREATE LOGIN Andy WITH PASSWORD = N'Lab5#Passw0rd', DEFAULT_DATABASE = FitnessCRM;
CREATE LOGIN TestUser WITH PASSWORD = N'Lab5#Passw0rd', DEFAULT_DATABASE = FitnessCRM;
CREATE USER Andy FOR LOGIN Andy;
CREATE USER TestUser FOR LOGIN TestUser;
GO
-- пример 1 из методички: права на всю таблицу
GRANT SELECT, UPDATE ON dbo.memberships TO TestUser;
-- пример 2 из методички: право читать только три столбца (в скобках после таблицы)
GRANT SELECT ON dbo.clients (id, code, full_name) TO TestUser;
-- само задание: Andy читает таблицу целиком...
GRANT SELECT ON dbo.membership_types TO Andy;
-- ...а менять может только два столбца
GRANT UPDATE ON dbo.membership_types (base_price, is_active) TO Andy;
GO
-- что реально выдано: строка на каждое право, для столбцов - строка на столбец
SELECT dp.name AS grantee, p.permission_name, p.state_desc, OBJECT_NAME(p.major_id) AS table_name, COL_NAME(p.major_id, p.minor_id) AS column_name
FROM sys.database_permissions AS p
JOIN sys.database_principals AS dp ON dp.principal_id = p.grantee_principal_id
WHERE p.class = 1 AND dp.name IN (N'Andy', N'TestUser')
ORDER BY dp.name, table_name, column_name, p.permission_name;
GO
-- проверка Andy: "примеряем" его пользователя
EXECUTE AS USER = N'Andy';
-- можно: читать таблицу
SELECT id, code, base_price FROM dbo.membership_types ORDER BY id;
-- можно: менять base_price (вхолостую, внутри транзакции, потом откат)
BEGIN TRAN;
UPDATE dbo.membership_types SET base_price = base_price WHERE id = 1;
ROLLBACK;
-- нельзя: менять code (на этот столбец право не выдавали)
UPDATE dbo.membership_types SET code = code WHERE id = 1;
-- нельзя: читать чужую таблицу
SELECT id FROM dbo.clients;
REVERT;
GO
-- проверка TestUser
EXECUTE AS USER = N'TestUser';
-- можно: три выданных столбца
SELECT TOP (3) id, code, full_name FROM dbo.clients ORDER BY id;
-- нельзя: телефон (столбец не выдан)
SELECT phone FROM dbo.clients;
REVERT;
GO
```

Что делает блок. В методичке есть два пробела. Первый: Andy и TestUser «уже существуют», хотя их никто не создавал, - создаём (логин, потом пользователь базы). Второй: текст задания («читать таблицу Product и менять только Name и ListPrice») расходится с примером («GRANT select on Product (Name, ListPrice)» - это чтение только двух столбцов). Сделано по тексту задания: Andy получает SELECT на таблицу целиком и UPDATE только на два столбца; а второй вид записи (права на столбцы) показан на TestUser, и у него смысл проектный: из клиентов видны id, code, full_name, а остальные столбцы (телефон, e-mail, дата рождения) закрыты; отказ проверен на телефоне, остальные закрыты по той же причине - право на них не выдано.

Как это работает. GRANT SELECT ON таблица (столбцы) TO пользователь - список столбцов в скобках сразу после имени таблицы; без скобок право на всю таблицу. Запрос к sys.database_permissions - это «список выданных ключей»: по строке на право, для столбцов по строке на каждый столбец. Проверка идёт через EXECUTE AS USER: окно временно «становится» этим пользователем. UPDATE ... SET base_price = base_price - присвоение значения самому себе: право проверяется, данные не меняются, и всё равно внутри BEGIN TRAN ... ROLLBACK. Два кода отказа: Msg 229 - нет права на объект (таблицу), Msg 230 - нет права на столбец.

Результат:

```
Changed database context to 'FitnessCRM'.
grantee|permission_name|state_desc|table_name|column_name
-------|---------------|----------|----------|-----------
Andy|SELECT|GRANT|membership_types|NULL
Andy|UPDATE|GRANT|membership_types|base_price
Andy|UPDATE|GRANT|membership_types|is_active
TestUser|SELECT|GRANT|clients|code
TestUser|SELECT|GRANT|clients|full_name
TestUser|SELECT|GRANT|clients|id
TestUser|SELECT|GRANT|memberships|NULL
TestUser|UPDATE|GRANT|memberships|NULL

(8 rows affected)
id|code|base_price
--|----|----------
1|BASE_1|15000.00
2|STD_3|39000.00
3|STD_6|72000.00
4|STD_12|130000.00
5|UNLIM_1|25000.00
6|UNLIM_6|120000.00
7|UNLIM_12|210000.00

(7 rows affected)

(1 rows affected)
Msg 230, Level 14, State 1, Server SERVER\SQLEXPRESS, Line 6
The UPDATE permission was denied on the column 'code' of the object 'membership_types', database 'FitnessCRM', schema 'dbo'.
Msg 229, Level 14, State 5, Server SERVER\SQLEXPRESS, Line 7
The SELECT permission was denied on the object 'clients', database 'FitnessCRM', schema 'dbo'.
id|code|full_name
--|----|---------
1|FIZ_01_00001|Иванов Иван Иванович
2|FIZ_01_00002|Петрова Анна Сергеевна
3|FIZ_01_00003|Сидоров Пётр Алексеевич

(3 rows affected)
Msg 230, Level 14, State 1, Server SERVER\SQLEXPRESS, Line 3
The SELECT permission was denied on the column 'phone' of the object 'clients', database 'FitnessCRM', schema 'dbo'.
```

Задание 7. То же самое окнами SSMS (кода нет; я это не выполнял, SSMS мне недоступен, ниже описание по методичке с соответствием командам выше)
- Логины: Object Explorer - Security - Logins. New Login... открывает окно с вкладками: General (имя, тип входа Windows или SQL Server authentication, пароль, стартовая база, язык), Server Roles (галочки серверных ролей: то же, что sp_addsrvrolemember), User Mapping (в какие базы пустить и под каким именем: то же, что sp_adduser, плюс роли базы). Кнопка Script вверху окна показывает T-SQL, который SSMS собирается выполнить: удобно для скриншотов и для понимания.
- Серверные роли: Security - Server Roles; Properties роли показывает членов (то же, что sp_helpsrvrolemember). Встроенные серверные роли нельзя удалить, и их права изменить нельзя.
- Пользователи и роли базы: FitnessCRM - Security - Users (New User...: имя и логин) и Roles - Database Roles (Properties: члены роли).
- Права: Properties пользователя или роли - вкладка Securables. Для каждого объекта три состояния: Grant (галочка), Deny (крестик) и пустое поле - явно ничего не выдано, доступа нет «по умолчанию». Это те же GRANT, DENY и «ничего не сказано».

Блок 4. Задание 8: убрать TempUser (строки 63-74 в .sql)

```sql
-- Задание 8: убираем TempUser (порядок: роли, потом пользователь, потом логин)
USE FitnessCRM;
GO
EXEC sp_droprolemember N'db_datareader', N'MyFirstUser';
EXEC sp_dropuser N'MyFirstUser';
GO
EXEC sp_dropsrvrolemember N'TempUser', N'securityadmin';
EXEC sp_droplogin N'TempUser';
GO
-- проверка: логин, пользователь и его схема исчезли (три пустых результата)
SELECT name FROM sys.server_principals WHERE name = N'TempUser';
SELECT name FROM sys.database_principals WHERE name = N'MyFirstUser';
SELECT name FROM sys.schemas WHERE name = N'MyFirstUser';
GO
```

Что делает блок. Убираем в обратном порядке создания: сначала роль у пользователя, потом пользователя, потом роль сервера у логина, потом сам логин. Так не остаётся «осиротевших» записей: пользователь без логина или логин в роли. Последний запрос показывает, что sp_dropuser убрал и схему MyFirstUser, которую создал sp_adduser. Andy и TestUser остаются, чтобы можно было посмотреть их права в окнах SSMS, их удалит блок 16.

Результат:

```
Changed database context to 'FitnessCRM'.
name
----

(0 rows affected)
name
----

(0 rows affected)
name
----

(0 rows affected)
```

Блок 5. СРС 1-2: серверные роли, права dbcreator, роль sa (строки 76-87 в .sql)

```sql
-- СРС 1: все серверные роли и что можно делать участникам dbcreator
USE master;
GO
EXEC sp_helpsrvrole;
EXEC sp_srvrolepermission N'dbcreator';
GO
-- СРС 2: какая серверная роль у учётной записи sa
EXEC sp_helpsrvrolemember N'sysadmin';
-- то же, но только про sa, и видно, что учётная запись отключена
SELECT m.name AS member_name, r.name AS server_role, m.is_disabled
FROM sys.server_role_members AS rm
JOIN sys.server_principals AS r ON r.principal_id = rm.role_principal_id
JOIN sys.server_principals AS m ON m.principal_id = rm.member_principal_id
WHERE m.name = N'sa';
GO
```

Ответ на СРС 1. Серверные роли - вывод sp_helpsrvrole (восемь встроенных: sysadmin, securityadmin, serveradmin, setupadmin, processadmin, diskadmin, dbcreator, bulkadmin, и десять служебных ##MS_...##). Участникам dbcreator разрешено (sp_srvrolepermission): создавать базы (CREATE DATABASE), изменять (ALTER DATABASE), удалять (DROP DATABASE), восстанавливать из копий (RESTORE DATABASE, RESTORE LOG), расширять базу (Extend database), переименовывать (sp_renamedb) и добавлять членов в саму роль. Практическая проверка этих прав на живом логине - в блоке 8.

Ответ на СРС 2. У sa роль sysadmin. Первый запрос показывает всех участников sysadmin (среди них учётные записи Windows этого компьютера и службы SQL Server; в выводе ниже я их опустил, оставлена строка sa), второй запрос отбирает только sa и заодно показывает is_disabled = 1: на этом сервере учётная запись sa существует и состоит в sysadmin, но отключена, войти под ней нельзя. (Заметка про вывод sp_srvrolepermission: список прав взят из справочной таблицы процедуры; в sys.server_permissions права встроенных ролей не хранятся - запрос туда для sysadmin, securityadmin, diskadmin и dbcreator вернул пусто. Настоящие права члена роли видны через sys.fn_my_permissions, см. блоки 6, 8 и 13.)

Результат:

```
Changed database context to 'master'.
ServerRole|Description
----------|-----------
sysadmin|System Administrators
securityadmin|Security Administrators
serveradmin|Server Administrators
setupadmin|Setup Administrators
processadmin|Process Administrators
diskadmin|Disk Administrators
dbcreator|Database Creators
bulkadmin|Bulk Insert Administrators
##MS_ServerStateReader##|Server State Readers
##MS_ServerStateManager##|Server State Managers
##MS_DefinitionReader##|Definition Readers
##MS_DatabaseConnector##|Database Connectors
##MS_DatabaseManager##|Database Managers
##MS_LoginManager##|Login Managers
##MS_SecurityDefinitionReader##|Security Definition Readers
##MS_PerformanceDefinitionReader##|Performance Definition Readers
##MS_ServerSecurityStateReader##|Server Security State Readers
##MS_ServerPerformanceStateReader##|Server Performance State Readers

(18 rows affected)
ServerRole|Permission
----------|----------
dbcreator|Add member to dbcreator
dbcreator|ALTER DATABASE
dbcreator|CREATE DATABASE
dbcreator|DROP DATABASE
dbcreator|Extend database
dbcreator|RESTORE DATABASE
dbcreator|RESTORE LOG
dbcreator|sp_renamedb

(8 rows affected)
ServerRole|MemberName|MemberSID
----------|----------|---------
sysadmin|sa|0x01

(показана строка sa; ещё 5 строк - учётные записи Windows этого компьютера - опущены)
member_name|server_role|is_disabled
-----------|-----------|-----------
sa|sysadmin|1

(1 rows affected)
```

Блок 6. СРС 3: кто создаёт и удаляет логины (строки 89-105 в .sql)

```sql
-- СРС 3: какая роль может создавать и удалять логины
USE master;
GO
-- что умеет securityadmin по справке процедуры
EXEC sp_srvrolepermission N'securityadmin';
GO
-- пробный логин в роли securityadmin
CREATE LOGIN lab5_sec WITH PASSWORD = N'Lab5#Passw0rd';
ALTER SERVER ROLE securityadmin ADD MEMBER lab5_sec;
GO
-- работаем от его имени
EXECUTE AS LOGIN = N'lab5_sec';
-- его реальные права на сервере
SELECT permission_name FROM sys.fn_my_permissions(NULL, N'SERVER') ORDER BY permission_name;
-- создаём и удаляем логин
CREATE LOGIN lab5_sec_made WITH PASSWORD = N'Lab5#Passw0rd';
SELECT name, type_desc FROM sys.server_principals WHERE name = N'lab5_sec_made';
DROP LOGIN lab5_sec_made;
-- после удаления логина нет (пустой результат)
SELECT name FROM sys.server_principals WHERE name = N'lab5_sec_made';
REVERT;
GO
-- пробный логин больше не нужен
DROP LOGIN lab5_sec;
GO
```

Ответ на СРС 3. Создавать и удалять логины может роль securityadmin (и, конечно, sysadmin, который может всё). Подтверждение двумя способами: в справке sp_srvrolepermission у securityadmin стоят sp_addlogin, sp_droplogin, sp_password, sp_helplogins; и на практике член этой роли создал логин, увидел его в sys.server_principals и удалил. Его реальные права (fn_my_permissions): ALTER ANY LOGIN и CREATE LOGIN - как раз они отвечают за управление логинами; остальные две строки, CONNECT SQL и VIEW ANY DATABASE, - базовые права: они видны у каждого из проверенных логинов. Для контраста: в блоке 8 член dbcreator на ту же команду CREATE LOGIN получает отказ.

Результат:

```
Changed database context to 'master'.
ServerRole|Permission
----------|----------
securityadmin|Add member to securityadmin
securityadmin|Grant/deny/revoke CREATE DATABASE
securityadmin|Read the error log
securityadmin|sp_addlinkedsrvlogin
securityadmin|sp_addlogin
securityadmin|sp_defaultdb
securityadmin|sp_defaultlanguage
securityadmin|sp_denylogin
securityadmin|sp_droplinkedsrvlogin
securityadmin|sp_droplogin
securityadmin|sp_dropremotelogin
securityadmin|sp_grantlogin
securityadmin|sp_helplogins
securityadmin|sp_password
securityadmin|sp_remoteoption (update)
securityadmin|sp_revokelogin

(16 rows affected)
permission_name
---------------
ALTER ANY LOGIN
CONNECT SQL
CREATE LOGIN
VIEW ANY DATABASE

(4 rows affected)
name|type_desc
----|---------
lab5_sec_made|SQL_LOGIN

(1 rows affected)
name
----

(0 rows affected)
```

Блок 7. СРС 4: смена пароля через sp_password (строки 107-114 в .sql)

```sql
-- СРС 4: смена пароля процедурой sp_password
USE master;
GO
CREATE LOGIN lab5_pwd WITH PASSWORD = N'Lab5#Passw0rd';
GO
-- PWDCOMPARE сравнивает текст с хэшем пароля: 1 - совпадает, 0 - нет
SELECT name, PWDCOMPARE(N'Lab5#Passw0rd', password_hash) AS old_matches, PWDCOMPARE(N'Lab5#NewPassw0rd', password_hash) AS new_matches FROM sys.sql_logins WHERE name = N'lab5_pwd';
-- меняем пароль: старый, новый, чей логин
EXEC sp_password @old = N'Lab5#Passw0rd', @new = N'Lab5#NewPassw0rd', @loginame = N'lab5_pwd';
-- после смены результаты поменялись местами
SELECT name, PWDCOMPARE(N'Lab5#Passw0rd', password_hash) AS old_matches, PWDCOMPARE(N'Lab5#NewPassw0rd', password_hash) AS new_matches FROM sys.sql_logins WHERE name = N'lab5_pwd';
GO
```

Что делает блок. SQL Server не хранит пароли, он хранит их хэши (необратимый «отпечаток»). Поэтому проверить смену пароля можно, сравнив текст с отпечатком: PWDCOMPARE(текст, password_hash) возвращает 1, если отпечаток соответствует этому тексту. До смены совпадает старый пароль (old_matches = 1, new_matches = 0), после - наоборот. Параметры sp_password: @old - прежний пароль, @new - новый, @loginame - чей логин. Современная замена: ALTER LOGIN lab5_pwd WITH PASSWORD = N'новый' OLD_PASSWORD = N'старый' (проверено так же, на отдельном пробном логине, результат тот же).

Результат:

```
Changed database context to 'master'.
name|old_matches|new_matches
----|-----------|-----------
lab5_pwd|1|0

(1 rows affected)
name|old_matches|new_matches
----|-----------|-----------
lab5_pwd|0|1

(1 rows affected)
```

Блок 8. СРС 5: свой логин, права на базы, попытка создать ещё логин (строки 116-132 в .sql)

```sql
-- СРС 5: свой логин, права на создание и изменение баз, попытка создать ещё логин
USE master;
GO
-- логин со стартовой базой FitnessCRM
CREATE LOGIN lab5_dev WITH PASSWORD = N'Lab5#Passw0rd', DEFAULT_DATABASE = FitnessCRM;
-- доказательство: логин есть, тип SQL_LOGIN, стартовая база - FitnessCRM
SELECT name, type_desc, default_database_name, is_disabled FROM sys.server_principals WHERE name = N'lab5_dev';
GO
-- права "создавать и менять базы" - это роль dbcreator
ALTER SERVER ROLE dbcreator ADD MEMBER lab5_dev;
EXEC sp_helpsrvrolemember N'dbcreator';
GO
-- "входим" под этим логином
EXECUTE AS LOGIN = N'lab5_dev';
SELECT SUSER_NAME() AS login_name, IS_SRVROLEMEMBER(N'dbcreator') AS is_dbcreator, IS_SRVROLEMEMBER(N'securityadmin') AS is_securityadmin;
-- какие права у него на сервере
SELECT permission_name FROM sys.fn_my_permissions(NULL, N'SERVER') ORDER BY permission_name;
-- создать базу, изменить её параметр, посмотреть владельца - всё разрешено (удалит её блок 16)
CREATE DATABASE lab5_dev_db;
ALTER DATABASE lab5_dev_db SET RECOVERY SIMPLE;
SELECT name, SUSER_SNAME(owner_sid) AS owner_login, recovery_model_desc FROM sys.databases WHERE name = N'lab5_dev_db';
-- а создать ещё один логин нельзя
CREATE LOGIN lab5_other WITH PASSWORD = N'Lab5#Passw0rd';
REVERT;
GO
```

Что делает блок. Первое доказательство: запись о логине в sys.server_principals (тип SQL_LOGIN, стартовая база FitnessCRM). Второе: sp_helpsrvrolemember N'dbcreator' показывает логин в роли. Третье: под этим логином (EXECUTE AS LOGIN) мы создали базу lab5_dev_db, изменили её (ALTER DATABASE ... SET RECOVERY SIMPLE - модель восстановления стала SIMPLE) и увидели владельца - lab5_dev. Права члена dbcreator на сервере: CREATE ANY DATABASE (плюс общие CONNECT SQL и VIEW ANY DATABASE). Удалять эту базу из-под самого логина я не стал: задание требует «создавать и менять», а в одном из моих прогонов сервер оборвал соединение именно на DROP DATABASE под чужим логином (фатальная ошибка 615, плавающая, повторить её отдельно не удалось). Базу удалит блок 16 от имени администратора.

Объяснение результата (то, о чём спрашивает методичка). Команда CREATE LOGIN закончилась ошибкой Msg 15247 «User does not have permission to perform this action». Причина: создавать логины может только тот, у кого есть право ALTER ANY LOGIN, а оно есть у securityadmin и sysadmin (блок 6). Роль dbcreator даёт управление базами и больше ничего: быть «хозяином баз» и «выдавать пропуска» - разные связки ключей. Это принцип наименьших прав: каждому ровно то, что нужно.

Результат:

```
Changed database context to 'master'.
name|type_desc|default_database_name|is_disabled
----|---------|---------------------|-----------
lab5_dev|SQL_LOGIN|FitnessCRM|0

(1 rows affected)
ServerRole|MemberName|MemberSID
----------|----------|---------
dbcreator|lab5_dev|0x47FC530106913C4B9CB53F838C824D11

(1 rows affected)
login_name|is_dbcreator|is_securityadmin
----------|------------|----------------
lab5_dev|1|0

(1 rows affected)
permission_name
---------------
CONNECT SQL
CREATE ANY DATABASE
VIEW ANY DATABASE

(3 rows affected)
name|owner_login|recovery_model_desc
----|-----------|-------------------
lab5_dev_db|lab5_dev|SIMPLE

(1 rows affected)
Msg 15247, Level 16, State 1, Server SERVER\SQLEXPRESS, Line 7
User does not have permission to perform this action.
```

Настоящий вход под lab5_dev. Здесь ловушка. У логина стартовая база FitnessCRM, но пользователя в этой базе у него пока нет (его создаёт блок 9). При входе без указания базы сервер пытается открыть стартовую базу, не может и отказывает: «Cannot open user default database. Login failed.» (код 4064). Выход: при подключении указать другую базу, например master, - в SSMS это Options >> Connection Properties >> Connect to database: master. Под таким подключением та же команда CREATE LOGIN даёт тот же отказ 15247:

```
sqlcmd -S .\SQLEXPRESS -U lab5_dev -P Lab5#Passw0rd -C -W -Q "SELECT DB_NAME();"
Sqlcmd: Error: Microsoft ODBC Driver 18 for SQL Server : Login failed for user 'lab5_dev'..
Sqlcmd: Error: Microsoft ODBC Driver 18 for SQL Server : Cannot open user default database. Login failed..

sqlcmd -S .\SQLEXPRESS -U lab5_dev -P Lab5#Passw0rd -d master -C -W -s "|" -Q "SELECT SUSER_NAME() AS login_name, DB_NAME() AS current_db, IS_SRVROLEMEMBER('dbcreator') AS is_dbcreator; CREATE LOGIN lab5_other WITH PASSWORD = N'Lab5#Passw0rd';"
login_name|current_db|is_dbcreator
----------|----------|------------
lab5_dev|master|1

(1 rows affected)
Msg 15247, Level 16, State 1, Server SERVER\SQLEXPRESS, Line 1
User does not have permission to perform this action.
```

Блок 9. СРС 6: пользователь manager (строки 134-147 в .sql)

```sql
-- СРС 6: пользователь manager для логина lab5_dev
USE FitnessCRM;
GO
-- имя пользователя может отличаться от имени логина: связь идёт по внутреннему номеру (SID)
CREATE USER manager FOR LOGIN lab5_dev;
GO
EXEC sp_helpuser N'manager';
-- та же связь через системные таблицы
SELECT dp.name AS db_user, dp.type_desc, sp.name AS login_name, dp.default_schema_name
FROM sys.database_principals AS dp
JOIN sys.server_principals AS sp ON sp.sid = dp.sid
WHERE dp.name = N'manager';
GO
-- примеряем пользователя: кто мы и в какой базе
EXECUTE AS USER = N'manager';
SELECT USER_NAME() AS db_user, SUSER_NAME() AS login_name, DB_NAME() AS current_db;
REVERT;
GO
```

Что делает блок. CREATE USER manager FOR LOGIN lab5_dev создаёт в FitnessCRM пользователя manager и привязывает его к логину lab5_dev. Привязка идёт по SID (внутреннему номеру логина), а не по имени, поэтому имена могут быть разными. Доказательство тремя способами: sp_helpuser (пользователь, роль public, логин), соединение таблиц sys.database_principals и sys.server_principals по SID и «примерка» через EXECUTE AS USER. Теперь у логина есть пользователь в стартовой базе, и вход без указания базы работает:

Результат:

```
Changed database context to 'FitnessCRM'.
UserName|RoleName|LoginName|DefDBName|DefSchemaName|UserID|SID
--------|--------|---------|---------|-------------|------|---
manager|public|lab5_dev|FitnessCRM|dbo|6         |0x47FC530106913C4B9CB53F838C824D11
db_user|type_desc|login_name|default_schema_name
-------|---------|----------|-------------------
manager|SQL_USER|lab5_dev|dbo

(1 rows affected)
db_user|login_name|current_db
-------|----------|----------
manager|lab5_dev|FitnessCRM

(1 rows affected)
```

```
sqlcmd -S .\SQLEXPRESS -U lab5_dev -P Lab5#Passw0rd -C -W -s "|" -Q "SELECT SUSER_NAME() AS login_name, USER_NAME() AS db_user, DB_NAME() AS current_db;"
login_name|db_user|current_db
----------|-------|----------
lab5_dev|manager|FitnessCRM

(1 rows affected)
```

Блок 10. СРС 7: роль «только просмотр» (строки 149-158 в .sql)

```sql
-- СРС 7: роль "только просмотр" - db_datareader
USE FitnessCRM;
GO
ALTER ROLE db_datareader ADD MEMBER manager;
EXEC sp_helprolemember N'db_datareader';
GO
EXECUTE AS USER = N'manager';
-- читать можно
SELECT TOP (5) * FROM dbo.memberships ORDER BY id;
-- писать нельзя (запрос отклоняется, ничего не добавится)
INSERT INTO dbo.branches (code, name, address) VALUES (N'ZZ', N'test', N'test');
REVERT;
GO
```

Что делает блок. Роль, которая разрешает только смотреть содержимое базы, - db_datareader (читать все таблицы и представления). ALTER ROLE роль ADD MEMBER пользователь - современная запись sp_addrolemember. Проверка из методички («выполнить запрос к базе»): SELECT проходит, INSERT отклоняется с Msg 229 - добавить строку не вышло, и в таблице branches ничего не появилось. Тот же результат при настоящем подключении ниже.

Результат:

```
Changed database context to 'FitnessCRM'.
DbRole|MemberName|MemberSID
------|----------|---------
db_datareader|manager|0x47FC530106913C4B9CB53F838C824D11

(1 rows affected)
id|client_id|type_id|branch_id|status|start_date|end_date|price_paid
--|---------|-------|---------|------|----------|--------|----------
1|1|2|1|ACTIVE|2026-09-01|2026-12-01|39000.00
2|2|5|1|EXPIRED|2026-09-02|2026-10-02|25000.00
3|3|1|1|EXPIRED|2026-09-03|2026-10-03|15000.00
4|4|3|1|ACTIVE|2026-09-04|2027-03-04|72000.00
5|5|4|1|ACTIVE|2026-09-05|2027-09-05|130000.00

(5 rows affected)
Msg 229, Level 14, State 5, Server SERVER\SQLEXPRESS, Line 3
The INSERT permission was denied on the object 'branches', database 'FitnessCRM', schema 'dbo'.
```

```
sqlcmd -S .\SQLEXPRESS -U lab5_dev -P Lab5#Passw0rd -C -W -s "|" -Q "SELECT TOP (2) id, client_id, status FROM dbo.memberships ORDER BY id; INSERT INTO dbo.branches (code, name, address) VALUES (N'ZZ', N'test', N'test');"
id|client_id|status
--|---------|------
1|1|ACTIVE
2|2|EXPIRED

(2 rows affected)
Msg 229, Level 14, State 5, Server SERVER\SQLEXPRESS, Line 1
The INSERT permission was denied on the object 'branches', database 'FitnessCRM', schema 'dbo'.
```

Блок 11. СРС 8: запретить просмотр (строки 160-175 в .sql)

```sql
-- СРС 8: запрет просмотра - роль db_denydatareader
USE FitnessCRM;
GO
ALTER ROLE db_denydatareader ADD MEMBER manager;
GO
-- manager теперь в двух ролях сразу: читать и разрешено, и запрещено
SELECT r.name AS role_name, m.name AS member_name
FROM sys.database_role_members AS rm
JOIN sys.database_principals AS r ON r.principal_id = rm.role_principal_id
JOIN sys.database_principals AS m ON m.principal_id = rm.member_principal_id
WHERE m.name = N'manager'
ORDER BY r.name;
GO
EXECUTE AS USER = N'manager';
-- запрет побеждает
SELECT TOP (5) * FROM dbo.memberships ORDER BY id;
-- прямой вопрос серверу: есть ли право SELECT на таблицу (1 - да, 0 - нет)
SELECT HAS_PERMS_BY_NAME(N'dbo.memberships', N'OBJECT', N'SELECT') AS can_select_memberships;
REVERT;
GO
```

Что делает блок. Роль db_denydatareader - это встроенный DENY на чтение всех таблиц. Мы не убирали manager из db_datareader, он состоит в обеих ролях сразу, и читать ему и разрешено, и запрещено. Побеждает запрет: DENY сильнее любого GRANT, как бы он ни был получен (в том числе через роль). Как доказать, что всё сделано правильно (вопрос методички): (1) список ролей пользователя показывает обе роли; (2) SELECT возвращает Msg 229 «The SELECT permission was denied»; (3) HAS_PERMS_BY_NAME возвращает 0; (4) то же при настоящем подключении ниже.

Результат:

```
Changed database context to 'FitnessCRM'.
role_name|member_name
---------|-----------
db_datareader|manager
db_denydatareader|manager

(2 rows affected)
Msg 229, Level 14, State 5, Server SERVER\SQLEXPRESS, Line 2
The SELECT permission was denied on the object 'memberships', database 'FitnessCRM', schema 'dbo'.
can_select_memberships
----------------------
0

(1 rows affected)
```

```
sqlcmd -S .\SQLEXPRESS -U lab5_dev -P Lab5#Passw0rd -C -W -s "|" -Q "SELECT TOP (2) id, client_id, status FROM dbo.memberships ORDER BY id;"
Msg 229, Level 14, State 5, Server SERVER\SQLEXPRESS, Line 1
The SELECT permission was denied on the object 'memberships', database 'FitnessCRM', schema 'dbo'.
```

Блок 12. СРС 9: сколько пользователей базы можно создать на один логин (строки 177-194 в .sql)

```sql
-- СРС 9: сколько пользователей базы можно создать на один логин
USE FitnessCRM;
GO
-- вторая попытка в той же базе - ошибка
CREATE USER manager2 FOR LOGIN lab5_dev;
GO
-- временная вторая база
USE master;
GO
CREATE DATABASE lab5_scratch;
GO
USE lab5_scratch;
GO
-- в другой базе тот же логин получает ещё одного пользователя
CREATE USER manager2 FOR LOGIN lab5_dev;
GO
SELECT DB_NAME() AS db, dp.name AS db_user, sp.name AS login_name FROM sys.database_principals AS dp JOIN sys.server_principals AS sp ON sp.sid = dp.sid WHERE sp.name = N'lab5_dev';
GO
USE FitnessCRM;
GO
SELECT DB_NAME() AS db, dp.name AS db_user, sp.name AS login_name FROM sys.database_principals AS dp JOIN sys.server_principals AS sp ON sp.sid = dp.sid WHERE sp.name = N'lab5_dev';
GO
```

Ответ на СРС 9. В одной базе - ровно один пользователь на логин: вторая попытка в FitnessCRM закончилась ошибкой Msg 15063 «The login already has an account with the user name 'manager'». В каждой другой базе тот же логин может получить своего пользователя (manager в FitnessCRM и manager2 в lab5_scratch, оба смотрят на один логин lab5_dev). Итого: на один логин можно создать столько пользователей, сколько баз на сервере, по одному на базу. Обоснование: пользователь - это «карточка в конкретный кабинет», а логин (пропуск) один; в одном кабинете двух карточек на один пропуск быть не может, а кабинетов много.

Результат:

```
Changed database context to 'FitnessCRM'.
Msg 15063, Level 16, State 1, Server SERVER\SQLEXPRESS, Line 1
The login already has an account with the user name 'manager'.
Changed database context to 'master'.
Changed database context to 'lab5_scratch'.
db|db_user|login_name
--|-------|----------
lab5_scratch|manager2|lab5_dev

(1 rows affected)
Changed database context to 'FitnessCRM'.
db|db_user|login_name
--|-------|----------
FitnessCRM|manager|lab5_dev

(1 rows affected)
```

Блок 13. СРС 10-11: логин с ролью diskadmin, члены и права роли (строки 196-211 в .sql)

```sql
-- СРС 10: логин с SQL-аутентификацией, стартовая база FitnessCRM, роль diskadmin (то, что SSMS делает кнопками)
USE master;
GO
CREATE LOGIN lab5_disk WITH PASSWORD = N'Lab5#Passw0rd', DEFAULT_DATABASE = FitnessCRM;
ALTER SERVER ROLE diskadmin ADD MEMBER lab5_disk;
GO
-- проверка: логин, стартовая база, включена ли проверка политики паролей
SELECT sp.name, sp.type_desc, sp.default_database_name, sl.is_policy_checked
FROM sys.server_principals AS sp
JOIN sys.sql_logins AS sl ON sl.principal_id = sp.principal_id
WHERE sp.name = N'lab5_disk';
-- СРС 11: кто входит в diskadmin и что роль может
EXEC sp_helpsrvrolemember N'diskadmin';
EXEC sp_srvrolepermission N'diskadmin';
GO
-- реальные права члена роли
EXECUTE AS LOGIN = N'lab5_disk';
SELECT permission_name FROM sys.fn_my_permissions(NULL, N'SERVER') ORDER BY permission_name;
REVERT;
GO
```

СРС 10 окнами SSMS (задание просит именно SSMS; я это окнами не выполнял, команды выше - то, что SSMS генерирует кнопкой Script): Object Explorer - Security - Logins - правая кнопка - New Login... Вкладка General: Login name lab5_disk, переключатель SQL Server authentication, пароль и подтверждение, Default database - FitnessCRM. Вкладка Server Roles: галочка diskadmin. OK. Что получилось, проверяется запросом выше: тип SQL_LOGIN, стартовая база FitnessCRM, проверка политики паролей включена (is_policy_checked = 1).

Ответ на СРС 11. В diskadmin входит только что созданный lab5_disk. Роль отвечает за дисковые файлы сервера: по справке процедуры - DISK INIT, sp_addumpdevice, sp_diskdefault, sp_dropdevice (и добавление членов); реальное право члена, которое показывает fn_my_permissions: ALTER RESOURCES (плюс общие CONNECT SQL и VIEW ANY DATABASE). Читать или менять данные в таблицах эта роль не позволяет.

Результат:

```
Changed database context to 'master'.
name|type_desc|default_database_name|is_policy_checked
----|---------|---------------------|-----------------
lab5_disk|SQL_LOGIN|FitnessCRM|1

(1 rows affected)
ServerRole|MemberName|MemberSID
----------|----------|---------
diskadmin|lab5_disk|0x954AB39F309AB743AB78968B62F2F2AA

(1 rows affected)
ServerRole|Permission
----------|----------
diskadmin|Add member to diskadmin
diskadmin|DISK INIT
diskadmin|sp_addumpdevice
diskadmin|sp_diskdefault
diskadmin|sp_dropdevice

(5 rows affected)
permission_name
---------------
ALTER RESOURCES
CONNECT SQL
VIEW ANY DATABASE

(3 rows affected)
```

Блок 14. СРС 12-13: пользователь на логине lab5_disk, его роль и права (строки 213-224 в .sql)

```sql
-- СРС 12: пользователь базы для логина lab5_disk
USE FitnessCRM;
GO
CREATE USER diskuser FOR LOGIN lab5_disk;
GO
-- СРС 13: в какой роли пользователь
EXEC sp_helpuser N'diskuser';
GO
EXECUTE AS USER = N'diskuser';
-- 1 - состоит в роли, 0 - нет
SELECT IS_MEMBER(N'public') AS in_public, IS_MEMBER(N'db_datareader') AS in_db_datareader;
-- читать таблицу нельзя
SELECT * FROM dbo.membership_types;
-- прямой вопрос серверу про право SELECT
SELECT HAS_PERMS_BY_NAME(N'dbo.membership_types', N'OBJECT', N'SELECT') AS can_select;
REVERT;
GO
```

Ответ на СРС 13. Новый пользователь состоит в одной роли - public (sp_helpuser, IS_MEMBER(N'public') = 1; в db_datareader не состоит - 0). Назначение public: роль по умолчанию, в неё автоматически попадает каждый пользователь базы; права, выданные public, получают все. Но по умолчанию у public есть только чтение системного каталога (метаданных), на пользовательские таблицы прав нет. Поэтому SELECT * FROM dbo.membership_types закончился отказом Msg 229, а HAS_PERMS_BY_NAME вернул 0. Роль diskadmin (серверная, блок 13) данных в базах не открывает - это другой уровень. Настоящее подключение даёт то же:

Результат:

```
Changed database context to 'FitnessCRM'.
UserName|RoleName|LoginName|DefDBName|DefSchemaName|UserID|SID
--------|--------|---------|---------|-------------|------|---
diskuser|public|lab5_disk|FitnessCRM|dbo|9         |0x954AB39F309AB743AB78968B62F2F2AA
in_public|in_db_datareader
---------|----------------
1|0

(1 rows affected)
Msg 229, Level 14, State 5, Server SERVER\SQLEXPRESS, Line 3
The SELECT permission was denied on the object 'membership_types', database 'FitnessCRM', schema 'dbo'.
can_select
----------
0

(1 rows affected)
```

```
sqlcmd -S .\SQLEXPRESS -U lab5_disk -P Lab5#Passw0rd -C -W -s "|" -Q "SELECT SUSER_NAME() AS login_name, USER_NAME() AS db_user, DB_NAME() AS current_db; SELECT TOP (1) * FROM dbo.membership_types;"
login_name|db_user|current_db
----------|-------|----------
lab5_disk|diskuser|FitnessCRM

(1 rows affected)
Msg 229, Level 14, State 5, Server SERVER\SQLEXPRESS, Line 1
The SELECT permission was denied on the object 'membership_types', database 'FitnessCRM', schema 'dbo'.
```

Блок 15. СРС 14: роль managers и итоговые права (строки 226-249 в .sql)

```sql
-- СРС 14: своя роль managers
USE FitnessCRM;
GO
-- создаём роль, даём ей одно право, кладём в неё пользователя
CREATE ROLE managers;
GRANT SELECT ON dbo.membership_types TO managers;
ALTER ROLE managers ADD MEMBER diskuser;
GO
EXECUTE AS USER = N'diskuser';
SELECT IS_MEMBER(N'managers') AS in_managers;
-- теперь читать можно
SELECT id, code, kind, months, base_price FROM dbo.membership_types ORDER BY id;
-- а другие таблицы - по-прежнему нет
SELECT TOP (1) * FROM dbo.clients;
REVERT;
GO
-- права пользователя на каждую таблицу: сначала запоминаем список таблиц (от имени администратора)
DECLARE @t TABLE (table_name sysname);
INSERT INTO @t SELECT name FROM sys.tables;
EXECUTE AS USER = N'diskuser';
-- по каждой таблице: можно ли читать, добавлять, менять, удалять
SELECT table_name,
       HAS_PERMS_BY_NAME(N'dbo.' + table_name, N'OBJECT', N'SELECT') AS can_select,
       HAS_PERMS_BY_NAME(N'dbo.' + table_name, N'OBJECT', N'INSERT') AS can_insert,
       HAS_PERMS_BY_NAME(N'dbo.' + table_name, N'OBJECT', N'UPDATE') AS can_update,
       HAS_PERMS_BY_NAME(N'dbo.' + table_name, N'OBJECT', N'DELETE') AS can_delete
FROM @t ORDER BY table_name;
-- какие таблицы пользователь вообще видит в каталоге
SELECT name AS visible_table FROM sys.tables ORDER BY name;
REVERT;
GO
```

Ответ на СРС 14. Роль создана (CREATE ROLE), ей выдано одно право (GRANT SELECT ON dbo.membership_types TO managers), пользователь diskuser положен в роль. Теперь SELECT из membership_types проходит (все 7 видов абонементов), SELECT из clients по-прежнему отклоняется. К каким ещё объектам есть доступ: ни к каким. Проверено по каждой из 6 таблиц FitnessCRM и по четырём действиям: единственная единица в таблице прав - SELECT на membership_types, всё остальное 0. Дополнительно сервер просто прячет от пользователя то, на что у него нет прав: sys.tables показывает ему одну таблицу membership_types. Кроме этого у всех пользователей есть то, что роль public даёт по умолчанию (чтение системного каталога и служебные системные объекты), к данным проекта это отношения не имеет. Других пользовательских объектов (представлений, процедур) в FitnessCRM сейчас нет: проверено запросом на чтение - только 6 таблиц и ограничения. Почему так: права складываются из ролей, в которых состоит пользователь (public + managers), а у public на данные ничего нет. Сверка с настоящим подключением ниже.

Строка «(6 rows affected)» перед таблицей прав - от INSERT в табличную переменную @t, это не результат запроса.

Результат:

```
Changed database context to 'FitnessCRM'.
in_managers
-----------
1

(1 rows affected)
id|code|kind|months|base_price
--|----|----|------|----------
1|BASE_1|BASE|1|15000.00
2|STD_3|STD|3|39000.00
3|STD_6|STD|6|72000.00
4|STD_12|STD|12|130000.00
5|UNLIM_1|UNLIM|1|25000.00
6|UNLIM_6|UNLIM|6|120000.00
7|UNLIM_12|UNLIM|12|210000.00

(7 rows affected)
Msg 229, Level 14, State 5, Server SERVER\SQLEXPRESS, Line 4
The SELECT permission was denied on the object 'clients', database 'FitnessCRM', schema 'dbo'.

(6 rows affected)
table_name|can_select|can_insert|can_update|can_delete
----------|----------|----------|----------|----------
branches|0|0|0|0
clients|0|0|0|0
membership_types|1|0|0|0
memberships|0|0|0|0
payments|0|0|0|0
staff|0|0|0|0

(6 rows affected)
visible_table
-------------
membership_types

(1 rows affected)
```

```
sqlcmd -S .\SQLEXPRESS -U lab5_disk -P Lab5#Passw0rd -C -W -s "|" -Q "SELECT TOP (2) id, code, base_price FROM dbo.membership_types ORDER BY id; SELECT TOP (1) id FROM dbo.clients;"
id|code|base_price
--|----|----------
1|BASE_1|15000.00
2|STD_3|39000.00

(2 rows affected)
Msg 229, Level 14, State 5, Server SERVER\SQLEXPRESS, Line 1
The SELECT permission was denied on the object 'clients', database 'FitnessCRM', schema 'dbo'.
```

Блок 16. Очистка (строки 251-272 в .sql)

```sql
-- Очистка: удаляем всё, что создала лаба (запускать последним)
USE FitnessCRM;
GO
-- сначала пользователи и роль в базе
DROP USER IF EXISTS Andy;
DROP USER IF EXISTS TestUser;
DROP USER IF EXISTS manager;
DROP USER IF EXISTS diskuser;
DROP ROLE IF EXISTS managers;
GO
-- потом временные базы
USE master;
GO
DROP DATABASE IF EXISTS lab5_scratch;
DROP DATABASE IF EXISTS lab5_dev_db;
GO
-- потом логины (у DROP LOGIN нет IF EXISTS, поэтому проверка вручную)
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'Andy') DROP LOGIN Andy;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'TestUser') DROP LOGIN TestUser;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'lab5_pwd') DROP LOGIN lab5_pwd;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'lab5_dev') DROP LOGIN lab5_dev;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'lab5_disk') DROP LOGIN lab5_disk;
GO
-- проверка: ничего не осталось (два пустых результата)
SELECT name FROM sys.server_principals WHERE name IN (N'TempUser', N'Andy', N'TestUser', N'lab5_sec', N'lab5_pwd', N'lab5_dev', N'lab5_disk');
SELECT name FROM sys.databases WHERE name IN (N'lab5_scratch', N'lab5_dev_db');
GO
```

Что делает блок. Порядок тот же: пользователи и роль, потом временные базы, потом логины (логин нельзя удалить, пока его кто-то использует, и неаккуратно оставлять пользователя без логина). DROP USER IF EXISTS и DROP DATABASE IF EXISTS не падают, если объекта уже нет; у DROP LOGIN такой формы нет (проверено, Msg 156), поэтому для логинов стоит IF EXISTS (SELECT ...). Логины lab5_sec и TempUser удалены раньше (блоки 6 и 4). База lab5_dev_db, созданная в блоке 8, удаляется здесь (логин lab5_dev её владелец, поэтому базы удаляются раньше логинов). Пользователь manager2 из lab5_scratch исчезает вместе с самой базой.

Результат:

```
Changed database context to 'FitnessCRM'.
Changed database context to 'master'.
name
----

(0 rows affected)
name
----

(0 rows affected)
```

Короткие ответы для отчёта

- СРС 1. Серверные роли: sysadmin, securityadmin, serveradmin, setupadmin, processadmin, diskadmin, dbcreator, bulkadmin (и десять служебных ##MS_...##). dbcreator: создавать, изменять, удалять и восстанавливать базы.
- СРС 2. У sa роль sysadmin (на этом сервере sa отключён).
- СРС 3. Логины создаёт и удаляет securityadmin (и sysadmin).
- СРС 4. Пароль меняется sp_password (@old, @new, @loginame) или ALTER LOGIN ... OLD_PASSWORD; смена доказывается PWDCOMPARE.
- СРС 5. Своему логину выдана роль dbcreator, создание и изменение баз проверено; новый логин под ним создать нельзя (Msg 15247), потому что право ALTER ANY LOGIN есть только у securityadmin и sysadmin.
- СРС 6-8. Пользователь manager создан на логине lab5_dev; db_datareader даёт только чтение (INSERT отклоняется); db_denydatareader запрещает чтение, и запрет сильнее разрешения.
- СРС 9. В одной базе один пользователь на логин (Msg 15063), всего - по одному в каждой базе.
- СРС 10-11. Логин с diskadmin создан (в SSMS окнами или командами выше); в роли только он; права роли - ALTER RESOURCES, DISK INIT и дисковые процедуры.
- СРС 12-13. Пользователь на этом логине состоит только в public; на таблицы прав нет, SELECT отклоняется.
- СРС 14. После роли managers пользователь может читать только membership_types, остальные таблицы закрыты.

Как применить в проекте

Связка с планом. В PLAN/06-subjects-map.md лаба 5 («безопасность») привязана так: логин и пользователь приложения - неделя 1 (уже сделано: логин fitnesscrm_app), роли и права - неделя 2 (блок «Контроль доступа» и «Автотесты доступа» в PLAN/02-roadmap.md). Что из лабы пригодится там:
1. Принцип наименьших прав вместо db_owner. Блок 2 показал, что fitnesscrm_app сейчас db_owner в FitnessCRM: приложению разрешено вообще всё, включая удаление таблиц и выдачу прав. Для недели 2 стоит завести для приложения свою роль и выдать ей только нужное. Проверено на копии базы: роль с GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo читает и пишет таблицы, видит метаданные (INFORMATION_SCHEMA.COLUMNS вернул 42 столбца), но CREATE TABLE отклоняется (Msg 262). Что именно разрешать (например, без DELETE и без прямой записи в payments - «деньги только через операции» из PLAN/04-database.md), решаешь ты по матрице доступа. Проверь, что spring.jpa.hibernate.ddl-auto=validate по-прежнему проходит: Hibernate читает именно метаданные таблиц.
2. Хэши паролей в staff. Роль db_datareader (как у manager в блоке 10) читает все столбцы, включая staff.password_hash: на копии из 8 строк хэш читался у всех 8 (значения я не выводил). Любому будущему логину «только чтение» (отчёты, маркетолог из матрицы доступа) закрывай столбец отдельно: DENY SELECT ON dbo.staff (password_hash) TO имя_роли. Проверено: после этого SELECT id, username, role FROM dbo.staff работает, а SELECT * и любой запрос с password_hash получают Msg 230.
3. Два уровня ролей, не путать. Восемь ролей FitLife (DIRECTOR, MANAGER, RECEPTION ...) - это роли приложения: они лежат в таблице staff и проверяются Spring Security. Роли из этой лабы - роли базы данных: они защищают сами данные от ошибок приложения и от посторонних подключений. Приложение ходит в базу под одним логином, поэтому «ресепшн видит только свой филиал» решается в приложении (@PreAuthorize и фильтр по филиалу), а роли БД решают «что приложению вообще разрешено».
4. Тесты прав для db/tests/. Блоки 11 и 15 - готовая заготовка: EXECUTE AS USER + HAS_PERMS_BY_NAME отвечают на вопрос «что видит и что не видит эта роль» в одном окне, без отдельного подключения и без паролей. Такой скрипт можно положить в db/tests/ (неделя 2: «Автотесты доступа ... плюс тестовый SQL-скрипт db/tests/»). Не забудь REVERT.
5. Код проекта и SQL проекта пишешь ты; здесь только решение лабы. Если берёшь идеи, переписывай под свои имена ролей.
Строка про эту лабу занесена в PLAN/07-journal.md.

Ловушки и находки

- Методичка 2008 против сервера 2025: sa отключён; 10 новых служебных серверных ролей; старые процедуры работают, но устарели.
- Пароли придумывай сам: сервер за тебя их не проверит. На этом компьютере SQL-логин с пустым паролем создался без единой ошибки (проверено на пробном логине, тут же удалён). Вероятная причина - слабая локальная политика паролей Windows, из которой SQL Server берёт требования (саму причину я не проверял). Для учебных логинов не страшно, для логина приложения в проекте - важно.
- Мелкие огрехи методички: пропущена кавычка в sp_addrolemember 'db_datareader, 'MyFirstUser'; Andy и TestUser «уже существуют»; текст задания 6 и его пример про разное (чтение таблицы и запись двух столбцов против чтения двух столбцов).
- sp_adduser создаёт ещё и одноимённую схему (DefSchemaName), CREATE USER - нет; sp_dropuser убирает и схему (проверено).
- Логин со стартовой базой, где у него нет пользователя, не может войти (Msg 4064); обходной путь - указать другую базу при подключении или создать пользователя.
- DENY сильнее GRANT, в том числе полученного через роль.
- Права встроенных серверных ролей не лежат в sys.server_permissions: смотри sp_srvrolepermission (справка) и sys.fn_my_permissions под самим логином (факт).
- Ошибка DDL под EXECUTE AS обрывает пакет и не даёт выполниться REVERT.
- Плавающий сбой сервера: в одном из моих полных прогонов (SQL Server 2025 RTM) на DROP DATABASE под EXECUTE AS LOGIN пришла фатальная ошибка 615 (Msg 21), и соединение закрылось; в 12 отдельных повторах той же последовательности и ещё в 36 повторах трёх её вариантов сбой не воспроизвёлся. Поэтому в блоке 8 база не удаляется из-под логина. Если соединение всё же оборвётся на каком-то блоке: переподключись и запусти блок 16, потом начни заново.
- DROP LOGIN не поддерживает IF EXISTS.

Что проверено

Источник теории. Лекции 6 «Database Security System», на которую ссылается методичка, в папке teacher-lectures нет (Lecture 5 оттуда - про функции SQL и к лабе не относится), поэтому теория здесь - общие знания о SQL Server, подтверждённые реальными запусками. Все запуски - на SQL Server 2025 Express (RTM, 17.0.1000.7) с включённым смешанным режимом аутентификации.
- Проверка шла не на живой FitnessCRM, а на её копии: копирующая резервная копия (COPY_ONLY) восстановлена под временным именем, в выводах выше имя копии заменено на FitnessCRM, а имя компьютера и учётной записи Windows - на SERVER и DOMAIN\admin. Копия и временная резервная копия удалены.
- Блоки 1-16 выполнены по очереди (каждый отдельным подключением), затем весь файл целиком одним запуском: вывод совпал построчно (пустые строки и случайные SID не сравнивались). Блок 16 оставляет сервер чистым: ни одного логина, пользователя, роли и временной базы из лабы. Повторный запуск после очистки даёт тот же результат.
- Файл целиком запускался подряд: по 3 раза в чистой версии и в версии с комментариями, без сбоев и с одинаковым результатом (после правки блока 8, см. «Ловушки»).
- Версия с комментариями из этого файла и чистый .sql-файл - одна и та же программа: после удаления комментариев и пробелов тексты совпадают, а версия с комментариями выполнена целиком с тем же выводом (отличаются только номера строк в сообщениях об ошибках: комментарии их сдвигают).
- Шаги «войти под созданной учётной записью» выполнены и через EXECUTE AS (в одном окне), и настоящим подключением по SQL-аутентификации через sqlcmd (вывод выше).
- Живая FitnessCRM и серверные логины и роли сверены с состоянием, снятым до начала проверки (состав логинов, ролей, членов ролей, прав, число строк в таблицах): без изменений.
- Не выполнено мной: окна SSMS (задание 7 и пункт 10 самостоятельной работы описаны, их команды выполнены как T-SQL) и скриншоты для отчёта: их делаешь ты, запуская блоки в SSMS.
