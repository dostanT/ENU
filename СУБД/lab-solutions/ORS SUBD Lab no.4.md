Microsoft SQL Server. Лабораторная 4. Хранимые процедуры

Суть лабы и как она проверена

Цель лабы - научиться создавать собственные хранимые процедуры, вызывать их и передавать им параметры, в том числе такой параметр, через который процедура возвращает результат (OUTPUT).

Сначала пример, потом определение. Представь кофейню. Можно каждый раз диктовать бариста весь рецепт: возьми эспрессо, добавь молока, взбей. А можно один раз записать рецепт в книгу под названием "капучино" и дальше просто заказывать "капучино", при необходимости уточняя ("большой", "без сахара"). Хранимая процедура - это именованный рецепт из команд T-SQL, сохранённый прямо в базе данных на сервере. CREATE PROCEDURE записывает рецепт в книгу, EXEC имя - заказывает его. Параметры - то, что меняется от заказа к заказу (в этой лабе: число, дата, строка). OUTPUT-параметр - пустая коробочка, которую отдаёшь процедуре вместе с заказом: процедура кладёт в неё ответ, а после вызова ты забираешь его из своей переменной.

Что и чем проверено (важно для доверия к коду ниже):

- Сам T-SQL НЕ выполнялся: в этом окружении (macOS) нет Microsoft SQL Server и базы AdventureWorks2008 (см. корневой CLAUDE.md и syllabus-toc.md).
- Синтаксис всех T-SQL-скриптов прогнан через статический разбор грамматикой T-SQL (пакет sqlfluff 4.3.0, диалект tsql, установлен в изолированное окружение): каждый скрипт и все они вместе разбираются без ошибок. Заведомо сломанные контрольные скрипты (незакрытая скобка, опечатка в WITH ENCRYPTION, оборванный CASE) тем же разбором отвергаются - значит, проверка что-то ловит. Это проверка синтаксиса, а не выполнения и не смысла запроса.
- Логика каждой процедуры проверена по-настоящему: те же шаги в том же порядке переписаны на PL/pgSQL (ближайший диалект из доступных здесь), загружены во временную базу PostgreSQL 18.3 и сверены с независимыми расчётами на Python (детали под каждым заданием). Временная база удалена сразу после проверки, существующие базы не тронуты.
- Всё, что специфично именно для MS SQL Server (HOST_NAME, sys.system_objects, sp_helptext, WITH ENCRYPTION, SET DATEFORMAT, поведение DATEADD и т. п.), описано по документации T-SQL и помечено "не проверено выполнением". Ожидаемые результаты вызовов ниже - это результат PostgreSQL-версии той же логики, а не вывод настоящего SQL Server.

Общие правила для всех скриптов ниже

- GO - не команда T-SQL, а разделитель пакетов (batch) для SSMS и sqlcmd: клиент отправляет серверу текст порциями, каждая порция заканчивается строкой GO.
- CREATE PROCEDURE должна быть первой командой в своём пакете, а всё, что идёт после AS до конца пакета, становится телом процедуры. Поэтому сразу после текста процедуры обязательно ставится GO: без него следующий за процедурой вызов EXEC стал бы ЧАСТЬЮ процедуры (получилась бы процедура, которая вызывает сама себя).
- Процедуры создаются в текущей базе (комментарий из задания), поэтому скрипт начинается с USE AdventureWorks2008 (на рис. 4.1 лаба выполняется именно в ней). Схема в CREATE PROCEDURE не указана - объект попадает в схему по умолчанию (dbo, как и на рисунке: dbo.Test, dbo.DigitCount).
- Перед каждым CREATE PROCEDURE стоит строка IF OBJECT_ID('dbo.Имя', 'P') IS NOT NULL DROP PROCEDURE dbo.Имя. Она нужна, чтобы скрипт можно было запускать повторно: без неё второй запуск падает с ошибкой "уже существует объект". 'P' - код типа "хранимая процедура".
- EXEC перед именем процедуры обязателен, если вызов не первая команда в пакете (комментарий из задания 2).
- В скриптах только ASCII и английские комментарии, чтобы не зависеть от кодировки файла.

Задание 1. Процедура Test: имя компьютера, укороченное, если длиннее девяти букв

Сначала пример. Компьютер называется LAPTOP-12345: в имени 12 символов, это больше девяти, значит выводим первые шесть символов и многоточие - LAPTOP... . Компьютер называется PC-01: имя короткое, выводим как есть - PC-01. Ровно девять букв - это НЕ "более девяти", такое имя выводится целиком.

Механизм (код дан в самом задании, здесь - объяснение, а не решение с нуля). HOST_NAME() возвращает имя компьютера, С КОТОРОГО подключились к серверу, то есть имя клиентской машины, а не самого сервера. Тип результата - nvarchar (строка Юникода), где на каждый символ уходит 2 байта; DATALENGTH возвращает длину в БАЙТАХ, поэтому её делят на 2, чтобы получить длину в буквах (та же деталь, что в lab-solutions/ORS SUBD Lab no.2.md, задание 3). Дальше обычный IF ... ELSE: BEGIN ... END в теле не нужен, потому что в каждой ветке по одной команде. SELECT (а не PRINT) означает, что результат придёт таблицей на вкладку Results.

```sql
USE AdventureWorks2008
GO

IF OBJECT_ID('dbo.Test', 'P') IS NOT NULL DROP PROCEDURE dbo.Test
GO

CREATE PROCEDURE Test AS
IF (DATALENGTH(HOST_NAME()) / 2 > 9)
    SELECT LEFT(HOST_NAME(), 6) + '...'
ELSE
    SELECT HOST_NAME()
GO

SELECT name, create_date FROM sys.procedures WHERE name = 'Test'
GO

EXEC Test
GO
```

Пункт 3 задания ("убедиться, что процедура создана", рис. 4.1) - это Object Explorer: Databases, AdventureWorks2008, Programmability, Stored Procedures (после создания нажать Refresh, F5) - в списке появится dbo.Test рядом с собственными процедурами AdventureWorks (их имена начинаются с usp). Запрос SELECT name, create_date FROM sys.procedures в скрипте выше делает то же самое текстом. Пункт 4 (вызов) в задании записан просто как TEST - так работает только тогда, когда вызов первый в пакете, поэтому в скрипте EXEC Test.

Не проверено выполнением: имя компьютера зависит от машины, с которой идёт подключение, поэтому какой именно текст появится на вкладке Results, покажет только реальный запуск.

Проверка логики на PostgreSQL (те же шаги, реально выполнено). В PostgreSQL нет прямого аналога HOST_NAME() (имени клиентской машины), поэтому имя передаётся параметром, а длина считается в символах (char_length) - это и есть "DATALENGTH / 2" для nvarchar.

```pgsql
CREATE FUNCTION test_host(host text) RETURNS text LANGUAGE plpgsql AS $$
BEGIN
  IF char_length(host) > 9 THEN
    RETURN left(host, 6) || '...';
  ELSE
    RETURN host;
  END IF;
END $$;
```

Сверены 21 имя (длины от 1 до 15, латиница и кириллица) с независимым правилом на Python - все совпали. Границу 9/10 проверка показывает явно:

```
'AAAAAAAAA'    (9 символов)  ->  'AAAAAAAAA'
'AAAAAAAAAA'   (10 символов) ->  'AAAAAA...'
'PC-01'        (5 символов)  ->  'PC-01'
'DOSTAN-MAC'   (10 символов) ->  'DOSTAN...'
'LAPTOP-12345' (12 символов) ->  'LAPTOP...'
'ДОСТАН-НОУТ'  (11 символов) ->  'ДОСТАН...'
```

Задание 2. Процедура DigitCount: число цифр в числе через OUTPUT-параметр

Сначала пример. Число 1249. Делим нацело на 10 и считаем деления: 1249 - 124 (одно деление), 124 - 12 (два), 12 - 1 (три), 1 - 0 (четыре). Число дошло до нуля за четыре деления - значит, в нём 4 цифры: каждое деление на 10 отбрасывает последнюю цифру. Для самого числа 0 цикл не выполнится ни разу, а цифра у нуля всё-таки одна - поэтому отдельная ветка IF (@num = 0) SET @cnt = 1 (то же рассуждение, что в lab-solutions/ORS SUBD Lab no.2.md, задание 4; там это был кусок скрипта, здесь он завёрнут в процедуру).

Про формулировку: в английском тексте задания сказано "takes a number as a divisor" (принимает число "как делитель") - это неточность перевода. По коду процедура принимает само число, у которого считаются цифры, и никакого деления "на это число" нет.

Механизм параметров. У процедуры два параметра: @num - обычный входной и @cnt OUTPUT - выходной. Входной параметр процедура получает как КОПИЮ: внутри она делит @num на 10 до нуля, но переменная @num в вызывающем коде остаётся 1249 (в PostgreSQL-версии это проверено: после вызова num по-прежнему 1249). OUTPUT-параметр работает в обратную сторону: когда процедура завершилась, итоговое значение @cnt копируется обратно в переменную вызывающего. Слово OUTPUT нужно и в объявлении процедуры, и в вызове (EXEC DigitCount @num, @cnt OUTPUT). Если забыть его в вызове, ошибки не будет, но @cnt не получит результат (у только что объявленной переменной останется NULL): процедура посчитала ответ в своей копии и вернуть его не смогла. EXEC перед именем обязателен, потому что вызов стоит не первым в пакете (комментарий из задания).

```sql
IF OBJECT_ID('dbo.DigitCount', 'P') IS NOT NULL DROP PROCEDURE dbo.DigitCount
GO

CREATE PROCEDURE DigitCount
    @num int,
    @cnt int OUTPUT
AS
IF (@num = 0) SET @cnt = 1
ELSE BEGIN
    SET @cnt = 0
    WHILE (@num <> 0) BEGIN
        SET @cnt = @cnt + 1
        SET @num = @num / 10
    END
END
GO

DECLARE @num int = 1249
DECLARE @cnt int
EXEC DigitCount @num, @cnt OUTPUT
SELECT @cnt AS [Number of digits]
GO
```

Ожидаемый результат последнего SELECT - одна строка, столбец Number of digits, значение 4 (результат PostgreSQL-версии той же логики, см. ниже). В T-SQL целочисленное деление отрицательного числа отбрасывает дробную часть в сторону нуля (-1249 / 10 даёт -124), поэтому цикл дойдёт до нуля и для отрицательных чисел (по документации T-SQL, не проверено выполнением; в PostgreSQL деление ведёт себя так же).

Проверка логики на PostgreSQL (те же шаги, реально выполнено). OUTPUT превращается в OUT-параметр процедуры.

```pgsql
CREATE PROCEDURE digit_count(num int, OUT cnt int) LANGUAGE plpgsql AS $$
BEGIN
  IF num = 0 THEN
    cnt := 1;
  ELSE
    cnt := 0;
    WHILE num <> 0 LOOP
      cnt := cnt + 1;
      num := num / 10;
    END LOOP;
  END IF;
END $$;
```

Результаты вызовов и проверок:

```
CALL digit_count(1249, NULL)   ->  cnt = 4
CALL digit_count(-1249, NULL)  ->  cnt = 4
CALL digit_count(0, NULL)      ->  cnt = 1
вызов из блока DO с переменной n = 1249:  cnt = 4, n после вызова = 1249 (копия не портит оригинал)
```

Процедура сверена на 400009 значениях (от -200000 до 200000 и крайние 2147483647, -2147483647, 1000000000, 999999999, 10, 9, 1, 0) с независимым способом счёта (длина числа, записанного текстом) - расхождений 0.

Самостоятельная работа

Подсказка "Design the solution to the following problems in the form of stored procedures" стоит сразу после пункта 1, поэтому пункт 1 сделан обычным запросом, пункты 2-4 - хранимыми процедурами, пункт 5 - удалением. Требование к отчёту - набор SQL-скриптов по этим пяти пунктам: каждый блок ниже - самостоятельный скрипт, их можно склеить подряд в один файл (между блоками стоит GO). Зависимости почти нет: пункт 4 в самом конце обращается к процедуре DigitCount из задания 2 (для контраста, см. ниже), а пункт 5 логично выполнять последним.

1. Определить количество системных хранимых процедур

Механизм. Системные процедуры - это встроенные процедуры сервера (sp_help, sp_helptext, sp_addlogin и т. д.). Начиная с SQL Server 2005 они физически лежат в скрытой служебной базе Resource, но видны в каждой базе через схему sys. Каталожное представление sys.system_objects перечисляет ВСЕ системные объекты, а условие type = 'P' оставляет только хранимые процедуры на T-SQL (расширенные процедуры xp_ имеют тип 'X' и сюда не попадают - в Object Explorer они лежат в отдельной папке). Функция COUNT считает подходящие строки. В Object Explorer эти процедуры видны в папке System Stored Procedures узла Programmability (она есть и на рис. 4.1).

```sql
SELECT COUNT(*) AS [System stored procedures]
FROM sys.system_objects
WHERE type = 'P'
GO
```

Равнозначная запись: sys.all_objects с условием type = 'P' AND is_ms_shipped = 1 (объекты, поставляемые вместе с сервером).

Не проверено выполнением: число зависит от версии и сборки сервера, поэтому в отчёт его можно вписать только со своего запуска. Для сравнения, как это выглядит в PostgreSQL (аналогия, а не ответ на задание; реально выполнено, PostgreSQL 18.3):

```
SELECT count(*) FILTER (WHERE prokind = 'f') AS functions,
       count(*) FILTER (WHERE prokind = 'p') AS procedures
FROM pg_proc
WHERE pronamespace = 'pg_catalog'::regnamespace;
-- результат: functions = 3226, procedures = 0
```

В схеме pg_catalog нашлось 3226 функций и 0 процедур: встроенные возможности PostgreSQL оформлены в основном функциями, а процедуры как отдельный вид появились в нём только с 11-й версии.

2. Определить время года для заданной даты

Сначала пример. Строка 05/06/2026 - это 5 июня, если читать её как день/месяц/год, или 6 мая, если читать как месяц/день/год. В первом случае лето, во втором весна: ОДНА И ТА ЖЕ строка даёт разные ответы. Именно поэтому в задании упомянут SET DATEFORMAT - он сообщает серверу, в каком порядке читать день, месяц и год во вводимой дате.

Механизм. Процедура GetSeason принимает дату типом date (он появился в SQL Server 2008, для которого написана лаба), берёт номер месяца функцией MONTH и по нему выбирает время года. Взяты метеорологические времена года по месяцам: зима - декабрь, январь, февраль; весна - март, апрель, май; лето - июнь, июль, август; осень - сентябрь, октябрь, ноябрь (названия как в задании: fall, winter, spring, summer); астрономические границы вроде 21 марта не используются. Результат возвращается через OUTPUT-параметр @season, как в задании 2.

Где действует SET DATEFORMAT. Это настройка СЕССИИ (текущего подключения): она действует до следующего SET DATEFORMAT или до конца подключения. Выполнять её нужно ДО вызова процедуры: текстовый литерал '05/06/2026' превращается в дату в момент вызова, ещё до входа в тело процедуры, и по правилу, действующему в этот момент. Поэтому в тесте формат задаётся перед каждым EXEC, а в конце возвращается mdy (типичное значение по умолчанию для английской локали).

```sql
IF OBJECT_ID('dbo.GetSeason', 'P') IS NOT NULL DROP PROCEDURE dbo.GetSeason
GO

CREATE PROCEDURE GetSeason
    @d date,
    @season varchar(10) OUTPUT
AS
BEGIN
    DECLARE @m int
    SET @m = MONTH(@d)
    SET @season = CASE
        WHEN @m IN (12, 1, 2) THEN 'winter'
        WHEN @m IN (3, 4, 5)  THEN 'spring'
        WHEN @m IN (6, 7, 8)  THEN 'summer'
        ELSE 'fall'
    END
END
GO

DECLARE @season varchar(10)

SET DATEFORMAT dmy
EXEC GetSeason '05/06/2026', @season OUTPUT
SELECT '05/06/2026 read as dmy' AS InputText, @season AS Season

SET DATEFORMAT mdy
EXEC GetSeason '05/06/2026', @season OUTPUT
SELECT '05/06/2026 read as mdy' AS InputText, @season AS Season

SET DATEFORMAT ymd
EXEC GetSeason '2026-12-15', @season OUTPUT
SELECT '2026-12-15 read as ymd' AS InputText, @season AS Season

SET DATEFORMAT mdy
GO
```

Ожидаемый результат (три отдельные таблицы по одной строке; значения получены на PostgreSQL-версии той же логики):

```
InputText                 Season
05/06/2026 read as dmy    summer
05/06/2026 read as mdy    spring
2026-12-15 read as ymd    winter
```

Не проверено выполнением: SET DATEFORMAT и неявное преобразование строки в date - по документации T-SQL. Осторожно, если заменить date на datetime (в SQL Server 2005 другого типа нет): для datetime строка вида 2026-12-15 зависит от DATEFORMAT (при dmy она будет прочитана как год-день-месяц и вызовет ошибку), безопасный формат для любых настроек - 20261215 без разделителей.

Проверка логики на PostgreSQL (те же шаги, реально выполнено):

```pgsql
CREATE FUNCTION get_season(d date) RETURNS text LANGUAGE plpgsql AS $$
DECLARE m int;
BEGIN
  m := EXTRACT(month FROM d);
  RETURN CASE
    WHEN m IN (12, 1, 2) THEN 'winter'
    WHEN m IN (3, 4, 5)  THEN 'spring'
    WHEN m IN (6, 7, 8)  THEN 'summer'
    ELSE 'fall'
  END;
END $$;
```

Функция сверена для КАЖДОГО дня с 2020-01-01 по 2027-12-31 (2922 даты) с таблицей "месяц - время года" на Python - расхождений 0. Аналог SET DATEFORMAT в PostgreSQL - SET datestyle; вот что получилось (та же строка, разный порядок чтения, разное время года):

```
SET datestyle = 'ISO, DMY':  05/06/2026 -> 2026-06-05 -> summer
SET datestyle = 'ISO, MDY':  05/06/2026 -> 2026-05-06 -> spring
SET datestyle = 'ISO, YMD':  2026-12-15 -> 2026-12-15 -> winter
```

Это аналогия поведения, а не доказательство работы именно SET DATEFORMAT в SQL Server.

3. Известна дата рождения: проверить, 16 лет ему или меньше

Сначала пример. Человек родился 24.09.2009. Семнадцати лет он достигнет 24.09.2026. Значит, 23.09.2026 ему ещё 16 - ответ "да, 16 или моложе"; а 24.09.2026 ему уже 17 - ответ "нет". Отсюда идея: "16 лет или моложе" - это то же самое, что "17-й день рождения ещё впереди", то есть дата рождения плюс 17 лет больше сегодняшней даты. В T-SQL: DATEADD(YEAR, 17, @birth) > @today.

Почему возраст не считается через DATEDIFF(YEAR, @birth, GETDATE()): DATEDIFF считает, сколько раз между двумя датами сменился НОМЕР ГОДА, а не сколько полных лет прошло: между 31.12.2009 и 01.01.2010 он вернёт 1, хотя прошёл один день. Чтобы получить точный возраст, пришлось бы вычитать единицу, если день рождения в этом году ещё не наступил (такая поправка делалась в lab-solutions/ORS SUBD Lab no.3.md, задача 2 самостоятельной работы). Сравнение с 17-м днём рождения обходится без неё, одной строкой.

Толкование условия: "16 years old or younger" понято буквально - возраст не больше 16 (до 17-го дня рождения). Если по замыслу нужно "младше 16", в коде меняется одно число: 17 на 16. Защита: дата рождения в будущем - ошибка ввода, процедура сообщает о ней через RAISERROR и выходит, не задав @isYoung (он остаётся NULL).

Тест собран из дат, отсчитанных от сегодняшнего дня, поэтому правильные ответы (1, 1, 1, 0, 0) не зависят от того, когда запускается скрипт.

```sql
IF OBJECT_ID('dbo.IsSixteenOrYounger', 'P') IS NOT NULL DROP PROCEDURE dbo.IsSixteenOrYounger
GO

CREATE PROCEDURE IsSixteenOrYounger
    @birth date,
    @isYoung bit OUTPUT
AS
BEGIN
    DECLARE @today date
    SET @today = CAST(GETDATE() AS date)

    IF @birth > @today
    BEGIN
        RAISERROR('The birth date is in the future.', 16, 1)
        RETURN
    END

    -- the 17th birthday is still ahead  <=>  the person is 16 years old or younger
    IF DATEADD(YEAR, 17, @birth) > @today
        SET @isYoung = 1
    ELSE
        SET @isYoung = 0
END
GO

DECLARE @today date, @b date, @r bit
SET @today = CAST(GETDATE() AS date)

SET @b = DATEADD(YEAR, -10, @today)
EXEC IsSixteenOrYounger @b, @r OUTPUT
PRINT CONVERT(varchar(10), @b, 120) + ' (10 years old)         -> ' + CAST(@r AS varchar(1))

SET @b = DATEADD(YEAR, -16, @today)
EXEC IsSixteenOrYounger @b, @r OUTPUT
PRINT CONVERT(varchar(10), @b, 120) + ' (turned 16 today)      -> ' + CAST(@r AS varchar(1))

SET @b = DATEADD(DAY, 1, DATEADD(YEAR, -17, @today))
EXEC IsSixteenOrYounger @b, @r OUTPUT
PRINT CONVERT(varchar(10), @b, 120) + ' (turns 17 tomorrow)    -> ' + CAST(@r AS varchar(1))

SET @b = DATEADD(YEAR, -17, @today)
EXEC IsSixteenOrYounger @b, @r OUTPUT
PRINT CONVERT(varchar(10), @b, 120) + ' (turned 17 today)      -> ' + CAST(@r AS varchar(1))

SET @b = DATEADD(YEAR, -30, @today)
EXEC IsSixteenOrYounger @b, @r OUTPUT
PRINT CONVERT(varchar(10), @b, 120) + ' (30 years old)         -> ' + CAST(@r AS varchar(1))
GO
```

Ожидаемый вывод на вкладке Messages при запуске 24.09.2026 (даты в начале строк зависят от дня запуска, ответы после стрелки - нет; значения получены на PostgreSQL-версии той же логики):

```
2016-09-24 (10 years old)         -> 1
2010-09-24 (turned 16 today)      -> 1
2009-09-25 (turns 17 tomorrow)    -> 1
2009-09-24 (turned 17 today)      -> 0
1996-09-24 (30 years old)         -> 0
```

Соглашение для родившихся 29 февраля: по документации T-SQL, если после сдвига года такого дня в месяце нет, DATEADD возвращает последний день месяца, то есть в невисокосные годы такой человек "отмечает" день рождения 28 февраля. В PostgreSQL то же самое: date '2004-02-29' + interval '17 years' даёт 2021-02-28 (проверено). Другое правило (например, 1 марта) даст отличие ровно на один день.

Не проверено выполнением: DATEADD и RAISERROR в SQL Server - по документации T-SQL.

Проверка логики на PostgreSQL (те же шаги, реально выполнено; параметр today нужен только для воспроизводимых тестов, в T-SQL он вычисляется внутри процедуры из GETDATE()):

```pgsql
CREATE FUNCTION is_sixteen_or_younger(birth date, today date DEFAULT current_date) RETURNS boolean LANGUAGE plpgsql AS $$
BEGIN
  IF birth > today THEN
    RAISE EXCEPTION 'The birth date is in the future.';
  END IF;
  RETURN (birth + interval '17 years')::date > today;
END $$;
```

Граничные случаи при "сегодня" = 2026-09-24:

```
родился 2016-09-24 (10 лет)                      ->  да
родился 2010-09-24 (16 лет исполнилось сегодня)  ->  да
родился 2009-09-25 (17 лет исполнится завтра)    ->  да
родился 2009-09-24 (17 лет исполнилось сегодня)  ->  нет
родился 2009-09-23 (17 лет исполнилось вчера)    ->  нет
родился 1996-09-24 (30 лет)                      ->  нет
родился 2026-09-24 (родился сегодня)             ->  да
родился 2026-09-25 (в будущем)                   ->  ошибка "The birth date is in the future."
```

Кроме того, сверено 100000 случайных пар (дата рождения, сегодня) с независимым расчётом возраста на Python (по правилу "день рождения в этом году уже был или ещё нет"; даты рождения 29 февраля исключены из этой сверки из-за соглашения выше) - расхождений 0.

4. Определить, является ли строка адресом электронной почты; скрыть исходный текст процедуры

Сначала пример. user@example.com - адрес: есть @, а после неё есть точка. user.example.com - не адрес: нет @. user@example - не адрес: после @ нет точки. user.name@example - тоже нет: точка есть, но стоит ДО @, а не после.

Правила, которые проверяет процедура (подсказка из задания плюс несколько минимальных проверок здравого смысла):

1. В строке нет пробелов.
2. Есть ровно одна @, и перед ней хотя бы один символ.
3. После @ есть хотя бы одна точка (правило из подсказки), причём точка не стоит сразу после @ и не является последним символом строки (иначе user@.com и user@example. считались бы адресами).

Если нужна ровно формулировка подсказки, оставьте только проверку "есть @ и после неё есть точка": остальные проверки лишь ужесточают правило.

Как читается код. CHARINDEX('@', @s) - позиция первой @ (0, если её нет); условие @at < 2 отсекает и отсутствие @, и @ в самом начале. CHARINDEX('@', @s, @at + 1) ищет вторую @ начиная со следующей позиции. SUBSTRING(@s, @at + 1, LEN(@s) - @at) - часть строки после @ (домен). CHARINDEX('.', @domain) > 1 - в домене есть точка и она не первый символ; RIGHT(@domain, 1) <> '.' - последний символ не точка. RETURN просто завершает процедуру досрочно; @isEmail заранее выставлен в 0, поэтому досрочный выход означает "не адрес".

Шифрование. WITH ENCRYPTION в заголовке процедуры (после списка параметров, перед AS) заставляет сервер хранить текст процедуры в зашифрованном (запутанном) виде: работает процедура по-прежнему, но прочитать её исходный текст стандартными средствами нельзя.

```sql
IF OBJECT_ID('dbo.IsEmail', 'P') IS NOT NULL DROP PROCEDURE dbo.IsEmail
GO

CREATE PROCEDURE IsEmail
    @s varchar(255),
    @isEmail bit OUTPUT
WITH ENCRYPTION
AS
BEGIN
    DECLARE @at int, @domain varchar(255)
    SET @isEmail = 0
    IF @s IS NULL RETURN
    IF CHARINDEX(' ', @s) > 0 RETURN
    SET @at = CHARINDEX('@', @s)
    IF @at < 2 RETURN
    IF CHARINDEX('@', @s, @at + 1) > 0 RETURN
    SET @domain = SUBSTRING(@s, @at + 1, LEN(@s) - @at)
    IF CHARINDEX('.', @domain) > 1 AND RIGHT(@domain, 1) <> '.'
        SET @isEmail = 1
END
GO

DECLARE @r bit

EXEC IsEmail 'user@example.com', @r OUTPUT
PRINT 'user@example.com  -> ' + CAST(@r AS varchar(1))

EXEC IsEmail 'a.b@mail.co.uk', @r OUTPUT
PRINT 'a.b@mail.co.uk    -> ' + CAST(@r AS varchar(1))

EXEC IsEmail 'user.example.com', @r OUTPUT
PRINT 'user.example.com  -> ' + CAST(@r AS varchar(1))

EXEC IsEmail 'user@example', @r OUTPUT
PRINT 'user@example      -> ' + CAST(@r AS varchar(1))

EXEC IsEmail 'user.name@example', @r OUTPUT
PRINT 'user.name@example -> ' + CAST(@r AS varchar(1))

EXEC IsEmail '@example.com', @r OUTPUT
PRINT '@example.com      -> ' + CAST(@r AS varchar(1))

EXEC IsEmail 'user@.com', @r OUTPUT
PRINT 'user@.com         -> ' + CAST(@r AS varchar(1))

EXEC IsEmail 'user@example.', @r OUTPUT
PRINT 'user@example.     -> ' + CAST(@r AS varchar(1))

EXEC IsEmail 'a@b@c.com', @r OUTPUT
PRINT 'a@b@c.com         -> ' + CAST(@r AS varchar(1))

EXEC IsEmail 'us er@example.com', @r OUTPUT
PRINT 'us er@example.com -> ' + CAST(@r AS varchar(1))
GO

EXEC sp_helptext 'IsEmail'
SELECT OBJECT_DEFINITION(OBJECT_ID('IsEmail')) AS SourceCode
SELECT [definition] FROM sys.sql_modules WHERE object_id = OBJECT_ID('IsEmail')
GO

EXEC sp_helptext 'DigitCount'
GO
```

"Prove that the steps are correct" понято как два доказательства: (а) процедура работает - таблица тестов; (б) исходный текст действительно скрыт - sp_helptext, OBJECT_DEFINITION и sys.sql_modules, и для контраста sp_helptext у обычной (незашифрованной) процедуры DigitCount показывает её текст.

Ожидаемый вывод тестов на вкладке Messages (получен на PostgreSQL-версии той же логики; 1 - адрес, 0 - не адрес):

```
user@example.com  -> 1
a.b@mail.co.uk    -> 1
user.example.com  -> 0
user@example      -> 0
user.name@example -> 0
@example.com      -> 0
user@.com         -> 0
user@example.     -> 0
a@b@c.com         -> 0
us er@example.com -> 0
```

Ожидаемый результат проверки скрытия (по документации SQL Server, не проверено выполнением):

- EXEC sp_helptext 'IsEmail' - вместо текста сообщение The text for object 'IsEmail' is encrypted.
- SELECT OBJECT_DEFINITION(OBJECT_ID('IsEmail')) - NULL.
- SELECT [definition] FROM sys.sql_modules WHERE object_id = OBJECT_ID('IsEmail') - NULL в столбце definition.
- EXEC sp_helptext 'DigitCount' - полный текст процедуры DigitCount (у неё шифрования нет).

Две оговорки про WITH ENCRYPTION (по документации). Первая: это скорее маскировка, чем настоящая защита: текст остаётся доступным привилегированным пользователям, которые могут читать системные таблицы через выделенное административное подключение (DAC) или напрямую файлы базы, а также тем, кто может подключить отладчик к процессу сервера. Вторая: получить свой же текст с сервера обычными способами нельзя, поэтому файл скрипта нужно сохранить - без него не получится ни изменить процедуру (ALTER требует полный текст), ни перенести её.

Проверка логики на PostgreSQL (те же шаги в том же порядке, реально выполнено; шифрования в PostgreSQL для функций нет, проверялась только логика проверки адреса):

```pgsql
CREATE FUNCTION is_email(s text) RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE at_pos int; dom text;
BEGIN
  IF s IS NULL THEN RETURN false; END IF;
  IF position(' ' in s) > 0 THEN RETURN false; END IF;
  at_pos := position('@' in s);
  IF at_pos < 2 THEN RETURN false; END IF;
  IF position('@' in substr(s, at_pos + 1)) > 0 THEN RETURN false; END IF;
  dom := substr(s, at_pos + 1);
  RETURN position('.' in dom) > 1 AND right(dom, 1) <> '.';
END $$;
```

Сверка: перебраны ВСЕ строки длиной от 0 до 7 символов из алфавита "a", "@", ".", пробел (21845 строк) и сравнены с независимой моделью тех же правил на Python (регулярное выражение) - расхождений 0 (адресами признаны 46 строк). Пустая или NULL-строка адресом не признаётся. Выбранные для теста строки дали в точности таблицу выше.

5. Удалить все созданные процедуры

Сначала список того, что создано: Test и DigitCount (задания 1 и 2), GetSeason, IsSixteenOrYounger и IsEmail (пункты 2-4). Пункт 1 - запрос, он ничего не создаёт.

Механизм. DROP PROCEDURE имя удаляет процедуру; условие IF OBJECT_ID(...) IS NOT NULL защищает от ошибки, если процедуры уже нет. Удаляются именно свои процедуры, по именам: в AdventureWorks2008 есть и собственные процедуры (их имена начинаются с usp, они видны на рис. 4.1) - они не наши, и удалять "всё, что лежит в Programmability - Stored Procedures", нельзя.

```sql
IF OBJECT_ID('dbo.Test', 'P') IS NOT NULL DROP PROCEDURE dbo.Test
IF OBJECT_ID('dbo.DigitCount', 'P') IS NOT NULL DROP PROCEDURE dbo.DigitCount
IF OBJECT_ID('dbo.GetSeason', 'P') IS NOT NULL DROP PROCEDURE dbo.GetSeason
IF OBJECT_ID('dbo.IsSixteenOrYounger', 'P') IS NOT NULL DROP PROCEDURE dbo.IsSixteenOrYounger
IF OBJECT_ID('dbo.IsEmail', 'P') IS NOT NULL DROP PROCEDURE dbo.IsEmail
GO

SELECT name FROM sys.procedures
WHERE name IN ('Test', 'DigitCount', 'GetSeason', 'IsSixteenOrYounger', 'IsEmail')
GO
```

Ожидаемый результат: последний SELECT возвращает пустой набор (ни одной строки) - значит, ни одной из наших процедур не осталось. После удаления вызов EXEC Test завершится ошибкой "Could not find stored procedure 'Test'" (по документации, не проверено выполнением). Логично выполнять этот скрипт последним - после того как результаты остальных пунктов получены и записаны в отчёт.

Частые ошибки (сводка)

- Нет GO после CREATE PROCEDURE: следующий вызов EXEC становится частью тела процедуры. И наоборот, CREATE PROCEDURE не в начале пакета (например, сразу после другой команды без GO) - ошибка синтаксиса.
- Забыли OUTPUT в вызове: процедура отработает без ошибок, но результат не попадёт в переменную вызывающего.
- Считают возраст через DATEDIFF(YEAR, ...): она считает смены номера года, а не полные годы (31.12 - 01.01 даёт 1 год).
- SET DATEFORMAT выполнен после вызова или не выполнен вовсе: строка вида 05/06/2026 будет прочитана по настройке сессии, а не так, как задумано.
- Путают HOST_NAME() с именем сервера: функция возвращает имя КЛИЕНТСКОЙ машины, с которой пришёл запрос.
- Воспринимают WITH ENCRYPTION как надёжную защиту и теряют исходный скрипт: защиты нет, а текст с сервера уже не достать.
- Удаляют "все процедуры" в базе вместо своих: вместе с нашими пропадут и собственные процедуры AdventureWorks (usp...).
- Пишут DECLARE @x int = 5 на SQL Server 2005: такая запись (инициализация при объявлении) появилась только в 2008; в задании она используется, лаба рассчитана на 2008.

Источник

Задание - labs/ORS SUBD Lab no.4.docx ("Microsoft SQL Server. Lab #4. Stored Procedures"; тот же текст есть в силлабусе, PDF стр. 37). Материалов преподавателя по хранимым процедурам в папке пока нет (на лекцию 5 "Auxiliary Database Objects", которую называет сама лаба, в teacher-lectures ничего не положено), поэтому T-SQL-часть построена на коде из задания и на общих знаниях и документации T-SQL - не привязана к материалам курса.

Итог проверки. Реально выполнено: статический разбор синтаксиса всех T-SQL-скриптов; логика заданий 1-2 и пунктов 2-4 самостоятельной работы на PostgreSQL-версиях (21 имя; 400009 чисел; 2922 даты; граничные случаи и 100000 случайных пар для возраста; 21845 строк для проверки адреса) со сверкой на независимых расчётах на Python. Не проверено выполнением (нужен настоящий SQL Server): результат HOST_NAME(); число системных процедур в пункте 1; работа SET DATEFORMAT с явной строкой-литералом; тексты сообщений sp_helptext, OBJECT_DEFINITION и sys.sql_modules для зашифрованной процедуры; поведение DATEADD для 29 февраля; сообщение об удалённой процедуре.
