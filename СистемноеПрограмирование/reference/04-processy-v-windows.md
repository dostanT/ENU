Справочник. Глава 4. Процессы в Windows

Логика

- Процесс = объект ядра, контейнер ресурсов. Сам код выполняют потоки (первичный поток создаётся вместе с процессом). Процесс завершён, когда завершились ВСЕ его потоки.
- Процессу принадлежат: виртуальное адресное пространство, рабочее множество (часть, реально лежащая в RAM), маркер доступа (от чьего имени работает, что разрешено), таблица дескрипторов (своя у каждого процесса). Плюс PID: просто номер, прав доступа не даёт.
- Родитель вызывает CreateProcess -> получает PROCESS_INFORMATION (hProcess, hThread, dwProcessId, dwThreadId). Дескрипторы hProcess и hThread закрывать CloseHandle (сами не закрываются, даже если процесс уже завершён). Закрытие дескриптора не убивает процесс.
- Ждать завершения дочернего: WaitForSingleObject(pi.hProcess, INFINITE).
- Завершение: ExitProcess (сам себя, DLL получают DLL_PROCESS_DETACH) и TerminateProcess (чужой, DLL не уведомляются, только для аварий).
- Наследование дескрипторов - три условия одновременно: 1) дескриптор создан наследуемым (bInheritHandle = TRUE в SECURITY_ATTRIBUTES при создании объекта, либо SetHandleInformation); 2) CreateProcess с bInheritHandles = TRUE; 3) число-значение дескриптора передано дочернему явно (обычно командной строкой, itoa/wsprintf). Причина третьего: дочерний процесс не может угадать номер.
- Не наследуются: дескрипторы памяти (LocalAlloc, GlobalAlloc, HeapCreate, HeapAlloc) и DLL (LoadLibrary) - привязаны к адресному пространству.
- Наследование против именования объектов: имя = поиск по имени (дороже) и нужна гарантия уникальности (GUID). Анонимный наследуемый объект проще и быстрее.
- DuplicateHandle: копия дескриптора с другими правами/наследованием, можно в другой процесс. Пример: дать ребёнку только THREAD_TERMINATE, чтобы он мог убить поток, но не Suspend/Resume.
- Псевдодескриптор (GetCurrentProcess/GetCurrentThread): только для себя, не наследуется, CloseHandle не нужен. Настоящий - через DuplicateHandle.
- Планирование: вытесняющая многозадачность, квант около 20 мс. Приоритеты 0-31. Базовый приоритет потока = класс приоритета процесса + уровень приоритета потока.
- Динамическое изменение (только базовый 0-15): при получении сообщения/переходе в готовность +2, потом -1 за каждый отработанный квант, но не ниже исходного базового.
- Особенность Windows 2000 vs 98: SetHandleInformation, GetHandleInformation, *PriorityBoost (4 функции) в Windows 98 всегда возвращают FALSE. Вместо SetHandleInformation в 98 - DuplicateHandle.

Функции

CreateProcess
BOOL CreateProcess(LPCTSTR lpApplicationName, LPTSTR lpCommandLine, LPSECURITY_ATTRIBUTES lpProcessAttributes, LPSECURITY_ATTRIBUTES lpThreadAttributes, BOOL bInheritHandles, DWORD dwCreationFlags, LPVOID lpEnvironment, LPCTSTR lpCurrentDirectory, LPSTARTUPINFO lpStartUpInfo, LPPROCESS_INFORMATION lpProcessInformation);
Создаёт процесс. 10 параметров.
- lpApplicationName - имя exe с ПОЛНЫМ путём (строка, оканчивается нулём). Или NULL, если задан lpCommandLine
- lpCommandLine - командная строка: имя программы + аргументы. Полный путь не нужен: ищет в порядке 1) каталог, откуда запущено приложение, 2) текущий каталог родителя, 3) системный каталог Windows, 4) каталог Windows, 5) каталоги из PATH
- lpProcessAttributes - защита процесса; NULL = по умолчанию
- lpThreadAttributes - защита первичного потока; NULL = по умолчанию
- bInheritHandles - TRUE: наследуемые дескрипторы родителя передаются потомку; FALSE: не передаются
- dwCreationFlags - флаги: CREATE_NEW_CONSOLE (новая консоль; если 0/NULL - вывод идёт в консоль родителя), класс приоритета (см. ниже)
- lpEnvironment - блок окружения; NULL = как у родителя
- lpCurrentDirectory - текущий диск и каталог; NULL = как у родителя
- lpStartUpInfo - STARTUPINFO: вид главного окна. Перед вызовом ZeroMemory(&si, sizeof(STARTUPINFO)); si.cb = sizeof(STARTUPINFO); (иначе поведение непредсказуемо)
- lpProcessInformation - выходной: PROCESS_INFORMATION (hProcess, hThread, dwProcessId, dwThreadId нового процесса и его первичного потока)
Возврат: не 0 - успех; FALSE - ошибка (причина - GetLastError).
Ловушка: запуск командной строкой vs lpApplicationName - два способа задать программу, обычно используют один.

Шаблон
STARTUPINFO si; PROCESS_INFORMATION pi;
ZeroMemory(&si, sizeof(STARTUPINFO)); si.cb = sizeof(STARTUPINFO);
if (!CreateProcess(NULL, "Notepad.exe", NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) return GetLastError();
WaitForSingleObject(pi.hProcess, INFINITE);
CloseHandle(pi.hThread); CloseHandle(pi.hProcess);

ExitProcess
VOID ExitProcess(UINT uExitCode);
- uExitCode - код возврата процесса (получают все его потоки)
Процесс завершает сам себя: все потоки завершаются, DLL получают DLL_PROCESS_DETACH.

TerminateProcess
BOOL TerminateProcess(HANDLE hProcess, UINT uExitCode);
- hProcess - какой процесс убить
- uExitCode - код возврата
Возврат: не 0 - успех, FALSE - ошибка. Не освобождает все ресурсы (DLL_PROCESS_DETACH не посылается). Только аварийно.

SetHandleInformation
BOOL SetHandleInformation(HANDLE hObject, DWORD dwMask, DWORD dwFlags);
Меняет свойства дескриптора (Windows 2000).
- hObject - дескриптор
- dwMask - какие флаги меняем (например HANDLE_FLAG_INHERIT)
- dwFlags - новые значения этих флагов (HANDLE_FLAG_INHERIT = сделать наследуемым, 0 = ненаследуемым)
Пример: SetHandleInformation(hThread, HANDLE_FLAG_INHERIT, HANDLE_FLAG_INHERIT);
Возврат: не 0 - успех, FALSE - ошибка (в Windows 98 всегда FALSE).

GetHandleInformation
BOOL GetHandleInformation(HANDLE hObject, LPDWORD lpdwFlags);
- hObject - дескриптор
- lpdwFlags - выходной: свойства дескриптора
Возврат: не 0 / FALSE. Только Windows 2000.

DuplicateHandle
BOOL DuplicateHandle(HANDLE hSourceProcessHandle, HANDLE hSourceHandle, HANDLE hTargetProcessHandle, LPHANDLE lpTargetHandle, DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwOptions);
Копия дескриптора. 7 параметров.
- hSourceProcessHandle - дескриптор процесса-источника (чей дескриптор копируем)
- hSourceHandle - исходный дескриптор
- hTargetProcessHandle - дескриптор процесса-приёмника (куда копия)
- lpTargetHandle - выходной: адрес переменной для нового дескриптора
- dwDesiredAccess - права доступа к объекту через копию (флаги зависят от типа объекта; например THREAD_TERMINATE). Игнорируется, если в dwOptions DUPLICATE_SAME_ACCESS
- bInheritHandle - TRUE: копия наследуемая; FALSE: нет
- dwOptions - комбинация: DUPLICATE_CLOSE_SOURCE (закрыть исходный дескриптор после дублирования), DUPLICATE_SAME_ACCESS (те же права, что у исходного)
Возврат: не 0 - успех, FALSE - ошибка.

GetCurrentProcess
HANDLE GetCurrentProcess(VOID);
Псевдодескриптор текущего процесса.

SetPriorityClass / GetPriorityClass
BOOL SetPriorityClass(HANDLE hProcess, DWORD dwPriorityClass);
DWORD GetPriorityClass(HANDLE hProcess);
- hProcess - процесс
- dwPriorityClass - один из флагов: IDLE_PRIORITY_CLASS (фон), BELOW_NORMAL_PRIORITY_CLASS (с Windows 2000), NORMAL_PRIORITY_CLASS (по умолчанию), ABOVE_NORMAL_PRIORITY_CLASS (с Windows 2000), HIGH_PRIORITY_CLASS (мало кода, быстро), REAL_TIME_PRIORITY_CLASS (реальное время, работа с железом)
Set: не 0 / FALSE. Get: возвращает флаг класса; при ошибке 0.
Ловушка: числовые значения флагов не отражают порядок приоритетов (IDLE числово больше NORMAL) - это просто идентификаторы.
Класс задаётся и при создании: через dwCreationFlags в CreateProcess.

SetThreadPriority / GetThreadPriority
BOOL SetThreadPriority(HANDLE hThread, int nPriority);
DWORD GetThreadPriority(HANDLE hThread);
- hThread - поток
- nPriority - уровень: THREAD_PRIORITY_LOWEST (-2), BELOW_NORMAL (-1), NORMAL (0, по умолчанию), ABOVE_NORMAL (+1), HIGHEST (+2) - относительно приоритета процесса; THREAD_PRIORITY_IDLE (базовый = 16 в классе REAL_TIME, иначе 1); THREAD_PRIORITY_TIME_CRITICAL (31 в REAL_TIME, иначе 15)
Set: не 0 / FALSE. Get: возвращает уровень; при ошибке THREAD_PRIORITY_ERROR_RETURN.

Таблица базовых приоритетов (уровень потока / класс процесса: Real time, High, Above normal, Normal, Below normal, Idle)
- Time critical: 31, 15, 15, 15, 15, 15
- Highest: 26, 15, 12, 10, 8, 6
- Above normal: 25, 14, 11, 9, 7, 5
- Normal: 24, 13, 10, 8, 6, 4
- Below normal: 23, 12, 9, 7, 5, 3
- Lowest: 22, 11, 8, 6, 4, 2
- Idle: 16, 1, 1, 1, 1, 1
Пример: Normal в классе High = 13; Normal в классе Idle = 4.

SetProcessPriorityBoost / GetProcessPriorityBoost / SetThreadPriorityBoost / GetThreadPriorityBoost (Windows 2000)
BOOL SetProcessPriorityBoost(HANDLE hProcess, BOOL DisablePriorityBoost);
BOOL GetProcessPriorityBoost(HANDLE hProcess, PBOOL pDisablePriorityBoost);
BOOL SetThreadPriorityBoost(HANDLE hThread, BOOL DisablePriorityBoost);
BOOL GetThreadPriorityBoost(HANDLE hThread, PBOOL pDisablePriorityBoost);
- DisablePriorityBoost - TRUE: динамическое повышение ЗАПРЕЩЕНО; FALSE: РАЗРЕШЕНО (по умолчанию). Название читается наоборот, ловушка.
- pDisablePriorityBoost - выходной: текущее состояние (TRUE = запрещено)
- Process-версии действуют на все потоки процесса, Thread-версии - на один поток
Возврат: не 0 / FALSE (в Windows 98 всегда FALSE).
