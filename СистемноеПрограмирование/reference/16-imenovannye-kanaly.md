Справочник. Глава 16. Работа с именованными каналами в Windows

Логика

- Именованный канал - объект ядра С ИМЕНЕМ, между процессами на компьютерах одной локальной сети. Характеристики: имя; полудуплексный или дуплексный; поток или сообщения; синхронный или асинхронный; любая топология.
- Порядок работы: сервер CreateNamedPipe -> сервер ConnectNamedPipe -> клиент WaitNamedPipe + CreateFile -> ReadFile/WriteFile -> сервер DisconnectNamedPipe -> CloseHandle у обоих.
- Имя. Сервер: \\.\pipe\pipe_name ("." - локальная машина, канал создаётся всегда локально). Клиент: \\server_name\pipe\pipe_name. Имя нечувствительно к регистру. В коде C косые удваиваются: "\\\\.\\pipe\\demo_pipe".
- Режим сообщений на клиенте: клиент на той же машине с именем \\.\pipe\... открывает канал ПОТОКОМ; чтобы открыть сообщениями, нужно \\server_name\pipe\... (для TransactNamedPipe/CallNamedPipe обязательно полное имя компьютера, не точка).
- Экземпляры: имя одно, экземпляров от 1 до PIPE_UNLIMITED_INSTANCES (nMaxInstances). Один экземпляр - один клиент. Несколько клиентов - несколько вызовов CreateNamedPipe с одним именем (нужно право FILE_CREATE_PIPE_INSTANCE, по умолчанию оно есть у владельца канала).
- dwOpenMode - направление (только ОДИН из трёх): PIPE_ACCESS_DUPLEX (чтение и запись), PIPE_ACCESS_INBOUND (клиент пишет, сервер читает), PIPE_ACCESS_OUTBOUND (сервер пишет, клиент читает). Дают права: DUPLEX - GENERIC_READ+GENERIC_WRITE+SYNCHRONIZE; INBOUND - GENERIC_READ+SYNCHRONIZE; OUTBOUND - GENERIC_WRITE+SYNCHRONIZE. Плюс FILE_FLAG_WRITE_THROUGH (без буферизации по сети), FILE_FLAG_OVERLAPPED (асинхронная передача).
- dwPipeMode: PIPE_TYPE_BYTE / PIPE_TYPE_MESSAGE (как ПИШЕТСЯ), PIPE_READMODE_BYTE / PIPE_READMODE_MESSAGE (как ЧИТАЕТСЯ), PIPE_WAIT (синхронно) / PIPE_NOWAIT (асинхронно, по книге). По умолчанию - поток.
- Должны СОВПАДАТЬ у всех экземпляров: направление, способ чтения и записи. Могут ОТЛИЧАТЬСЯ: FILE_FLAG_WRITE_THROUGH, FILE_FLAG_OVERLAPPED, PIPE_WAIT/PIPE_NOWAIT.
- Клиентский доступ в CreateFile должен соответствовать dwOpenMode сервера, иначе CreateFile завершается неудачей (INBOUND-канал клиент открывает на GENERIC_WRITE).
- Защита: по умолчанию канал принадлежит создавшему пользователю. Между компьютерами - одинаковые логины/пароли, либо открытая защита (SECURITY_ATTRIBUTES + дескриптор безопасности с DACL NULL, листинг 16.5).
- WaitNamedPipe: если экземпляров с таким именем нет - сразу неудача, независимо от таймаута. Вызывать только после того, как сервер связался с каналом ConnectNamedPipe.
- Успех WaitNamedPipe не гарантирует успех CreateFile (сервер закрыл канал или экземпляр занял другой клиент). Защита: сервер создаёт НОВЫЙ экземпляр после каждого успешного ConnectNamedPipe или сразу несколько. Если известно, что сервер уже вызвал ConnectNamedPipe, CreateFile можно без WaitNamedPipe.
- ConnectNamedPipe блокирует сервер, если клиента нет -> вызывать в отдельном потоке (разбудить можно клиентским вызовом из другого потока того же приложения).
- DisconnectNamedPipe: любая операция клиента с каналом после этого - ошибка; сервер снова может вызвать ConnectNamedPipe для другого клиента.
- Асинхронный обмен: FILE_FLAG_OVERLAPPED в dwOpenMode + lpOverlapped в ReadFile/WriteFile; также ReadFileEx/WriteFileEx (гл. 24). За один WriteFile - не больше 65 535 байтов.
- PeekNamedPipe копирует, НЕ удаляя, и НЕ ждёт (на пустом канале нули в счётчиках). ReadFile удаляет и ждёт.
- TransactNamedPipe = WriteFile + ReadFile одной операцией, только если сервер создал канал с PIPE_TYPE_MESSAGE, дескриптор уже открыт. CallNamedPipe = связь + запись + чтение + разрыв одним вызовом, канал открыт в режиме сообщений.
- Get/SetNamedPipeHandleState - ИЗМЕНЯЕМЫЕ характеристики (Get: дескриптор открыт на чтение; Set: на запись). GetNamedPipeInfo - НЕИЗМЕНЯЕМЫЕ (дескриптор открыт на чтение).

Функции

CreateNamedPipe
HANDLE CreateNamedPipe(LPCTSTR lpName, DWORD dwOpenMode, DWORD dwPipeMode, DWORD nMaxInstances, DWORD nOutBufferSize, DWORD nInBufferSize, DWORD nDefaultTimeOut, LPSECURITY_ATTRIBUTES lpPipeAttributes);
- lpName - имя канала "\\.\pipe\pipe_name"
- dwOpenMode - направление PIPE_ACCESS_* | FILE_FLAG_WRITE_THROUGH | FILE_FLAG_OVERLAPPED
- dwPipeMode - PIPE_TYPE_*, PIPE_READMODE_*, PIPE_WAIT/PIPE_NOWAIT
- nMaxInstances - максимум экземпляров, 1..PIPE_UNLIMITED_INSTANCES
- nOutBufferSize, nInBufferSize - размеры выходного/входного буфера; только пожелание, 0 = по умолчанию
- nDefaultTimeOut - таймаут ожидания клиентом связи; используется в WaitNamedPipe при NMPWAIT_USE_DEFAULT_WAIT
- lpPipeAttributes - защита; NULL = по умолчанию
Возврат: дескриптор экземпляра; при неудаче INVALID_HANDLE_VALUE (книга называет ещё ERROR_INVALID_PARAMETR - nMaxInstances больше PIPE_UNLIMITED_INSTANCES; в реальном API это код из GetLastError).

ConnectNamedPipe
BOOL ConnectNamedPipe(HANDLE hNamedPipe, LPOVERLAPPED lpOverlapped);
- hNamedPipe - дескриптор экземпляра
- lpOverlapped - асинхронная связь; NULL = синхронная (сервер ждёт клиента)
Возврат: не 0 / FALSE. Вызывать для каждого свободного экземпляра.

DisconnectNamedPipe
BOOL DisconnectNamedPipe(HANDLE hNamedPipe);
- hNamedPipe - дескриптор экземпляра
Возврат: не 0 / FALSE. Разрывает связь сервера с клиентом.

WaitNamedPipe
BOOL WaitNamedPipe(LPCTSTR lpNamedPipeName, DWORD nTimeOut);
- lpNamedPipeName - "\\server_name\pipe\pipe_name" (server_name - компьютер сервера)
- nTimeOut - миллисекунды или NMPWAIT_USE_DEFAULT_WAIT (значение nDefaultTimeOut сервера) или NMPWAIT_WAIT_FOREVER
Возврат: не 0 / FALSE.
Ловушки: нет ни одного экземпляра - сразу FALSE; книга приписывает ей ERROR_PIPE_CONNECTED, если клиент подключился раньше ConnectNamedPipe (в реальном API этот код у ConnectNamedPipe).

CreateFile (для клиента канала)
HANDLE CreateFile(LPCTSTR lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile);
- lpFileName - имя канала, формат как в WaitNamedPipe
- dwDesiredAccess - 0 (получить атрибуты) / GENERIC_READ / GENERIC_WRITE; в листингах глав 16 - GENERIC_READ | GENERIC_WRITE; должен соответствовать dwOpenMode сервера
- dwShareMode - 0 (не делить) или FILE_SHARE_READ | FILE_SHARE_WRITE
- lpSecurityAttributes - NULL
- dwCreationDisposition - ВСЕГДА OPEN_EXISTING
- dwFlagsAndAttributes - 0 (или FILE_ATTRIBUTE_NORMAL); подробно - глава 24
- hTemplateFile - NULL
Возврат: дескриптор канала; INVALID_HANDLE_VALUE при неудаче.

ReadFile / WriteFile для канала - прототипы и параметры в reference/15. Отличие: lpOverlapped может быть не NULL, если задан FILE_FLAG_OVERLAPPED.

PeekNamedPipe
BOOL PeekNamedPipe(HANDLE hNamedPipe, LPVOID lpBuffer, DWORD nBufferSize, LPDWORD lpBytesRead, LPDWORD lpTotalBytesAvail, LPDWORD lpBytesLeftThisMessage);
- hNamedPipe - дескриптор, открытый на чтение
- lpBuffer - куда скопировать данные; NULL = данные не читать
- nBufferSize - размер lpBuffer
- lpBytesRead - выходной DWORD: сколько скопировано (NULL, если не читаем)
- lpTotalBytesAvail - выходной DWORD: сколько байтов сейчас в канале (NULL, если не читаем)
- lpBytesLeftThisMessage - выходной DWORD: сколько байтов текущего сообщения не прочитано (NULL, если не читаем)
Поток: копируется ровно длина буфера. Сообщения: копируется целое сообщение, если влезает, иначе часть, остаток - в lpBytesLeftThisMessage.
Возврат: не 0 / FALSE. Пустой канал - не ждёт, нули.

TransactNamedPipe
BOOL TransactNamedPipe(HANDLE hNamedPipe, LPVOID lpInBuffer, DWORD dwInBufferSize, LPVOID lpOutBuffer, DWORD dwOutBufferSize, LPDWORD lpBytesRead, LPOVERLAPPED lpOverlapped);
- hNamedPipe - уже открытый дескриптор
- lpInBuffer, dwInBufferSize - что записать и длина в байтах
- lpOutBuffer, dwOutBufferSize - куда читать ответ и длина буфера
- lpBytesRead - выходной DWORD (при асинхронном доступе можно NULL)
- lpOverlapped - NULL = синхронно (асинхронно - гл. 27)
Возврат: не 0 / FALSE. Только при PIPE_TYPE_MESSAGE у сервера; клиент с полным именем компьютера, а не ".".

CallNamedPipe
BOOL CallNamedPipe(LPCTSTR lpNamedPipeName, LPVOID lpInBuffer, DWORD dwInBufferSize, LPVOID lpOutBuffer, DWORD dwOutBufferSize, LPDWORD lpBytesRead, DWORD dwTimeOut);
- lpNamedPipeName - имя канала
- lpInBuffer, dwInBufferSize - запись
- lpOutBuffer, dwOutBufferSize - чтение
- lpBytesRead - выходной DWORD: сколько прочитано
- dwTimeOut - миллисекунды ждать связи, или NMPWAIT_NOWAIT (нет свободного экземпляра - сразу вернуться), NMPWAIT_WAIT_FOREVER, NMPWAIT_USE_DEFAULT_WAIT
Возврат: не 0 / FALSE. Связь + запись + чтение + разрыв.

GetNamedPipeHandleState
BOOL GetNamedPipeHandleState(HANDLE hNamedPipe, LPDWORD lpState, LPDWORD lpCurrentInstances, LPDWORD lpMaxCollectionCount, LPDWORD lpCollectionDataTimeout, LPTSTR lpUserName, DWORD dwMaxUserNameSize);
- hNamedPipe - открыт на чтение
- lpState - комбинация PIPE_NOWAIT (не блокирован) и PIPE_READMODE_MESSAGE (сообщения); нет PIPE_NOWAIT = блокирован; нет PIPE_READMODE_MESSAGE = поток
- lpCurrentInstances - число созданных экземпляров
- lpMaxCollectionCount - макс. число байтов, которое клиент должен записать до передачи серверу; NULL для сервера и для локальной связи через "."
- lpCollectionDataTimeout - миллисекунды до передачи по сети; те же условия NULL
- lpUserName - куда имя владельца канала (только если доступ открыт всем пользователям)
- dwMaxUserNameSize - размер lpUserName
Любой параметр после дескриптора можно NULL, если не нужен.
Возврат: не 0 / FALSE.

SetNamedPipeHandleState
BOOL SetNamedPipeHandleState(HANDLE hNamedPipe, LPDWORD lpMode, LPDWORD lpMaxCollectionCount, LPDWORD lpCollectionDataTimeout);
- hNamedPipe - открыт на запись
- lpMode - новые режимы: PIPE_READMODE_BYTE/MESSAGE (передача) и PIPE_WAIT/PIPE_NOWAIT (ожидание; влияет на ConnectNamedPipe, WriteFile, ReadFile, но не на асинхронные операции); любая комбинация; NULL = не менять
- lpMaxCollectionCount - новое макс. число байтов перед передачей; NULL = не менять; игнорируется при FILE_FLAG_WRITE_THROUGH
- lpCollectionDataTimeout - новые миллисекунды перед передачей по сети; NULL = не менять; игнорируется при FILE_FLAG_WRITE_THROUGH
Возврат: не 0 / FALSE.

GetNamedPipeInfo
BOOL GetNamedPipeInfo(HANDLE hNamedPipe, LPDWORD lpFlags, LPDWORD lpOutBufferSize, LPDWORD lpInBufferSize, LPDWORD lpMaxInstances);
- hNamedPipe - открыт на чтение
- lpFlags - выходной: PIPE_CLIENT_END / PIPE_SERVER_END (чей конец) и PIPE_TYPE_BYTE / PIPE_TYPE_MESSAGE (способ передачи)
- lpOutBufferSize - размер выходного буфера (NULL, если не нужен)
- lpInBufferSize - размер входного буфера (NULL, если не нужен)
- lpMaxInstances - макс. число экземпляров; PIPE_UNLIMITED_INSTANCES = ограничено только ресурсами системы (NULL, если не нужно)
Возврат: не 0 / FALSE.
Ловушка: в листинге 16.11 dwFlags инициализирован, но он выходной; комментарии у трёх переменных перепутаны.

Шаблоны

Сервер (один клиент, листинг 16.3):
h = CreateNamedPipe("\\\\.\\pipe\\demo_pipe", PIPE_ACCESS_DUPLEX, PIPE_TYPE_MESSAGE | PIPE_WAIT, 1, 0, 0, INFINITE, NULL);
ConnectNamedPipe(h, NULL);
ReadFile(h, buf, sizeof(buf), &n, NULL); ... WriteFile(h, buf, len, &n, NULL);
CloseHandle(h);

Клиент (листинг 16.4):
wsprintf(pipeName, "\\\\%s\\pipe\\demo_pipe", machineName);
h = CreateFile(pipeName, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
WriteFile(h, msg, len, &n, NULL); ReadFile(h, buf, sizeof(buf), &n, NULL); CloseHandle(h);

Общедоступный канал (листинг 16.5):
sa.nLength = sizeof(sa); sa.bInheritHandle = FALSE;
InitializeSecurityDescriptor(&sd, SECURITY_DESCRIPTOR_REVISION);
SetSecurityDescriptorDacl(&sd, TRUE, NULL, FALSE);
sa.lpSecurityDescriptor = &sd;
CreateNamedPipe(..., &sa);
