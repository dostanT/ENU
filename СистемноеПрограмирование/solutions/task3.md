Задача 3 - мини-проект "Банк Ырыс: Диспетчерская мониторинга банкоматов"

Идея

Сиквел к solutions/task2.md: тот же банк "Ырыс", тот же принцип - не набор
несвязанных демонстраций, а один связный сценарий, где у каждого механизма
из глав 9-17 есть понятная причина быть именно здесь. Раз эти главы - про
консольные приложения (9-13) и передачу данных между процессами (14-17), а
не про потоки внутри одного процесса, как в главах 1-8, сценарий здесь
неизбежно МНОГОПРОЦЕССНЫЙ: диспетчерская - это дашборд на консоли, который
одновременно принимает данные от трёх разных видов дочерних процессов,
каждый через свой канал связи из своей главы.

Все четыре роли (диспетчер и три вида дочерних процессов) - это ОДИН и тот
же exe, роль выбирается первым аргументом командной строки. Диспетчер
узнаёт свой собственный путь (GetModuleFileName) и запускает себя же
повторно с нужной ролью - README не пришлось разбивать на 4 отдельных
файла, а получить именно multi-process сценарий, как того требуют главы
14-17, всё равно удалось.

Единственная оговорка про заголовки (тот же случай, что в task2.md): кроме
windows.h и iostream.h понадобился ещё stdlib.h - ради atoi() при разборе
чисел из командной строки (обычный C, не Win32-специфика).

Код

```c
// ============================================================================
//  Банк "Ырыс" - Диспетчерская мониторинга банкоматов
//  Мини-проект, охватывающий главы 9-17 (консольные приложения и передача
//  данных между процессами) - сиквел к solutions/task2.md (главы 1-8, тот
//  же банк, тот же общий стиль и приёмы: PrintLastError, критическая
//  секция вокруг вывода, событие с ручным сбросом для завершения).
//
//  Роли одного и того же exe (роль выбирается argv[1] - диспетчер запускает
//  сам себя повторно нужным аргументом через GetModuleFileName, см. main()
//  и функции Spawn*):
//
//    (без аргументов)  - диспетчер: главный процесс, рисует дашборд на
//                         консоли и принимает данные от трёх видов дочерних
//                         процессов одновременно;
//    agent <handle>    - датчик нагрузки: пишет в анонимный канал (15);
//    branch            - отделение: обменивается данными через именованный
//                         канал (16);
//    atm <id>          - банкомат: шлёт сообщения в почтовый ящик (17).
//
//  Карточка каждого канала передачи данных (глава 14 - в самой главе нет
//  функций Win32, только теория и словарь понятий; ниже он применён к трём
//  реальным каналам этого проекта, как и просит книга при разборе канала):
//
//    Анонимный канал agent -> диспетчер (глава 15):
//      имя: нет. Направление: полудуплекс, задаётся дескриптором (agent
//      только пишет, диспетчер только читает). Передача: потоком байтов
//      (сырая структура SensorReading, без разделителей сообщений). Обмен:
//      синхронный (ReadFile блокирует поток-читатель, пока agent не
//      напишет). Буферизация: ограниченная (dwSize у CreatePipe). Топология:
//      1 -> 1. Один компьютер. Адресация: косвенная, через значение
//      дескриптора, переданное в командной строке (способ явной передачи
//      из главы 15 и главы 10 - второй способ, через STARTUPINFO.hStdInput/
//      hStdOutput, в этом проекте не использован, см. пояснение внизу файла).
//
//    Именованный канал branch <-> диспетчер (глава 16):
//      имя: "\\.\pipe\Bank_Iris_BranchPipe". Направление: дуплекс
//      (PIPE_ACCESS_DUPLEX). Передача: сообщениями (PIPE_TYPE_MESSAGE).
//      Обмен: синхронный. Буферизация: ограниченная. Топология: 1 -> 1
//      (один экземпляр канала - одно отделение зараз). По природе -
//      локальная сеть, здесь один компьютер ("."). Адресация: косвенная,
//      по имени канала.
//
//    Почтовый ящик atm -> диспетчер (глава 17):
//      имя: "\\.\mailslot\Bank_Iris_ATMAlerts". Направление: только от
//      клиента к серверу - классическая топология этого механизма N -> 1
//      (несколько банкоматов, один диспетчер). Передача: сообщениями.
//      Обмен: синхронный с таймаутом ожидания (dwReadTimeout). Доставка не
//      подтверждается. По природе - домен, здесь один компьютер. Адресация:
//      косвенная, по имени ящика.
//
//  Единственная оговорка про заголовки (тот же случай, что в task2.md):
//  кроме windows.h и iostream.h понадобился ещё stdlib.h - ради atoi() при
//  разборе аргументов командной строки (обычный C, не Win32-специфика).
//
//  Не скомпилировано по-настоящему (нет Windows/MSVC в этом окружении) -
//  проверено по документации и логике API, каждая сигнатура сверена
//  построчно с lectures/09-17 и reference/09-17.
// ============================================================================

#include <windows.h>
#include <iostream>
#include <stdlib>   // atoi() - см. оговорку выше
usign namespace std;

// ---------- Имена каналов ----------

#define BRANCH_PIPE_NAME   "\\\\.\\pipe\\Bank_Iris_BranchPipe"
#define ATM_MAILSLOT_NAME  "\\\\.\\mailslot\\Bank_Iris_ATMAlerts"

// ---------- Размеры и раскладка дашборда (глава 11, 12) ----------

const int ATM_COUNT      = 3;    // сколько банкоматов в сегменте сети
const int AGENT_READINGS = 8;    // сколько показаний пришлёт датчик нагрузки

const int BUF_COLS = 100;   // ширина буфера экрана диспетчера (холст)
const int BUF_ROWS = 40;    // высота буфера экрана
const int WIN_COLS = 90;    // ширина ОКНА - меньше буфера (11: окно <= буфера)
const int WIN_ROWS = 25;

const int ROW_TITLE  = 0;
const int ROW_BOARD  = 3;          // строка табло банкоматов
const int ROW_LOAD   = 5;          // строка датчика нагрузки диспетчерской
const int ROW_HINT   = BUF_ROWS - 1;
const int LOG_TOP    = 7;          // первая строка прокручиваемого журнала
const int LOG_BOTTOM = BUF_ROWS - 3;

const int CELL_WIDTH = 14;   // ширина одной клетки табло банкомата

// ---------- Общие ресурсы диспетчера ----------

CRITICAL_SECTION g_csLog;        // защищает вывод в журнал и табло (6.1)
HANDLE           g_hQuitEvent;   // "пора закрываться", ручной сброс (6.4)
HANDLE           g_hStdOut;      // активный буфер экрана диспетчера
HANDLE           g_hStdIn;       // входной буфер диспетчера
HANDLE           g_hAgentRead;   // дескриптор ЧТЕНИЯ анонимного канала
HANDLE           g_hMailslot;    // дескриптор почтового ящика (сервер)

int  g_logRow = LOG_TOP;         // следующая свободная строка журнала
char g_exePath[MAX_PATH];        // путь к собственному exe (для самозапуска)

struct AtmCell
{
    int  state;          // 0 - нет данных, 1 - в норме, 2 - тревога
    char lastMsg[64];    // текст последнего сообщения от банкомата
};
AtmCell g_atm[ATM_COUNT];

DWORD g_agentLoad = 0;    // последнее показание датчика нагрузки (глава 15)

// Данные, которые agent передаёт диспетчеру потоком байтов через
// анонимный канал - сырая структура, а не текст (контраст с cout,
// про который прямо предупреждает глава 15: формат чтения должен
// совпадать с форматом записи).
struct SensorReading
{
    DWORD load;   // условная загрузка диспетчерской, %
    DWORD tick;   // GetTickCount на момент замера
};

// ============================================================================
//  Общие мелкие помощники
// ============================================================================

// Текст ошибки Win32 для ролей с ОБЫЧНОЙ консолью (branch, atm) - тот же
// приём, что PrintLastError в task2.md (тема 3.6, CoutErrorMessage).
void PrintLastError(const char* what)
{
    DWORD  err = GetLastError();
    LPVOID lpMsgBuf;

    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL, err, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPTSTR)&lpMsgBuf, 0, NULL);

    cout << "[ОШИБКА] " << what << " (код " << err << "): " << (char*)lpMsgBuf << endl;

    LocalFree(lpMsgBuf);
}

// Путь к собственному exe - понадобится всем трём Spawn*(), чтобы диспетчер
// мог запускать САМ СЕБЯ с другой ролью в командной строке. GetModuleFileName -
// обычная (не из глав 9-17) функция Win32 для получения пути к своему
// модулю, тот же приём переиспользования, что DuplicateHandle/CreateProcess
// из главы 4 в task2.md.
void BuildExePath()
{
    if (GetModuleFileName(NULL, g_exePath, MAX_PATH) == 0)
    {
        PrintLastError("GetModuleFileName");
        lstrcpy(g_exePath, "dispatcher.exe");   // крайний случай, не должен случиться
    }
}

// ============================================================================
//  Дашборд диспетчера: журнал с прокруткой (глава 13)
// ============================================================================

// ScrollConsoleScreenBuffer, ОГРАНИЧЕННЫЙ областью журнала через
// lpClipRectangle - в примере книги (GoToNewLine) прокручивается весь
// буфер целиком, здесь - только строки LOG_TOP..LOG_BOTTOM, чтобы табло и
// заголовок наверху не съезжали вместе с журналом.
void ScrollLogUp()
{
    SMALL_RECT srScroll;
    srScroll.Left = 0; srScroll.Top = (SHORT)(LOG_TOP + 1);
    srScroll.Right = (SHORT)(BUF_COLS - 1); srScroll.Bottom = (SHORT)LOG_BOTTOM;

    SMALL_RECT srClip;
    srClip.Left = 0; srClip.Top = (SHORT)LOG_TOP;
    srClip.Right = (SHORT)(BUF_COLS - 1); srClip.Bottom = (SHORT)LOG_BOTTOM;

    COORD coordDest;
    coordDest.X = 0; coordDest.Y = (SHORT)LOG_TOP;

    CHAR_INFO fill;
    fill.Char.AsciiChar = ' ';
    fill.Attributes     = FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE;

    if (!ScrollConsoleScreenBuffer(g_hStdOut, &srScroll, &srClip, coordDest, &fill))
        PrintLastError("ScrollConsoleScreenBuffer");
}

// Строка журнала: источник события + сам текст. Пишется через
// WriteConsole (высокий уровень, глава 13), с прокруткой, когда область
// журнала заполнена. Единственная точка вывода дашборда, защищённая
// критической секцией - без неё три потока-читателя каналов (глава 15-17)
// писали бы в консоль одновременно и портили бы друг другу строки.
void Log(const char* src, const char* msg)
{
    EnterCriticalSection(&g_csLog);

    char line[BUF_COLS + 1];
    wsprintf(line, "[%-9s] %s", src, msg);

    if (g_logRow > LOG_BOTTOM)
    {
        ScrollLogUp();
        g_logRow = LOG_BOTTOM;
    }

    COORD coord;
    coord.X = 0; coord.Y = (SHORT)g_logRow;

    DWORD written;
    FillConsoleOutputCharacter(g_hStdOut, ' ', BUF_COLS, coord, &written);  // стереть старое
    SetConsoleCursorPosition(g_hStdOut, coord);
    WriteConsole(g_hStdOut, line, lstrlen(line), &written, NULL);

    g_logRow++;

    LeaveCriticalSection(&g_csLog);
}

// ============================================================================
//  Дашборд диспетчера: табло банкоматов и датчик нагрузки (глава 12, 13)
// ============================================================================

// Одна клетка табло: цвет через FillConsoleOutputAttribute (глава 12,
// красит УЖЕ существующие клетки, не трогая символы), текст через
// WriteConsoleOutputCharacter (глава 13, пишет в клетку, не двигая курсор).
void DrawAtmCell(int index)
{
    COORD coord;
    coord.X = (SHORT)(index * CELL_WIDTH); coord.Y = (SHORT)ROW_BOARD;

    WORD attr;
    const char* mark;
    switch (g_atm[index].state)
    {
    case 2:
        attr = BACKGROUND_RED | BACKGROUND_INTENSITY |
               FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY;
        mark = "!!!";
        break;
    case 1:
        attr = BACKGROUND_GREEN |
               FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY;
        mark = "ok";
        break;
    default:
        attr = BACKGROUND_BLUE | FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE;
        mark = "...";
        break;
    }

    char label[CELL_WIDTH + 1];
    wsprintf(label, " ATM %-2d %-4s", index + 1, mark);

    DWORD written;
    FillConsoleOutputAttribute(g_hStdOut, attr, CELL_WIDTH, coord, &written);
    WriteConsoleOutputCharacter(g_hStdOut, label, lstrlen(label), coord, &written);
}

void DrawAllAtmCells()
{
    for (int i = 0; i < ATM_COUNT; ++i)
        DrawAtmCell(i);
}

void DrawLoad()
{
    char  line[64];
    wsprintf(line, "Нагрузка диспетчерской: %d%%       ", g_agentLoad);

    COORD coord;
    coord.X = 0; coord.Y = (SHORT)ROW_LOAD;

    DWORD written;
    SetConsoleCursorPosition(g_hStdOut, coord);
    WriteConsole(g_hStdOut, line, lstrlen(line), &written, NULL);
}

// ============================================================================
//  Заставка через второй буфер экрана - двойная буферизация (глава 12)
// ============================================================================

void ShowSplash()
{
    HANDLE hSplash = CreateConsoleScreenBuffer(
        GENERIC_READ | GENERIC_WRITE, 0, NULL, CONSOLE_TEXTMODE_BUFFER, NULL);
    if (hSplash == INVALID_HANDLE_VALUE)
    {
        PrintLastError("CreateConsoleScreenBuffer (заставка)");
        return;
    }

    SetConsoleTextAttribute(hSplash,
        BACKGROUND_BLUE | BACKGROUND_INTENSITY |
        FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_INTENSITY);

    DWORD written;
    COORD coord;

    coord.X = 2; coord.Y = 2;
    char title1[] = "БАНК \"ЫРЫС\"";
    SetConsoleCursorPosition(hSplash, coord);
    WriteConsole(hSplash, title1, lstrlen(title1), &written, NULL);

    coord.X = 2; coord.Y = 4;
    char title2[] = "Диспетчерская мониторинга банкоматов";
    SetConsoleCursorPosition(hSplash, coord);
    WriteConsole(hSplash, title2, lstrlen(title2), &written, NULL);

    coord.X = 2; coord.Y = 6;
    char title3[] = "Поднимаю каналы связи...";
    SetConsoleCursorPosition(hSplash, coord);
    WriteConsole(hSplash, title3, lstrlen(title3), &written, NULL);

    if (!SetConsoleActiveScreenBuffer(hSplash))
        PrintLastError("SetConsoleActiveScreenBuffer (заставка)");

    Sleep(1200);

    if (!SetConsoleActiveScreenBuffer(g_hStdOut))
        PrintLastError("SetConsoleActiveScreenBuffer (возврат к дашборду)");

    CloseHandle(hSplash);
}

// ============================================================================
//  Настройка консоли и окна диспетчера (глава 11, 12, 13)
// ============================================================================

BOOL SetupDispatcherConsole()
{
    if (!SetConsoleTitle("Банк \"Ырыс\" - Диспетчерская мониторинга"))
        PrintLastError("SetConsoleTitle");

    g_hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
    g_hStdIn  = GetStdHandle(STD_INPUT_HANDLE);
    if (g_hStdOut == INVALID_HANDLE_VALUE || g_hStdIn == INVALID_HANDLE_VALUE)
    {
        PrintLastError("GetStdHandle");
        return FALSE;
    }

    // Сначала увеличиваем буфер (холст), только потом окно (глава 11:
    // окно никогда не больше буфера - порядок именно поэтому такой).
    COORD bufSize;
    bufSize.X = (SHORT)BUF_COLS; bufSize.Y = (SHORT)BUF_ROWS;
    if (!SetConsoleScreenBufferSize(g_hStdOut, bufSize))
        PrintLastError("SetConsoleScreenBufferSize");

    SMALL_RECT winRect;
    winRect.Left = 0; winRect.Top = 0;
    winRect.Right = (SHORT)(WIN_COLS - 1); winRect.Bottom = (SHORT)(WIN_ROWS - 1);
    if (!SetConsoleWindowInfo(g_hStdOut, TRUE, &winRect))
        PrintLastError("SetConsoleWindowInfo");

    // Остальная часть главы 11: узнаём максимально возможный размер окна
    // и читаем заголовок обратно, чтобы убедиться, что он правда встал.
    COORD maxWin = GetLargestConsoleWindowSize(g_hStdOut);
    if (maxWin.X == 0 && maxWin.Y == 0)
        PrintLastError("GetLargestConsoleWindowSize");
    else if (maxWin.X < WIN_COLS || maxWin.Y < WIN_ROWS)
        Log("СИСТЕМА", "экран мельче, чем нужно дашборду - часть текста может не влезть");

    char  titleBuf[128];
    DWORD titleLen = GetConsoleTitle(titleBuf, sizeof(titleBuf));
    if (titleLen == 0)
        PrintLastError("GetConsoleTitle");

    HWND hWnd = GetConsoleWindow();
    if (hWnd == NULL)
        Log("СИСТЕМА", "GetConsoleWindow не нашёл окно (нужны Windows 2000/XP)");

    CONSOLE_CURSOR_INFO cci;
    cci.dwSize   = 25;
    cci.bVisible = TRUE;
    if (!SetConsoleCursorInfo(g_hStdOut, &cci))
        PrintLastError("SetConsoleCursorInfo");

    // Низкоуровневый ввод: без построчного режима и без эха - события
    // разбираем сами через ReadConsoleInput; окно и мышь - тоже приложению.
    DWORD dwMode;
    if (!GetConsoleMode(g_hStdIn, &dwMode))
        PrintLastError("GetConsoleMode");
    dwMode &= ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT);
    dwMode |= ENABLE_WINDOW_INPUT | ENABLE_MOUSE_INPUT;
    // ENABLE_QUICK_EDIT_MODE и ENABLE_EXTENDED_FLAGS не описаны в этой
    // главе книги (общее знание Win32, помечено отдельно): по умолчанию
    // QuickEdit включён и перехватывает клик мыши под выделение текста,
    // тогда MOUSE_EVENT в приложение вообще не попадёт - отключаем явно.
    dwMode |= ENABLE_EXTENDED_FLAGS;
    dwMode &= ~ENABLE_QUICK_EDIT_MODE;
    if (!SetConsoleMode(g_hStdIn, dwMode))
        PrintLastError("SetConsoleMode");

    return TRUE;
}

void DrawDashboardChrome()
{
    DWORD written;
    COORD zero;
    zero.X = 0; zero.Y = (SHORT)ROW_TITLE;

    WORD titleAttr = BACKGROUND_BLUE | BACKGROUND_INTENSITY |
                      FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY;
    FillConsoleOutputAttribute(g_hStdOut, titleAttr, BUF_COLS, zero, &written);
    SetConsoleTextAttribute(g_hStdOut, titleAttr);

    char title[] = " БАНК \"ЫРЫС\" - ДИСПЕТЧЕРСКАЯ МОНИТОРИНГА ";
    SetConsoleCursorPosition(g_hStdOut, zero);
    WriteConsole(g_hStdOut, title, lstrlen(title), &written, NULL);

    SetConsoleTextAttribute(g_hStdOut, FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);

    COORD c;
    c.X = 0; c.Y = 2;
    char boardLabel[] = "Табло банкоматов:";
    SetConsoleCursorPosition(g_hStdOut, c);
    WriteConsole(g_hStdOut, boardLabel, lstrlen(boardLabel), &written, NULL);

    DrawAllAtmCells();
    DrawLoad();

    c.X = 0; c.Y = (SHORT)(LOG_TOP - 1);
    char logLabel[] = "Журнал событий:";
    SetConsoleCursorPosition(g_hStdOut, c);
    WriteConsole(g_hStdOut, logLabel, lstrlen(logLabel), &written, NULL);

    c.X = 0; c.Y = (SHORT)ROW_HINT;
    char hint[] = "Q-выход  C-очистить журнал  ЛКМ по табло-подробности о банкомате";
    SetConsoleCursorPosition(g_hStdOut, c);
    WriteConsole(g_hStdOut, hint, lstrlen(hint), &written, NULL);
}

// ============================================================================
//  Датчик нагрузки: анонимный канал agent -> диспетчер (глава 15)
// ============================================================================

// Запуск датчика: дескриптор ЗАПИСИ передаём наследуемым дубликатом через
// командную строку (листинг 15.2 книги, приём предпочтён дуплексному
// варианту с двумя наследуемыми дескрипторами из листинга 15.4, потому что
// здесь канал полудуплексный и нужен только один дескриптор у потомка).
BOOL SpawnAgent()
{
    HANDLE hRead, hWrite, hInheritWrite;

    if (!CreatePipe(&hRead, &hWrite, NULL, 0))
    {
        PrintLastError("CreatePipe (agent)");
        return FALSE;
    }
    g_hAgentRead = hRead;   // остаётся ненаследуемым - виден только диспетчеру

    if (!DuplicateHandle(GetCurrentProcess(), hWrite, GetCurrentProcess(),
                          &hInheritWrite, 0, TRUE, DUPLICATE_SAME_ACCESS))
    {
        PrintLastError("DuplicateHandle (agent write)");
        CloseHandle(hWrite);
        return FALSE;
    }
    CloseHandle(hWrite);   // ненаследуемый оригинал больше не нужен

    char cmdLine[MAX_PATH + 32];
    wsprintf(cmdLine, "\"%s\" agent %d", g_exePath, (int)hInheritWrite);

    STARTUPINFO         si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);

    // DETACHED_PROCESS (глава 10): у датчика нет и не будет собственной
    // консоли - она ему не нужна, он только пишет в канал и завершается.
    if (!CreateProcess(NULL, cmdLine, NULL, NULL, TRUE,
                        DETACHED_PROCESS, NULL, NULL, &si, &pi))
    {
        PrintLastError("CreateProcess (agent)");
        CloseHandle(hInheritWrite);
        return FALSE;
    }
    CloseHandle(hInheritWrite);   // копия ушла ребёнку, здесь она больше не нужна
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);

    return TRUE;
}

// Поток-читатель: ReadFile блокируется, пока agent не пришлёт очередное
// показание (обмен синхронный, глава 14) - поэтому читает в отдельном
// потоке, а не в главном цикле, который занят вводом с консоли.
DWORD WINAPI AgentReaderThread(LPVOID)
{
    SensorReading r;
    DWORD         n;

    for (;;)
    {
        if (!ReadFile(g_hAgentRead, &r, sizeof(r), &n, NULL) || n == 0)
            break;   // канал закрыт (agent закончил или диспетчер завершается)

        g_agentLoad = r.load;

        EnterCriticalSection(&g_csLog);
        DrawLoad();
        LeaveCriticalSection(&g_csLog);

        char msg[64];
        wsprintf(msg, "показание: нагрузка %d%% (тик %u)", r.load, r.tick);
        Log("ДАТЧИК", msg);
    }

    return 0;
}

// ============================================================================
//  Отделение: именованный канал branch <-> диспетчер (глава 16)
// ============================================================================

BOOL SpawnBranch()
{
    char cmdLine[MAX_PATH + 16];
    wsprintf(cmdLine, "\"%s\" branch", g_exePath);

    STARTUPINFO         si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);

    // Ни CREATE_NEW_CONSOLE, ни DETACHED_PROCESS не указаны - по умолчанию
    // консольный потомок делит консоль родителя (глава 10, п. 1). Это
    // сделано НАРОЧНО, а не по недосмотру: несколько строк branch появятся
    // прямо в консоли диспетчера вперемешку с журналом - так на практике и
    // выглядит поведение по умолчанию, отличное от agent (нет консоли) и
    // atm (совсем новая консоль) ниже.
    if (!CreateProcess(NULL, cmdLine, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi))
    {
        PrintLastError("CreateProcess (branch)");
        return FALSE;
    }
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return TRUE;
}

// Сервер именованного канала - целиком в отдельном потоке, потому что
// ConnectNamedPipe блокирует вызывающий поток, пока не подключится клиент
// (глава 16 прямо советует не делать это в главном потоке).
DWORD WINAPI NamedPipeServerThread(LPVOID)
{
    HANDLE h = CreateNamedPipe(
        BRANCH_PIPE_NAME,
        PIPE_ACCESS_DUPLEX,
        PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
        1,           // один экземпляр - одно отделение зараз
        512, 512,    // размеры буферов - только пожелание системе
        5000,        // таймаут по умолчанию для клиентского WaitNamedPipe
        NULL);

    if (h == INVALID_HANDLE_VALUE)
    {
        PrintLastError("CreateNamedPipe");
        return 1;
    }

    BOOL connected = ConnectNamedPipe(h, NULL);
    if (!connected && GetLastError() != ERROR_PIPE_CONNECTED)
    {
        PrintLastError("ConnectNamedPipe");
        CloseHandle(h);
        return 1;
    }

    DWORD lpFlags, outSize, inSize, maxInst;
    if (GetNamedPipeInfo(h, &lpFlags, &outSize, &inSize, &maxInst))
    {
        char msg[96];
        wsprintf(msg, "отделение подключилось (буферы %d/%d байт, экземпляров max %d)",
                 outSize, inSize, maxInst);
        Log("ФИЛИАЛ", msg);
    }
    else
    {
        PrintLastError("GetNamedPipeInfo");
    }

    char  buf[256];
    DWORD n;
    if (ReadFile(h, buf, sizeof(buf) - 1, &n, NULL))
    {
        buf[n] = '\0';
        Log("ФИЛИАЛ", buf);

        char reply[] = "Диспетчер: отчёт принят, отделение на связи.";
        if (!WriteFile(h, reply, lstrlen(reply) + 1, &n, NULL))
            PrintLastError("WriteFile (ответ отделению)");
    }
    else
    {
        PrintLastError("ReadFile (branch pipe)");
    }

    if (!DisconnectNamedPipe(h))
        PrintLastError("DisconnectNamedPipe");
    CloseHandle(h);

    Log("ФИЛИАЛ", "сеанс завершён, канал закрыт");
    return 0;
}

// ============================================================================
//  Банкоматы: почтовый ящик atm -> диспетчер (глава 17)
// ============================================================================

BOOL CreateAtmMailslot()
{
    g_hMailslot = CreateMailslot(ATM_MAILSLOT_NAME, 0, 200, NULL);
    if (g_hMailslot == INVALID_HANDLE_VALUE)
    {
        PrintLastError("CreateMailslot");
        return FALSE;
    }
    return TRUE;
}

BOOL SpawnAtm(int id, int posX, int posY)
{
    char cmdLine[MAX_PATH + 16];
    wsprintf(cmdLine, "\"%s\" atm %d", g_exePath, id);

    char title[32];
    wsprintf(title, "Банкомат №%d", id);

    STARTUPINFO         si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);

    // Собственная, отдельная консоль с заданными положением/размером/
    // заголовком/цветом (глава 10) - каждое поле учитывается ТОЛЬКО при
    // поднятом соответствующем флаге в dwFlags, отсюда столько флагов.
    si.lpTitle         = title;
    si.dwX             = posX;
    si.dwY             = posY;
    si.dwXSize         = 320;
    si.dwYSize         = 160;
    si.dwXCountChars   = 50;
    si.dwYCountChars   = 10;
    si.dwFillAttribute = FOREGROUND_GREEN | FOREGROUND_INTENSITY;
    si.wShowWindow     = SW_SHOWNORMAL;
    si.dwFlags = STARTF_USEPOSITION | STARTF_USESIZE | STARTF_USECOUNTCHARS |
                 STARTF_USEFILLATTRIBUTE | STARTF_USESHOWWINDOW;

    if (!CreateProcess(NULL, cmdLine, NULL, NULL, FALSE,
                        CREATE_NEW_CONSOLE, NULL, NULL, &si, &pi))
    {
        PrintLastError("CreateProcess (atm)");
        return FALSE;
    }
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return TRUE;
}

// Сервер почтового ящика - тот же приём опроса, что в листинге 17.3
// книги: GetMailslotInfo подсказывает размер следующего сообщения и их
// количество, ReadFile читает РОВНО одно сообщение за раз.
DWORD WINAPI MailslotServerThread(LPVOID)
{
    for (;;)
    {
        if (WaitForSingleObject(g_hQuitEvent, 0) == WAIT_OBJECT_0)
            break;

        DWORD nextSize, count;
        if (!GetMailslotInfo(g_hMailslot, NULL, &nextSize, &count, NULL))
            break;   // дескриптор закрыт диспетчером при завершении - выходим тихо

        while (count != 0 && nextSize != MAILSLOT_NO_MESSAGE)
        {
            char* p = new char[nextSize + 1];
            DWORD n;
            if (ReadFile(g_hMailslot, p, nextSize, &n, NULL))
            {
                p[n] = '\0';
                Log("АТМ", p);

                // Свой же формат сообщения "ATM<id>:текст" - разбираем,
                // чтобы понять, какую клетку табло перекрасить и как.
                if (p[0] == 'A' && p[1] == 'T' && p[2] == 'M')
                {
                    int id = atoi(p + 3);
                    if (id >= 1 && id <= ATM_COUNT)
                    {
                        EnterCriticalSection(&g_csLog);
                        lstrcpyn(g_atm[id - 1].lastMsg, p, sizeof(g_atm[id - 1].lastMsg));
                        int len = lstrlen(p);
                        g_atm[id - 1].state = (len > 0 && p[len - 1] == '!') ? 2 : 1;
                        DrawAtmCell(id - 1);
                        LeaveCriticalSection(&g_csLog);
                    }
                }
            }
            delete[] p;

            if (!GetMailslotInfo(g_hMailslot, NULL, &nextSize, &count, NULL))
                break;
        }

        Sleep(150);   // не молотить GetMailslotInfo вхолостую между приходами сообщений
    }

    return 0;
}

// ============================================================================
//  Роль диспетчера целиком (главы 9, 11, 12, 13 - console; 15, 16, 17 - IPC)
// ============================================================================

int RunDispatcherRole()
{
    InitializeCriticalSection(&g_csLog);

    g_hQuitEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    if (g_hQuitEvent == NULL)
    {
        PrintLastError("CreateEvent");
        return 1;
    }

    if (!SetupDispatcherConsole())
        return 1;

    ShowSplash();

    for (int i = 0; i < ATM_COUNT; ++i)
    {
        g_atm[i].state = 0;
        lstrcpy(g_atm[i].lastMsg, "(нет данных)");
    }

    DrawDashboardChrome();
    Log("ДИСПЕТЧЕР", "дашборд поднят, запускаю каналы связи...");

    if (!SpawnAgent())
        Log("ДИСПЕТЧЕР", "датчик нагрузки не запущен (см. код ошибки выше)");

    if (!CreateAtmMailslot())
        Log("ДИСПЕТЧЕР", "почтовый ящик не создан");

    DWORD  dwAgentTid, dwPipeTid, dwMailslotTid;
    HANDLE hAgentThread    = CreateThread(NULL, 0, AgentReaderThread,    NULL, 0, &dwAgentTid);
    HANDLE hPipeThread     = CreateThread(NULL, 0, NamedPipeServerThread, NULL, 0, &dwPipeTid);
    HANDLE hMailslotThread = CreateThread(NULL, 0, MailslotServerThread, NULL, 0, &dwMailslotTid);

    if (hAgentThread == NULL || hPipeThread == NULL || hMailslotThread == NULL)
        PrintLastError("CreateThread (один из потоков IPC)");

    Sleep(300);   // дать потокам открыть каналы, прежде чем звать детей

    int startX = 360;
    for (int i = 0; i < ATM_COUNT; ++i)
    {
        SpawnAtm(i + 1, startX, 80);
        startX += 340;
        Sleep(80);
    }

    SpawnBranch();

    // ---- главный цикл: низкоуровневый ввод консоли (главы 9, 13) ----
    BOOL running = TRUE;
    while (running)
    {
        DWORD wait = WaitForSingleObject(g_hStdIn, 500);
        if (wait == WAIT_TIMEOUT)
            continue;   // просто даём фоновым потокам время поработать
        if (wait != WAIT_OBJECT_0)
        {
            PrintLastError("WaitForSingleObject (hStdIn)");
            break;
        }

        INPUT_RECORD ir;
        DWORD        nRead;
        if (!ReadConsoleInput(g_hStdIn, &ir, 1, &nRead))
        {
            PrintLastError("ReadConsoleInput");
            break;
        }

        switch (ir.EventType)
        {
        case KEY_EVENT:
            if (ir.Event.KeyEvent.bKeyDown)
            {
                char ch = ir.Event.KeyEvent.uChar.AsciiChar;
                if (ch == 'q' || ch == 'Q')
                {
                    running = FALSE;
                }
                else if (ch == 'c' || ch == 'C')
                {
                    EnterCriticalSection(&g_csLog);
                    COORD c;
                    c.X = 0; c.Y = (SHORT)LOG_TOP;
                    DWORD written;
                    FillConsoleOutputCharacter(g_hStdOut, ' ',
                        BUF_COLS * (LOG_BOTTOM - LOG_TOP + 1), c, &written);
                    g_logRow = LOG_TOP;
                    LeaveCriticalSection(&g_csLog);
                    Log("ДИСПЕТЧЕР", "журнал очищен оператором");
                }
            }
            break;

        case MOUSE_EVENT:
            if ((ir.Event.MouseEvent.dwButtonState & FROM_LEFT_1ST_BUTTON_PRESSED) &&
                ir.Event.MouseEvent.dwEventFlags == 0 &&
                ir.Event.MouseEvent.dwMousePosition.Y == ROW_BOARD)
            {
                int idx = ir.Event.MouseEvent.dwMousePosition.X / CELL_WIDTH;
                if (idx >= 0 && idx < ATM_COUNT)
                    Log("ТАБЛО", g_atm[idx].lastMsg);
            }
            break;

        case WINDOW_BUFFER_SIZE_EVENT:
            Log("СИСТЕМА", "окно консоли изменило размер");
            break;

        case FOCUS_EVENT:
        case MENU_EVENT:
            break;   // игнорируем - глава 9 явно отмечает, что это ответственность системы

        default:
            Log("СИСТЕМА", "неизвестный тип события ввода");
            break;
        }
    }

    Log("ДИСПЕТЧЕР", "получена команда закрытия, останавливаю каналы...");
    SetEvent(g_hQuitEvent);

    // NamedPipeServerThread и MailslotServerThread сами замечают
    // g_hQuitEvent между операциями (мэйлслот - раз в ~150мс через свой
    // опрос; именованный канал к этому моменту уже отработал одно
    // соединение и вышел). AgentReaderThread - другой случай: он стоит в
    // БЕЗУСЛОВНОМ блокирующем ReadFile и может законно ждать agent'а ещё
    // несколько секунд, а событие внутри цикла не проверяет. Единственный
    // доступный в главах 9-17 способ прервать это ожидание - закрыть
    // дескриптор, на котором поток заблокирован: для каналов это на
    // практике действительно расталкивает висящий ReadFile (возвращает
    // ошибку), но строго говоря это приём "с краю" учебника, не описанный
    // в этих главах явно - поэтому закрываем только этот, самый нужный,
    // дескриптор здесь, а не все три.
    CloseHandle(g_hAgentRead);

    // Таймаут 3000, не INFINITE: если оператор нажал Q ДО того, как
    // branch успел подключиться, NamedPipeServerThread всё ещё стоит в
    // ConnectNamedPipe (у синхронного вызова нет параметра таймаута) - в
    // этом редком случае ждать его вечно смысла нет, программа всё равно
    // корректно завершится, просто этот один поток не присоединится
    // явно (ОС снимает все потоки при выходе из main() в любом случае).
    HANDLE waitThese[3];
    waitThese[0] = hAgentThread;
    waitThese[1] = hPipeThread;
    waitThese[2] = hMailslotThread;
    WaitForMultipleObjects(3, waitThese, TRUE, 3000);

    CloseHandle(g_hMailslot);   // поток уже вышел сам (см. комментарий выше), закрываем следом
    CloseHandle(hAgentThread);
    CloseHandle(hPipeThread);
    CloseHandle(hMailslotThread);
    CloseHandle(g_hQuitEvent);
    DeleteCriticalSection(&g_csLog);

    SetConsoleTextAttribute(g_hStdOut, FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);
    cout << endl << "Диспетчерская закрыта. До связи." << endl;

    return 0;
}

// ============================================================================
//  Роль отделения - клиент именованного канала (глава 16)
// ============================================================================

int RunBranchRole()
{
    // Клиент на этом же компьютере открывает канал через "." - значит
    // получает поток, а не сообщения (глава 16, "режим сообщений на
    // клиенте"): для сообщений нужно полное имя компьютера. Здесь и
    // потока достаточно, потому что в этом обмене ровно одно сообщение
    // в каждую сторону подряд.
    if (!WaitNamedPipe(BRANCH_PIPE_NAME, 5000))
    {
        cout << "Отделение: WaitNamedPipe failed, диспетчер не отвечает, код "
             << GetLastError() << endl;
        return GetLastError();
    }

    HANDLE h = CreateFile(BRANCH_PIPE_NAME, GENERIC_READ | GENERIC_WRITE,
                           FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
                           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE)
    {
        cout << "Отделение: CreateFile failed, код " << GetLastError() << endl;
        return GetLastError();
    }

    char  report[] = "Отделение №2: смена закрыта, касса сходится, тревог не было.";
    DWORD n;
    if (!WriteFile(h, report, lstrlen(report) + 1, &n, NULL))
    {
        cout << "Отделение: WriteFile failed, код " << GetLastError() << endl;
        CloseHandle(h);
        return GetLastError();
    }
    cout << "Отделение: отчёт отправлен диспетчеру." << endl;

    // PeekNamedPipe - смотрим, сколько байт ответа уже пришло, НЕ забирая
    // их из канала (глава 16), прежде чем читать по-настоящему.
    Sleep(150);   // дать диспетчеру время ответить
    DWORD avail = 0;
    if (PeekNamedPipe(h, NULL, 0, NULL, &avail, NULL))
        cout << "Отделение: в канале уже " << avail << " байт ответа." << endl;

    char buf[256];
    if (ReadFile(h, buf, sizeof(buf) - 1, &n, NULL))
    {
        buf[n] = '\0';
        cout << "Отделение: получен ответ - " << buf << endl;
    }
    else
    {
        cout << "Отделение: ReadFile (ответ) failed, код " << GetLastError() << endl;
    }

    CloseHandle(h);
    return 0;
}

// ============================================================================
//  Роль банкомата - клиент почтового ящика (глава 17)
// ============================================================================

int RunAtmRole(int id)
{
    HANDLE hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
    SetConsoleTextAttribute(hStdOut, FOREGROUND_GREEN | FOREGROUND_INTENSITY);

    cout << "Банкомат #" << id << " запущен, отправляю сигналы в диспетчерскую..." << endl;

    HANDLE h = CreateFile(ATM_MAILSLOT_NAME, GENERIC_WRITE, FILE_SHARE_READ,
                           NULL, OPEN_EXISTING, 0, NULL);
    if (h == INVALID_HANDLE_VALUE)
    {
        cout << "Банкомат #" << id << ": CreateFile (mailslot) failed, код "
             << GetLastError() << endl;
        return GetLastError();
    }

    // Третье сообщение - тревожное (кончается на '!'), диспетчер по этому
    // же признаку красит клетку табло красным - см. MailslotServerThread.
    const char* events[3];
    events[0] = "статус: в норме";
    events[1] = "выдана купюрная лента";
    events[2] = "низкий остаток кассет!";

    for (int i = 0; i < 3; ++i)
    {
        char msg[80];
        wsprintf(msg, "ATM%d:%s", id, events[i]);

        DWORD n;
        if (!WriteFile(h, msg, lstrlen(msg) + 1, &n, NULL))
        {
            cout << "Банкомат #" << id << ": WriteFile failed, код " << GetLastError() << endl;
            break;
        }
        cout << "Банкомат #" << id << ": отправлено - " << events[i] << endl;
        Sleep(400 + id * 100);
    }

    CloseHandle(h);
    cout << "Банкомат #" << id << ": сеанс окончен." << endl;
    Sleep(2500);   // окно видно ещё немного, прежде чем закроется вместе с процессом
    return 0;
}

// ============================================================================
//  Роль датчика нагрузки - клиент анонимного канала (глава 15)
//  DETACHED_PROCESS: своей консоли нет и не будет, поэтому здесь нет ни
//  одного cout - только работа с каналом и тихий выход.
// ============================================================================

void RunAgentRole(HANDLE hWrite)
{
    SensorReading r;

    for (int i = 0; i < AGENT_READINGS; ++i)
    {
        r.load = 10 + (GetTickCount() % 85);   // условная нагрузка, 10-94%
        r.tick = GetTickCount();

        DWORD n;
        if (!WriteFile(hWrite, &r, sizeof(r), &n, NULL))
            break;   // диспетчер закрыл канал (завершается) - тихо выходим

        Sleep(500);
    }

    CloseHandle(hWrite);
}

// ============================================================================
//  main() - выбор роли по argv[1] (одна программа - четыре роли)
// ============================================================================

int main(int argc, char* argv[])
{
    BuildExePath();

    if (argc >= 3 && lstrcmpi(argv[1], "agent") == 0)
    {
        HANDLE hWrite = (HANDLE)(INT_PTR)atoi(argv[2]);
        RunAgentRole(hWrite);
        return 0;
    }

    if (argc >= 2 && lstrcmpi(argv[1], "branch") == 0)
        return RunBranchRole();

    if (argc >= 3 && lstrcmpi(argv[1], "atm") == 0)
        return RunAtmRole(atoi(argv[2]));

    return RunDispatcherRole();
}
```

Не скомпилировано по-настоящему (нет Windows/MSVC в этом окружении) -
проверено по документации и логике API: каждая сигнатура и константа
сверены построчно с lectures/09-17 и reference/09-17, а рабочие шаблоны
для CreatePipe/DuplicateHandle (15.2), CreateNamedPipe/ConnectNamedPipe
(16.3), клиента канала (16.4), CreateMailslot/GetMailslotInfo (17.3) и
клиента ящика (17.4) взяты именно из листингов книги, не придуманы заново.
1031 строка (требование - больше 900).

Механизм: что откуда и зачем

Сюжет: диспетчерская поднимает дашборд на консоли и запускает три вида
дочерних процессов - датчик нагрузки (анонимный канал), одно отделение
(именованный канал) и несколько банкоматов (почтовый ящик) - каждый со
своим каналом связи не случайно, а потому что у каждого свой профиль
задачи (см. карточку глав 9-17 внизу самого кода).

Глава 9 (структура консольного приложения, теория) - без отдельного кода,
потому что она везде: INPUT_RECORD/KEY_EVENT_RECORD/MOUSE_EVENT_RECORD/
WINDOW_BUFFER_SIZE_RECORD из этой главы - это именно то, что разбирает
switch в главном цикле диспетчера; CHAR_INFO - именно то, чем оперируют
FillConsoleOutputAttribute/WriteConsoleOutputCharacter в DrawAtmCell.
FOCUS_EVENT и MENU_EVENT явно игнорируются - глава прямо говорит, что это
ответственность системы, а не приложения.

Глава 10 (работа с консолью) - три способа получить консоль для потомка,
показаны все три сразу, по одному на роль: agent получает DETACHED_PROCESS
(нет консоли вообще - она ему без надобности), branch не получает никакого
специального флага (по умолчанию делит консоль родителя - нарочно, чтобы
показать именно это поведение), atm получает CREATE_NEW_CONSOLE с полным
набором полей STARTUPINFO (заголовок, положение, размер, цвет) - каждое
поле реально применяется только при своём флаге в dwFlags, отсюда список
из пяти флагов в SpawnAtm.

Глава 11 (окно консоли) - GetConsoleWindow/GetConsoleTitle/SetConsoleTitle/
GetLargestConsoleWindowSize/SetConsoleWindowInfo - все пять в
SetupDispatcherConsole. Порядок "сначала буфер, потом окно" - прямое
следствие правила главы: окно никогда не больше буфера.

Глава 12 (буфер экрана) - CreateConsoleScreenBuffer + SetConsoleActiveScreenBuffer
- заставка при старте (двойная буферизация: кадр готовится в неактивном
буфере, потом мгновенно показывается); SetConsoleScreenBufferSize -
буфер диспетчера сделан больше окна нарочно (100x40 холст, 90x25 окно), это
и есть демонстрация того, что буфер - это весь холст, а окно - только
видимая часть; SetConsoleCursorInfo - курсор уменьшен и включён; четыре
функции атрибутов главы (SetConsoleTextAttribute/FillConsoleOutputAttribute)
красят табло и заголовок.

Глава 13 (ввод-вывод на консоль) - высокий уровень (WriteConsole) выводит
все надписи дашборда; низкий уровень вывода (WriteConsoleOutputCharacter,
FillConsoleOutputCharacter) рисует клетки табло и чистит строки журнала;
низкий уровень ввода (ReadConsoleInput в цикле WaitForSingleObject(hStdIn)
-> switch по EventType) - тот же приём, что в примере книги про KeyEventProc/
MouseEventProc, только вместо печати структуры целиком - обработка команд
оператора (Q, C, клик по табло); SetConsoleMode/GetConsoleMode отключают
построчный ввод и эхо, включают события окна и мыши; ScrollConsoleScreenBuffer
прокручивает именно область журнала (через lpClipRectangle), а не весь
буфер, как в примере книги (GoToNewLine).

Глава 14 (передача данных, теория) - без отдельного кода (в главе нет
функций Win32), но её словарь применён к каждому из трёх реальных каналов
явно, в комментарии в самом начале файла - направление, поток/сообщения,
синхронность, буферизация, топология, адресация для каждого канала
расписаны по пунктам главы, а не абстрактно.

Глава 15 (анонимные каналы) - CreatePipe создаёт канал agent -> диспетчер;
DuplicateHandle с наследуемым дубликатом и закрытием оригинала - ровно
листинг 15.2; хендл передан через командную строку (один из двух способов
явной передачи, которые разбирает глава); формат передачи - поток сырых
байтов структуры SensorReading, не текст через cout (глава прямо
предупреждает про несовпадение форматов чтения/записи); обмен синхронный
- поэтому чтение в отдельном потоке (AgentReaderThread), а не в главном
цикле.

Глава 16 (именованные каналы) - CreateNamedPipe с PIPE_ACCESS_DUPLEX и
PIPE_TYPE_MESSAGE; ConnectNamedPipe в отдельном потоке (глава прямо
советует так делать, раз вызов блокирует); DisconnectNamedPipe в конце
сеанса; на стороне клиента - WaitNamedPipe + CreateFile (листинг 16.4
дословно, включая FILE_SHARE_READ | FILE_SHARE_WRITE) и PeekNamedPipe для
проверки, сколько байт ответа уже пришло, не забирая их; GetNamedPipeInfo
читает параметры подключившегося экземпляра.

Глава 17 (почтовые ящики) - CreateMailslot на диспетчере, CreateFile с
GENERIC_WRITE на каждом банкомате (листинг 17.4); сервер читает тем же
приёмом опроса, что листинг 17.3 книги - GetMailslotInfo подсказывает
размер и количество сообщений, ReadFile читает ровно одно сообщение за
раз; несколько банкоматов пишут в один и тот же ящик - классическая для
этого механизма топология "многие к одному".

Как это будет выглядеть при запуске (по логике, не проверенный вывод)

Реальный порядок строк в журнале будет каждый раз немного разным - три
потока диспетчера и несколько независимых процессов пишут не по
расписанию, а как получится у планировщика (та же логика, что в task2.md).
Но по замыслу программы: сначала на полторы секунды появляется синяя
заставка "БАНК ЫРЫС", затем дашборд с пустым табло (три серые клетки "...")
и нулевой нагрузкой; почти сразу открываются три отдельных окошка
"Банкомат №1/2/3" в новых консолях, каждое печатает у себя три строки и
закрывается через несколько секунд, а в журнале диспетчера тем временем
появляются строки вида "[АТМ] ATM1:статус: в норме" - клетка АТМ1 становится
зелёной "ok"; после третьего сообщения от каждого банкомата ("низкий
остаток кассет!") соответствующая клетка становится красной "!!!". Раз в
полсекунды в журнале появляется "[ДАТЧИК] показание: нагрузка NN%", а
строка "Нагрузка диспетчерской" вверху обновляется тем же числом. Через
секунду-другую отделение branch подключается к именованному каналу -
в САМОЙ консоли диспетчера (не в новом окне) неожиданно появляются две
строки "Отделение: отчёт отправлен диспетчеру." и "Отделение: получен
ответ - ...", прямо поверх дашборда - это и есть демонстрация главы 10,
не ошибка. Клик мышью по любой клетке табло выводит в журнал её последнее
сообщение целиком; клавиша C чистит журнал, оставляя табло на месте;
клавиша Q останавливает все три потока-читателя и печатает "Диспетчерская
закрыта. До связи." уже обычным cout под дашбордом.

Пояснение к карточке главы 15 в шапке файла: способ передачи дескриптора
через STARTUPINFO.hStdInput/hStdOutput (второй способ явной передачи из
главы 15, тесно связанный с перенаправлением стандартного ввода-вывода
из главы 10) в этом проекте не использован - агент передаётся только
через командную строку (листинг 15.2), чтобы не усложнять и без того
многосоставной сценарий четвёртым вариантом передачи хендла; сам способ
разобран отдельно в lectures/15-anonimnye-kanaly.md.
