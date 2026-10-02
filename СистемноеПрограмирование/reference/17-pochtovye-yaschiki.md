Справочник. Глава 17. Работа с почтовыми ящиками в Windows

Логика

- Почтовый ящик (mailslot) - объект ядра: передача сообщений от процессов-клиентов к процессам-серверам в пределах локальной сети. Характеристики: имя; направление ТОЛЬКО от клиента к серверу; передача сообщениями; обмен синхронный или асинхронный.
- Ящик - псевдофайл в оперативной памяти: доступ теми же функциями, что к файлам (CreateFile, WriteFile, ReadFile; также WriteFileEx/ReadFileEx).
- Порядок: сервер CreateMailslot -> клиент CreateFile (GENERIC_WRITE, OPEN_EXISTING) -> клиент WriteFile / сервер ReadFile -> CloseHandle у обоих. Установки связи "процесс - процесс" нет.
- Доставка системой НЕ подтверждается.
- Сообщение меньше 425 байт: дейтаграмма - рассылается ВСЕМ серверам с этим именем ящика (в пределах домена), быстро, без гарантии доставки. Несколько серверов с одним именем = однонаправленная связь "многие-ко-многим".
- Сообщение больше 426 байт: протокол SMB, только от ОДНОГО клиента к ОДНОМУ серверу; длина не больше 64 Кбайт.
- Сообщения длиной 425 и 426 байт в семействе Windows NT не поддерживаются.
- Имя на сервере (CreateMailslot): \\.\mailslot\mailslot_name - ящик создаётся ВСЕГДА локально; имя нечувствительно к регистру. В коде C: "\\\\.\\mailslot\\demo_mailslot".
- Имя на клиенте (CreateFile) - четыре формата, они определяют, КТО получит сообщение:
  - \\.\mailslot\имя - ящики на локальной машине
  - \\имя_компьютера\mailslot\имя - ящики на указанном компьютере
  - \\имя_домена\mailslot\имя - ящики внутри указанного домена
  - \\*\mailslot\имя - ящики внутри первичного домена системы
- dwReadTimeout (миллисекунды, сколько ReadFile ждёт сообщение): 0 - при пустом ящике ReadFile сразу возвращается; MAILSLOT_WAIT_FOREVER - ждёт бесконечно.
- ReadFile читает ОДНО сообщение. Размер следующего - lpNextSize из GetMailslotInfo (MAILSLOT_NO_MESSAGE, если ящик пуст); количество сообщений - lpMessageCount.
- Сервер тоже может писать в ящик, но смысл есть только при нескольких ящиках с одним именем в домене (все получат одинаковые сообщения).

Функции

CreateMailslot
HANDLE CreateMailslot(LPCTSTR lpName, DWORD dwMaxMessageSize, DWORD dwReadTimeout, LPSECURITY_ATTRIBUTES lpSecurityAttributes);
- lpName - "\\.\mailslot\mailslot_name"
- dwMaxMessageSize - максимальная длина сообщения в байтах; 0 - произвольная (комментарий листингов)
- dwReadTimeout - сколько миллисекунд ReadFile ждёт сообщение; 0 - не ждать; MAILSLOT_WAIT_FOREVER - ждать бесконечно
- lpSecurityAttributes - защита; NULL = по умолчанию
Возврат: дескриптор ящика; INVALID_HANDLE_VALUE при неудаче.
Ловушка: в прототипе книги после dwMaxMessageSize пропущена запятая.

CreateFile (для клиента ящика)
HANDLE CreateFile(LPCTSTR lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile);
- lpFileName - имя ящика в одном из четырёх форматов (см. Логика)
- dwDesiredAccess - только GENERIC_WRITE
- dwShareMode - любая комбинация FILE_SHARE_READ / FILE_SHARE_WRITE
- lpSecurityAttributes - NULL
- dwCreationDisposition - ВСЕГДА OPEN_EXISTING
- dwFlagsAndAttributes - 0 или FILE_ATTRIBUTE_NORMAL
- hTemplateFile - не используется, NULL
Возврат: дескриптор ящика; INVALID_HANDLE_VALUE при неудаче.

WriteFile (клиент) / ReadFile (сервер) - прототипы и параметры в reference/15. Для ящика lpOverlapped - NULL (синхронно); WriteFileEx/ReadFileEx - асинхронный вариант (глава 24).

GetMailslotInfo
BOOL GetMailslotInfo(HANDLE hMailslot, LPDWORD lpMaxMessageSize, LPDWORD lpNextSize, LPDWORD lpMessageCount, LPDWORD lpReadTimeout);
- hMailslot - дескриптор от CreateMailslot
- lpMaxMessageSize - выходной DWORD: максимальная длина сообщения (NULL, если не нужно)
- lpNextSize - выходной DWORD: длина СЛЕДУЮЩЕГО сообщения; MAILSLOT_NO_MESSAGE, если сообщений нет (NULL, если не нужно)
- lpMessageCount - выходной DWORD: сколько сообщений в ящике (NULL, если не нужно)
- lpReadTimeout - выходной DWORD: миллисекунды, сколько ReadFile ждёт при пустом ящике (NULL, если не нужно)
Возврат: не 0 при успехе; по тексту книги при неудаче NULL (то есть FALSE).
Ловушка: в прототипе книги пропущены запятые после lpMaxMessageSize и lpMessageCount.

SetMailslotInfo
BOOL SetMailslotInfo(HANDLE hMailslot, DWORD dwReadTimeout);
- hMailslot - дескриптор от CreateMailslot
- dwReadTimeout - новое время ожидания ReadFile в миллисекундах; 0 - не ждать; MAILSLOT_WAIT_FOREVER - бесконечно
Возврат: не 0 при успехе; по тексту книги при неудаче NULL (то есть FALSE).

Шаблоны

Сервер, читающий все накопленные сообщения (листинг 17.3):
h = CreateMailslot("\\\\.\\mailslot\\demo_mailslot", 0, MAILSLOT_WAIT_FOREVER, NULL);
GetMailslotInfo(h, NULL, &nextSize, &count, NULL);
while (count != 0) { p = new char[nextSize]; ReadFile(h, p, nextSize, &n, NULL); ...; GetMailslotInfo(h, NULL, &nextSize, &count, NULL); delete[] p; }
CloseHandle(h);

Клиент (листинг 17.4):
h = CreateFile("\\\\.\\mailslot\\demo_mailslot", GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
WriteFile(h, msg, strlen(msg) + 1, &n, NULL);
CloseHandle(h);

Сравнение трёх механизмов части IV (по книге)

- Анонимный канал (гл. 15): без имени; один компьютер; полудуплекс (направление задаёт дескриптор); поток байтов; синхронный; доступ - родитель и потомки (наследование дескриптора); CreatePipe; клиент получает унаследованный дескриптор.
- Именованный канал (гл. 16): имя \\.\pipe\name; компьютеры одной локальной сети; полудуплекс или дуплекс; поток или сообщения; синхронный или асинхронный; несколько экземпляров = несколько клиентов; сервер CreateNamedPipe + ConnectNamedPipe, клиент WaitNamedPipe + CreateFile.
- Почтовый ящик (гл. 17): имя \\.\mailslot\name; локальная сеть (домен); ТОЛЬКО от клиента к серверу; сообщения; синхронный или асинхронный; рассылка всем серверам с одним именем (сообщения меньше 425 байт); нет подтверждения доставки; сервер CreateMailslot, клиент CreateFile (GENERIC_WRITE).
