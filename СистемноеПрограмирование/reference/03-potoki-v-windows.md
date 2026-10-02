Справочник. Глава 3. Потоки в Windows

Логика

- Поток - объект ядра, которому ОС выделяет процессорное время. Свой контекст: код функции, регистры, стек приложения, стек ОС, маркер доступа. Плюс thread ID (уникален, пока поток жив).
- Потоки: системные / пользовательские; рабочие (фон) / интерфейсные (окна). Главный поток: main (консоль) или WinMain (окна).
- Состояния Windows: готов, выбран, выполняется, ждёт, ждёт ресурс, завершён. Готов -> выбран (планировщик выбрал) -> выполняется (переключение контекста). Выполняется -> готов (вытеснение). Выполняется -> ждёт (сам ждёт события) -> готов (дождался) или -> ждёт ресурс (ресурс занят) -> готов.
- Создание: CreateThread -> дескриптор. Функция потока вызывается ОС (callback), поэтому сигнатура жёсткая и параметр один (void*).
- Завершение: return из функции потока = ExitThread (DLL получают DLL_THREAD_DETACH). TerminateThread - аварийно, DLL не уведомляются, ресурсы не освобождаются.
- Дескриптор потока закрывать CloseHandle, иначе утечка (сам не закрывается, даже когда поток завершён).
- volatile: компилятор не знает про потоки и может держать переменную в регистре; volatile = всегда читать/писать в память. Нужно для переменных, общих для потоков.
- Приостановка = счётчик приостановок. Поток работает, только когда счётчик = 0. Suspend +1, Resume -1. Два Suspend = нужно два Resume.
- Ошибки: функция возвращает FALSE/NULL/-1, а код ошибки хранится отдельно для каждого потока (GetLastError).
- _beginthreadex/_endthreadex (process.h) - вместо CreateThread/ExitThread, если поток использует библиотеку C (Рихтер: надёжнее, правильно готовит структуры библиотеки C). Для потока, созданного _beginthreadex, завершать _endthreadex (освобождает память, выделенную при создании). В Visual C++ 6.0 в настройках выбрать Multithreaded runtime library.

Функции

CreateThread
HANDLE CreateThread(LPSECURITY_ATTRIBUTES lpThreadAttributes, DWORD dwStackSize, LPTHREAD_START_ROUTINE lpStartAddress, LPVOID lpParameter, DWORD dwCreationFlags, LPDWORD lpThreadId);
Создаёт поток.
- lpThreadAttributes - атрибуты защиты потока; NULL = по умолчанию
- dwStackSize - размер стека в байтах; 0 = по умолчанию (1 МБ). Меньше 1 МБ Windows всё равно даст 1 МБ; округляется вверх до размера страницы (4 КБ)
- lpStartAddress - адрес функции потока: DWORD WINAPI f(LPVOID lpParameters)
- lpParameter - единственный параметр, который получит функция потока (void*; можно передать указатель на структуру)
- dwCreationFlags - 0 = стартует сразу; CREATE_SUSPENDED = создан, но не запущен (запуск - ResumeThread)
- lpThreadId - выходной: адрес DWORD, куда запишется ID потока. Windows NT/2000: можно NULL. Windows 98: NULL нельзя
Возврат: дескриптор потока; при ошибке NULL.

Функция потока (callback)
DWORD WINAPI Имя(LPVOID lpParameters)
- вызывает её ОС, поэтому сигнатура фиксирована; возвращаемое DWORD = код завершения потока

ExitThread
VOID ExitThread(DWORD dwExitCode);
- dwExitCode - код завершения потока
Завершает вызывающий поток; то же, что return из функции потока. Уведомляет DLL (DLL_THREAD_DETACH). Ничего не возвращает.

TerminateThread
BOOL TerminateThread(HANDLE hThread, DWORD dwExitThread);
- hThread - какой поток убить
- dwExitThread - код завершения
Возврат: не 0 - успех, FALSE - ошибка.
Ловушка: мгновенно, DLL не уведомляются (нет DLL_THREAD_DETACH), ресурсы висят. Только если поток завис.

SuspendThread
DWORD SuspendThread(HANDLE hThread);
- hThread - какой поток приостановить (можно себя - через псевдодескриптор)
Счётчик приостановок +1. Возврат: предыдущее значение счётчика; -1 при ошибке. Макс. значение счётчика - MAXIMUM_SUSPEND_COUNT.

ResumeThread
DWORD ResumeThread(HANDLE hThread);
- hThread - какой поток возобновить
Счётчик -1 (если был > 0); поток реально запускается, когда счётчик стал 0. Счётчик уже 0 - ничего не делает. Возврат: предыдущее значение счётчика; -1 при ошибке.

Sleep
VOID Sleep(DWORD dwMilliseconds);
- dwMilliseconds - на сколько миллисекунд усыпить себя. 0 = уступить процессор готовым потокам и сразу вернуться в очередь; INFINITE = навсегда (единственный поток - приложение зависнет)
Sleep - поток усыпляет себя сам; Suspend - его останавливает другой.

GetCurrentThread
HANDLE GetCurrentThread(VOID);
Возвращает псевдодескриптор текущего потока: годится только для обращения потока к себе; нельзя передать другому процессу/потоку; не наследуется; CloseHandle не нужен. Настоящий дескриптор - DuplicateHandle (глава 4).

WaitForSingleObject (полностью - глава 6)
WaitForSingleObject(hThread, INFINITE) - ждать завершения потока.

GetLastError / SetLastError
DWORD GetLastError(VOID);
VOID SetLastError(DWORD dwErrCode);
- код последней ошибки хранится отдельно для каждого потока
- dwErrCode - какой код записать вручную

FormatMessage
DWORD FormatMessage(DWORD dwFlags, LPCVOID lpSource, DWORD dwMessageId, DWORD dwLanguageId, LPTSTR lpBuffer, DWORD nSize, va_list *Arguments);
Превращает код ошибки в текст.
- dwFlags - режим: FORMAT_MESSAGE_ALLOCATE_BUFFER (Windows сама выделяет буфер), FORMAT_MESSAGE_FROM_SYSTEM (текст из системных сообщений), FORMAT_MESSAGE_IGNORE_INSERTS (не подставлять значения)
- lpSource - источник сообщения; NULL для системных
- dwMessageId - код ошибки, обычно GetLastError()
- dwLanguageId - язык; MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT) = по умолчанию
- lpBuffer - куда писать текст; с ALLOCATE_BUFFER передаётся адрес указателя (LPTSTR)&lpMsgBuf
- nSize - макс. размер буфера; 0 при ALLOCATE_BUFFER
- Arguments - значения для вставки в сообщение; NULL
Буфер, выделенный системой, освобождать LocalFree (не free/delete).

CharToOem
BOOL CharToOem(LPCTSTR lpszSrc, LPSTR lpszDst);
- lpszSrc - исходная строка (кодировка ANSI/Microsoft)
- lpszDst - результат (кодировка OEM для консоли). Можно передать тот же буфер (CharToOem(s, s))
Без перекодировки русский текст в консоли - каша. OEM = Original Equipment Manufacturer.

Отладчик: в окне watch написать @err,hr - покажет текст последней ошибки.

Минимальный шаблон

DWORD WINAPI Add(LPVOID iNum) { n += (int)iNum; return 0; }
hThread = CreateThread(NULL, 0, Add, (void*)inc, 0, &IDThread);
if (hThread == NULL) return GetLastError();
WaitForSingleObject(hThread, INFINITE);
CloseHandle(hThread);
