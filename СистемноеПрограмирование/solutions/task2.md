Задача 2 - мини-проект "Банк Ырыс": один день из жизни отделения

Идея

Вместо набора несвязанных демонстраций - один связный сценарий: отделение банка открывается на смену, пять кассиров (потоков) обслуживают операции, менеджер (главный поток) следит за порядком и закрывает смену звонком, а в конце дня открывается процесс-отчёт. У каждого механизма из глав 1-8 в этом сценарии есть понятная причина находиться именно там, где он есть - ничего не добавлено просто "для галочки".

Единственная оговорка про заголовки: кроме windows.h и iostream.h понадобился ещё stdlib.h - ради rand()/srand() для случайности в сумме и виде операций. Это тот же самый случай, что в главе 8: там книга добавляет math.h ради abs() в примере с тупиками - без стандартной библиотеки C генератор случайных чисел не собрать, и это не Win32-специфичная вещь, а базовый C. Если для сдачи нужно строго два заголовка - можно убрать rand() и сделать суммы/действия по фиксированному циклу (например amount = 50 + (i * 37) % 150, action = i % 3), программа при этом не изменится по сути.

Код

```c
#include <windows.h>
#include <iostream>
#include <stdlib.h>   // rand()/srand() - см. оговорку выше

const int  TELLER_COUNT          = 5;    // всего кассиров
const int  WINDOW_SLOTS          = 3;    // окошек обслуживания меньше, чем кассиров
const int  TXN_PER_TELLER        = 6;    // операций на одного кассира за смену
const long VAULT_ALARM_THRESHOLD = 200;  // порог тревоги по остатку в сейфе

// ---------- Общие ресурсы отделения (глава 1: у каждого объекта ниже - свой HANDLE,
//            "номерок в гардеробе", а не сам объект) ----------

CRITICAL_SECTION g_csLog;            // защищает вывод в консоль (6.1)
HANDLE g_hVaultMutex;                // защищает g_vaultBalance, именованный (6.3)
HANDLE g_hWindowSlots;               // семафор на WINDOW_SLOTS окошек (6.5)
HANDLE g_hClosingBell;               // событие с ручным сбросом - закрытие смены (6.4)

long  g_vaultBalance      = 1000;             // общий сейф отделения
long  g_accountBalance[2] = { 500, 500 };     // два клиентских счёта
CRITICAL_SECTION g_csAccount[2];              // у каждого счёта - своя секция (6.1)

LONG g_transactionsTotal = 0;   // атомарный счётчик обслуженных операций (7.4)
LONG g_alarmRaised       = 0;   // атомарный флаг "тревога уже поднята" (7.3)

// ---------- Текст ошибки Win32 (3.6, тот же приём, что CoutErrorMessage) ----------

void PrintLastError(const char* what)
{
    DWORD  err = GetLastError();
    LPVOID lpMsgBuf;

    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL, err, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPTSTR)&lpMsgBuf, 0, NULL);

    EnterCriticalSection(&g_csLog);
    cout << "[ОШИБКА] " << what << " (код " << err << "): " << (char*)lpMsgBuf << endl;
    LeaveCriticalSection(&g_csLog);

    LocalFree(lpMsgBuf);
}

// ---------- Перевод между двумя счетами БЕЗ ТУПИКА (8.5, стратегия 3 - линейное
//            упорядочивание ресурсов по типу) ----------
//
// Наивный вариант (НЕ используется, здесь только для объяснения): брать критическую
// секцию счёта-источника, потом счёта-получателя, в порядке параметров from/to. Тогда
// поток, переводящий 0 -> 1, взял бы cs[0] и ждал cs[1]; поток, переводящий 1 -> 0
// ОДНОВРЕМЕННО, взял бы cs[1] и ждал cs[0] - оба ждут друг друга вечно, ровно тот же
// тупик, что для cs1/cs2 в главе 8.1. Решение ниже захватывает обе секции СТРОГО по
// возрастанию номера счёта, независимо от направления перевода - тупик после этого
// невозможен: если один поток уже держит секцию с меньшим номером, второй до неё
// просто не дойдёт первой и подождёт снаружи, как обычно, без циклического ожидания.

BOOL Transfer(int from, int to, long amount)
{
    int first  = (from < to) ? from : to;
    int second = (from < to) ? to   : from;

    EnterCriticalSection(&g_csAccount[first]);
    EnterCriticalSection(&g_csAccount[second]);

    BOOL ok = FALSE;
    if (g_accountBalance[from] >= amount)
    {
        g_accountBalance[from] -= amount;
        g_accountBalance[to]   += amount;
        ok = TRUE;
    }

    LeaveCriticalSection(&g_csAccount[second]);
    LeaveCriticalSection(&g_csAccount[first]);
    return ok;
}

// ---------- Сейф - через именованный мьютекс (6.3) ----------

void VaultDeposit(long amount)
{
    WaitForSingleObject(g_hVaultMutex, INFINITE);
    g_vaultBalance += amount;
    ReleaseMutex(g_hVaultMutex);
}

BOOL VaultWithdraw(long amount)
{
    WaitForSingleObject(g_hVaultMutex, INFINITE);
    BOOL ok = FALSE;
    if (g_vaultBalance >= amount)
    {
        g_vaultBalance -= amount;
        ok = TRUE;
    }
    long balanceNow = g_vaultBalance;   // снимок остатка, ещё держим мьютекс
    ReleaseMutex(g_hVaultMutex);

    // Тревога поднимается РОВНО ОДИН раз, даже если несколько кассиров заметят
    // низкий остаток "одновременно" - условная атомарная замена (7.3): меняем
    // g_alarmRaised с 0 на 1 только тому потоку, который первым застал его в 0.
    if (balanceNow < VAULT_ALARM_THRESHOLD)
    {
        if (InterlockedCompareExchange((PVOID*)&g_alarmRaised, (PVOID)1, (PVOID)0) == (PVOID)0)
        {
            EnterCriticalSection(&g_csLog);
            cout << "!!! ТРЕВОГА: остаток в сейфе ниже " << VAULT_ALARM_THRESHOLD
                 << " (сейчас " << balanceNow << ") !!!" << endl;
            LeaveCriticalSection(&g_csLog);
        }
    }
    return ok;
}

// ---------- Кассир (3.2: функция потока) ----------

DWORD WINAPI TellerThread(LPVOID lpParam)
{
    int id = (int)(INT_PTR)lpParam;

    for (int i = 0; i < TXN_PER_TELLER; ++i)
    {
        // Не блокируясь, проверяем звонок о закрытии - тот же приём dwMilliseconds=0,
        // что в lab-solutions/labka 3.md.
        if (WaitForSingleObject(g_hClosingBell, 0) == WAIT_OBJECT_0)
        {
            EnterCriticalSection(&g_csLog);
            cout << "Кассир " << id << ": услышал звонок о закрытии, ухожу." << endl;
            LeaveCriticalSection(&g_csLog);
            break;
        }

        // Окошко обслуживания - ограниченный ресурс, семафор (6.5).
        WaitForSingleObject(g_hWindowSlots, INFINITE);

        int  action = rand() % 3;
        long amount = 50 + rand() % 150;

        if (action == 0)
        {
            VaultDeposit(amount);
            EnterCriticalSection(&g_csLog);
            cout << "Кассир " << id << ": внёс в сейф " << amount << endl;
            LeaveCriticalSection(&g_csLog);
        }
        else if (action == 1)
        {
            BOOL ok = VaultWithdraw(amount);
            EnterCriticalSection(&g_csLog);
            cout << "Кассир " << id << ": "
                 << (ok ? "снял из сейфа " : "снятие отклонено, не хватает средств: ")
                 << amount << endl;
            LeaveCriticalSection(&g_csLog);
        }
        else
        {
            int from = id % 2;
            int to   = 1 - from;
            BOOL ok = Transfer(from, to, amount / 2);
            EnterCriticalSection(&g_csLog);
            cout << "Кассир " << id << ": перевод со счёта " << from << " на счёт " << to
                 << " (" << (amount / 2) << ") - " << (ok ? "выполнен" : "отклонён") << endl;
            LeaveCriticalSection(&g_csLog);
        }

        InterlockedIncrement(&g_transactionsTotal);   // 7.4

        ReleaseSemaphore(g_hWindowSlots, 1, NULL);     // освобождаем окошко

        Sleep(30 + rand() % 70);
    }

    return 0;
}

int main()
{
    srand((unsigned)GetTickCount());   // GetTickCount - тоже Win32 API, из windows.h

    cout << "======================================" << endl;
    cout << "  Банк \"Ырыс\", отделение №1 - смена дня" << endl;
    cout << "======================================" << endl << endl;

    InitializeCriticalSection(&g_csLog);
    InitializeCriticalSection(&g_csAccount[0]);
    InitializeCriticalSection(&g_csAccount[1]);

    g_hVaultMutex = CreateMutex(NULL, FALSE, "Bank_Iris_VaultMutex");
    if (g_hVaultMutex == NULL) { PrintLastError("CreateMutex"); return 1; }

    g_hWindowSlots = CreateSemaphore(NULL, WINDOW_SLOTS, WINDOW_SLOTS, NULL);
    if (g_hWindowSlots == NULL) { PrintLastError("CreateSemaphore"); return 1; }

    g_hClosingBell = CreateEvent(NULL, TRUE, FALSE, NULL);   // ручной сброс, несигнально
    if (g_hClosingBell == NULL) { PrintLastError("CreateEvent"); return 1; }

    // Рабочие часы - повышенный приоритет процесса (4.7-4.8).
    HANDLE hProcess  = GetCurrentProcess();   // псевдодескриптор (4.6)
    DWORD  oldClass  = GetPriorityClass(hProcess);
    SetPriorityClass(hProcess, ABOVE_NORMAL_PRIORITY_CLASS);
    cout << "Приоритет процесса: было " << oldClass
         << ", стало " << GetPriorityClass(hProcess)
         << " (часы работы - выше обычного)." << endl << endl;

    // Пять кассиров (3.2). Последний - стажёр, создан подвешенным (3.4).
    HANDLE hTellers[TELLER_COUNT];
    DWORD  dwTellerId[TELLER_COUNT];

    for (int i = 0; i < TELLER_COUNT; ++i)
    {
        DWORD flags = (i == TELLER_COUNT - 1) ? CREATE_SUSPENDED : 0;
        hTellers[i] = CreateThread(NULL, 0, TellerThread, (LPVOID)(INT_PTR)i, flags, &dwTellerId[i]);
        if (hTellers[i] == NULL) { PrintLastError("CreateThread"); return 1; }
    }
    cout << "Кассир " << (TELLER_COUNT - 1) << " - стажёр, создан в подвешенном состоянии." << endl;

    // Дубликат дескриптора с урезанными правами (4.5) - только ждать, не завершать.
    HANDLE hRestricted;
    if (DuplicateHandle(GetCurrentProcess(), hTellers[0],
                         GetCurrentProcess(), &hRestricted,
                         SYNCHRONIZE, FALSE, 0))
    {
        if (!TerminateThread(hRestricted, 0))
            PrintLastError("TerminateThread на урезанном дескрипторе (так и должно быть)");
        CloseHandle(hRestricted);
    }

    // Стажёра "обучают", потом выпускают в зал (3.4: ResumeThread).
    Sleep(150);
    ResumeThread(hTellers[TELLER_COUNT - 1]);
    cout << "Стажёр обучен и возобновлён." << endl << endl;

    // Смена идёт.
    Sleep(1500);

    // Звонок о закрытии - оповещает всех потоков разом (6.4: событие с ручным сбросом).
    SetEvent(g_hClosingBell);
    cout << endl << "Звенит звонок о закрытии." << endl;

    // Ждём, пока ВСЕ кассиры закончат (6.2: WaitForMultipleObjects, bWaitAll=TRUE).
    WaitForMultipleObjects(TELLER_COUNT, hTellers, TRUE, INFINITE);

    cout << endl << "======================================" << endl;
    cout << "Смена закончена." << endl;
    cout << "Обслужено операций: " << g_transactionsTotal << endl;
    cout << "Остаток в сейфе: " << g_vaultBalance << endl;
    cout << "Счёт 0: " << g_accountBalance[0] << ", счёт 1: " << g_accountBalance[1] << endl;
    cout << "======================================" << endl << endl;

    for (int i = 0; i < TELLER_COUNT; ++i)
        CloseHandle(hTellers[i]);

    // Конец дня - процесс-отчёт с пониженным приоритетом (4.2-4.3, 4.7-4.8).
    STARTUPINFO         si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);

    char cmdLine[] = "notepad.exe";
    if (CreateProcess(NULL, cmdLine, NULL, NULL, FALSE,
                       BELOW_NORMAL_PRIORITY_CLASS, NULL, NULL, &si, &pi))
    {
        cout << "Открываю блокнот для менеджера (процесс с пониженным приоритетом)." << endl;
        WaitForSingleObject(pi.hProcess, INFINITE);
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
    }
    else
    {
        PrintLastError("CreateProcess (notepad.exe)");
    }

    CloseHandle(g_hVaultMutex);
    CloseHandle(g_hWindowSlots);
    CloseHandle(g_hClosingBell);
    DeleteCriticalSection(&g_csLog);
    DeleteCriticalSection(&g_csAccount[0]);
    DeleteCriticalSection(&g_csAccount[1]);

    return 0;
}
```

Не скомпилировано по-настоящему (нет Windows/MSVC в этом окружении) - проверено по документации и логике API, каждая сигнатура и константа сверены построчно с уже написанными конспектами lectures/01-08. Как и в примере из главы 3, для сборки как многопоточного приложения в Visual C++ нужно поставить в настройках проекта Debug Multithreaded (или Multithreaded для release) - без этого возможны проблемы с библиотекой времени выполнения C.

Механизм: что откуда и зачем

Сюжет простой: отделение банка открывается на смену, пять кассиров работают параллельно, менеджер (главный поток) в конце звонит в колокольчик и ждёт, пока все закончат, а в конце дня открывает отчёт. У каждого механизма курса - понятная роль в этом сюжете, а не случайное место в коде:

Глава 1 (объекты и дескрипторы) - в коде нет отдельной демонстрации, потому что она везде: каждый CreateMutex/CreateSemaphore/CreateEvent/CreateThread/CreateProcess возвращает HANDLE - тот самый "номерок", а не сам объект, и каждый такой номерок в конце явно закрывается через CloseHandle/DeleteCriticalSection.

Глава 2 (потоки и процессы, теория) - тоже без отдельного кода: пять кассиров - это ровно демонстрация того, что несколько потоков ОДНОГО процесса напрямую делят общую память (g_vaultBalance, g_accountBalance) и поэтому нуждаются в синхронизации, а не в дорогих межпроцессных механизмах.

Глава 3 (потоки в Windows) - CreateThread создаёт пятерых кассиров; последний создан с CREATE_SUSPENDED и "обучается", пока не позовут ResumeThread; PrintLastError - тот же приём, что CoutErrorMessage из 3.6, только адаптирован под универсальное сообщение "что именно не получилось".

Глава 4 (процессы в Windows) - GetCurrentProcess/SetPriorityClass поднимают приоритет отделения на рабочие часы; DuplicateHandle с правом только SYNCHRONIZE показывает, что урезанный дескриптор реально не даёт TerminateThread сработать (попытка нарочно проваливается - это не баг, это и есть демонстрация); в конце CreateProcess запускает Notepad с BELOW_NORMAL_PRIORITY_CLASS как "отчёт для менеджера", WaitForSingleObject дожидается его закрытия.

Глава 5 (синхронизация, теория) - тоже без отдельного кода: именно это глава объясняет, зачем вообще в главе 6 четыре разных механизма, а не один - в проекте использованы три из них не случайно, а по тем же причинам, что разбирались в теории (взаимное исключение для общих переменных, событие для оповещения, семафор для ограниченного пула).

Глава 6 (синхронизация потоков в Windows) - CRITICAL_SECTION защищает вывод в консоль и счета (быстро, всё в одном процессе); именованный мьютекс защищает сейф (продемонстрирован как ресурс, который в реальной системе с несколькими процессами-отделениями мог бы делиться между ними по имени); семафор на WINDOW_SLOTS=3 ограничивает, сколько кассиров одновременно "у окошка", хотя кассиров пятеро; событие с ручным сбросом - звонок о закрытии, оповещающий всех потоков разом, а не по одному.

Глава 7 (атомарные операции) - InterlockedIncrement ведёт счётчик обслуженных операций без всякой блокировки; InterlockedCompareExchange гарантирует, что тревога о низком балансе выводится РОВНО один раз, даже если несколько кассиров заметят низкий остаток в перекрывающихся по времени вызовах VaultWithdraw.

Глава 8 (тупики) - функция Transfer специально написана так, чтобы избежать классического тупика из 8.1 (два потока берут два общих ресурса в противоположном порядке): здесь обе критические секции счетов захватываются строго по возрастанию номера счёта, независимо от направления перевода - это и есть стратегия 3 из 8.5 (линейное упорядочивание ресурсов по типу), применённая не абстрактно, а на конкретной паре ресурсов.

Как это будет выглядеть при запуске (по логике, не проверенный вывод)

Реальный порядок строк в консоли будет каждый раз разным - пять потоков пишут не по расписанию, а как получится у планировщика, это и есть весь смысл главы 2. Но по логике программы гарантировано: ни одна строка от разных кассиров не влезет ВНУТРЬ другой (критическая секция g_csLog не даёт), стажёр появится в логе с задержкой около 150мс после старта остальных, после звонка о закрытии кассиры перестанут начинать новые операции (хотя недозавершённую могут доделать), сумма "обслужено операций" будет не больше TELLER_COUNT * TXN_PER_TELLER = 30 и не меньше того, что успели сделать до звонка, а остаток на счетах 0 и 1 всегда останется согласованным (сумма списаний равна сумме зачислений, потому что Transfer атомарна относительно обеих критических секций).



======================================
  Банк "Ырыс", отделение №1 - смена дня
======================================

Приоритет процесса: было 32, стало 32768 (часы работы - выше обычного).

Кассир 4 - стажёр, создан в подвешенном состоянии.
[ОШИБКА] TerminateThread на урезанном дескрипторе (так и должно быть) (код 5): Access is denied.

Стажёр обучен и возобновлён.

Кассир 0: внёс в сейф 120
Кассир 1: снял из сейфа 80
Кассир 2: перевод со счёта 0 на счёт 1 (45) - выполнен
Кассир 3: внёс в сейф 95
Кассир 0: снял из сейфа 60
Кассир 1: перевод со счёта 1 на счёт 0 (70) - выполнен
Кассир 2: внёс в сейф 110
Кассир 4: снял из сейфа 50
Кассир 3: перевод со счёта 1 на счёт 0 (30) - отклонён
Кассир 0: внёс в сейф 140
...
!!! ТРЕВОГА: остаток в сейфе ниже 200 (сейчас 180) !!!
...
Кассир 1: услышал звонок о закрытии, ухожу.
Кассир 0: услышал звонок о закрытии, ухожу.

Звенит звонок о закрытии.

======================================
Смена закончена.
Обслужено операций: 18
Остаток в сейфе: 850
Счёт 0: 620, счёт 1: 380
======================================

Открываю блокнот для менеджера (процесс с пониженным приоритетом).
