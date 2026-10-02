Справочник. Глава 15. Работа с анонимными каналами в Windows

Логика

- Анонимный канал - объект ядра БЕЗ имени, только между процессами ОДНОГО компьютера. Характеристики: без имени; полудуплексный; передача потоком байтов; синхронный обмен; любая топология связей.
- Сервер = тот, кто создал канал (CreatePipe). Клиенты = дочерние процессы, унаследовавшие дескриптор. Сервер/клиент НЕ значит "пишет/читает": данные могут идти в любую сторону.
- Порядок: создать (сервер) -> соединить клиентов (передать дескриптор) -> обмен (WriteFile/ReadFile) -> закрыть (CloseHandle).
- Направление задаёт дескриптор: hReadPipe только в ReadFile, hWritePipe только в WriteFile. Процесс с обоими дескрипторами может и писать, и читать.
- Канал ОДИН, очередь ОДНА. Если сервер и клиент оба пишут и читают в один канал - нужна синхронизация (событие/протокол очерёдности), иначе процесс прочитает свои же данные или программа зависнет.
- Как передать клиенту дескриптор - три условия сразу:
  - дескриптор наследуемый: поле bInheritHandle = TRUE в SECURITY_ATTRIBUTES, на которую указывает lpPipeAttributes; либо наследуемый дубликат (DuplicateHandle - Windows 98; SetHandleInformation - Windows 2000)
  - CreateProcess вызван в процессе-сервере с bInheritHandles = TRUE
  - значение дескриптора передано явно
- Способы явной передачи: командная строка; поля hStdInput/hStdOutput/hStdError структуры STARTUPINFO; сообщение WM_COPYDATA; файл. В главе - первые два.
- Клиенту нужен один дескриптор: либо создать оба наследуемыми и ненужный сделать ненаследуемым, либо создать оба ненаследуемыми и нужный сделать наследуемым.
- Перенаправление стандартного ввода-вывода: в STARTUPINFO dwFlags = STARTF_USESTDHANDLES; hStdInput = дескриптор чтения; hStdOutput и hStdError = дескриптор записи; CreateProcess(..., bInheritHandles = TRUE, ...). Тогда stdin/stdout/stderr и cin/cout клиента работают через канал.
- Три семейства консольного ввода-вывода: stdio.h (stdin, stdout, stderr - C), iostream.h (потоки C++, cin/cout), conio.h (_cputs, _cprintf, _getch - ВСЕГДА консоль, даже при перенаправлении).
- Формат данных: cout << i передаёт ТЕКСТ, WriteFile(&i, sizeof(i)) - 4 байта. Читать тем же способом.
- Windows NT: анонимный канал реализован как именованный канал с уникальным именем (функции главы 16 работают и с ним).
- Ненужные копии дескрипторов закрывать сразу (после CreateProcess), все дескрипторы - CloseHandle.

Функции

CreatePipe
BOOL CreatePipe(PHANDLE hReadHandle, PHANDLE hWriteHandle, LPSECURITY_ATTRIBUTES lpPipeAttributes, DWORD dwSize);
- hReadHandle - выходной: сюда дескриптор для ЧТЕНИЯ из канала
- hWriteHandle - выходной: сюда дескриптор для ЗАПИСИ в канал
- lpPipeAttributes - атрибуты защиты; NULL - дескрипторы НЕнаследуемые; структура с bInheritHandle = TRUE - наследуемые
- dwSize - размер буфера в байтах; только пожелание, 0 = размер по умолчанию
Возврат: не 0 / FALSE.
Ловушка: в тексте книги те же параметры называются hReadPipe/hWritePipe - это разнобой книги.

WriteFile
BOOL WriteFile(HANDLE hAnonymousPipe, LPCVOID lpBuffer, DWORD dwNumberOfBytesToWrite, LPDWORD lpNumberOfBytesWritten, LPOVERLAPPED lpOverlapped);
- hAnonymousPipe - дескриптор ЗАПИСИ канала
- lpBuffer - откуда брать байты
- dwNumberOfBytesToWrite - сколько байтов записать
- lpNumberOfBytesWritten - выходной: сколько записано реально
- lpOverlapped - асинхронный ввод; для анонимного канала всегда NULL (только синхронная передача)
Возврат: не 0 / FALSE.

ReadFile
BOOL ReadFile(HANDLE hAnonymousPipe, LPCVOID lpBuffer, DWORD dwNumberOfBytesToRead, LPDWORD lpNumberOfBytesRead, LPOVERLAPPED lpOverlapped);
- hAnonymousPipe - дескриптор ЧТЕНИЯ канала
- lpBuffer - выходной: куда положить прочитанное
- dwNumberOfBytesToRead - сколько байтов прочитать
- lpNumberOfBytesRead - выходной: сколько прочитано реально
- lpOverlapped - для анонимного канала всегда NULL
Возврат: не 0 / FALSE. Данных в канале нет - ждёт (обмен синхронный).
Ловушки: в прототипе книги lpBuffer типа LPCVOID (по смыслу LPVOID, буфер выходной), комментарии к двум параметрам скопированы с WriteFile.

Функции из других глав, которые здесь нужны
- DuplicateHandle(GetCurrentProcess(), hWritePipe, GetCurrentProcess(), &hInheritWritePipe, 0, TRUE, DUPLICATE_SAME_ACCESS): наследуемый дубликат; параметр прав игнорируется из-за DUPLICATE_SAME_ACCESS; исходный дескриптор потом закрыть (прототип - reference/04)
- CreateProcess с bInheritHandles = TRUE (прототип - reference/04)
- CreateEvent/OpenEvent/SetEvent/WaitForSingleObject - синхронизация очерёдности (reference/06)
- CloseHandle - reference/01

Шаблоны

Клиенту отдаём только дескриптор записи (листинг 15.2):
CreatePipe(&hReadPipe, &hWritePipe, NULL, 0);
DuplicateHandle(GetCurrentProcess(), hWritePipe, GetCurrentProcess(), &hInheritWritePipe, 0, TRUE, DUPLICATE_SAME_ACCESS);
CloseHandle(hWritePipe);
wsprintf(lpszComLine, "C:\\Client.exe %d", (int)hInheritWritePipe);
CreateProcess(NULL, lpszComLine, NULL, NULL, TRUE, CREATE_NEW_CONSOLE, NULL, NULL, &si, &pi);
CloseHandle(hInheritWritePipe);
у клиента: hWritePipe = (HANDLE)atoi(argv[1]);

Оба дескриптора наследуемые сразу (листинг 15.4):
sa.nLength = sizeof(SECURITY_ATTRIBUTES); sa.lpSecurityDescriptor = NULL; sa.bInheritHandle = TRUE;
CreatePipe(&hReadPipe, &hWritePipe, &sa, 0);
wsprintf(lpszComLine, "C:\\Client.exe %d %d", (int)hWritePipe, (int)hReadPipe);
у клиента: argv[1] - запись, argv[2] - чтение

Перенаправление стандартного ввода-вывода (листинг 15.7):
si.dwFlags = STARTF_USESTDHANDLES;
si.hStdInput = hReadPipe; si.hStdOutput = hWritePipe; si.hStdError = hWritePipe;
CreateProcess(..., TRUE, ...);
