Справочник. Глава 10. Работа с консолью

Логика

- Процесс связан ровно с ОДНОЙ консолью.
- Два способа получить новую консоль: 1) CreateProcess с флагом CREATE_NEW_CONSOLE (без этого флага консольный потомок консольного родителя делит консоль родителя); 2) AllocConsole - для процесса без консоли (создан с DETACHED_PROCESS) - процесс сам себе выделяет.
- Параметры консоли (заголовок, положение, размеры, цвета) - поля STARTUPINFO, но поле учитывается ТОЛЬКО при поднятом соответствующем флаге в dwFlags:
  - lpTitle - заголовок окна консоли (флаг не нужен)
  - dwX, dwY - положение левого угла окна (STARTF_USEPOSITION)
  - dwXSize, dwYSize - размеры окна (STARTF_USESIZE)
  - dwXCountChars, dwYCountChars - размеры буфера экрана (STARTF_USECOUNTCHARS)
  - dwFillAttribute - цвет фона/текста (STARTF_USEFILLATTRIBUTE)
  - wShowWindow - способ показа окна (STARTF_USESHOWWINDOW), например SW_SHOWNORMAL
- Windows 98: реально применяется только lpTitle, остальное по умолчанию.
- DETACHED_PROCESS + STARTUPINFO: параметры применятся только когда потомок сам вызовет AllocConsole.
- При создании консоли система создаёт три стандартных дескриптора: STDIN (связан с входным буфером), STDOUT и STDERR (оба с буфером экрана). Различие STDOUT/STDERR - по роду сообщений и независимому перенаправлению, физически пишут на тот же экран.
- Перенаправление: SetStdHandle + дескрипторы через CreateFile с зарезервированными именами CONIN$ / CONOUT$.
- Перенаправление в анонимный канал при запуске потомка (поля hStdInput/hStdOutput/hStdError + STARTF_USESTDHANDLES) - раздел 15.6 (в главе 10 книга ошибочно отсылает к "гл. 13").
- После FreeConsole процесс без консоли; ранее полученные дескрипторы не становятся недействительными автоматически, но вывод через них больше никуда не попадёт.

Функции

AllocConsole
BOOL AllocConsole(VOID);
Выделяет вызывающему процессу консоль. Возврат: не 0 - успех, FALSE - ошибка.

FreeConsole
BOOL FreeConsole(VOID);
Освобождает консоль. Возврат: не 0 / FALSE.

GetStdHandle
HANDLE GetStdHandle(DWORD dwStdHandle);
- dwStdHandle - STD_INPUT_HANDLE, STD_OUTPUT_HANDLE или STD_ERROR_HANDLE
Возврат: дескриптор; при ошибке INVALID_HANDLE_VALUE.

SetStdHandle
BOOL SetStdHandle(DWORD dwStdHandle, HANDLE hHandle);
- dwStdHandle - какой стандартный дескриптор заменить (те же значения)
- hHandle - новое значение
Возврат: не 0 / FALSE. Обычно для перенаправления ввода-вывода.

CreateFile для консоли
- имя "CONIN$": dwDesiredAccess = GENERIC_READ, dwShareMode = FILE_SHARE_READ (если консоль наследуется), dwCreationDisposition = OPEN_EXISTING
- имя "CONOUT$": dwDesiredAccess = GENERIC_WRITE, dwShareMode = FILE_SHARE_WRITE (если наследуется), OPEN_EXISTING
- dwFlagsAndAttributes и hTemplateFile игнорируются; lpSecurityAttributes - только чтобы сделать консоль наследуемой

Шаблон: родитель с настроенной консолью
STARTUPINFO si; ZeroMemory(&si, sizeof(STARTUPINFO)); si.cb = sizeof(STARTUPINFO);
si.lpTitle = "..."; si.dwX = 200; si.dwY = 200; si.dwXSize = 300; si.dwYSize = 200; si.dwXCountChars = 100; si.dwYCountChars = 100;
si.dwFillAttribute = FOREGROUND_RED | FOREGROUND_INTENSITY | BACKGROUND_INTENSITY | BACKGROUND_BLUE;
si.dwFlags = STARTF_USECOUNTCHARS | STARTF_USEFILLATTRIBUTE | STARTF_USEPOSITION | STARTF_USESHOWWINDOW | STARTF_USESIZE; si.wShowWindow = SW_SHOWNORMAL;
CreateProcess(name, NULL, NULL, NULL, FALSE, CREATE_NEW_CONSOLE, NULL, NULL, &si, &pi);
Замечание: в описании полей книга пишет dwFillAttributes (с s), а в коде примеров - si.dwFillAttribute (без s); в коде используй без s.
