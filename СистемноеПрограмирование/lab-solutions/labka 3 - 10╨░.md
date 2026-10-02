Лабораторная работа 3-4 - Синхронизация процессов и потоков в ОС Windows

Вариант 10-А. Критическая секция (защита вывода) и событие с ручным сбросом (сигнал остановки)

Вариант 10 (из открытого списка в labka 3.docx): два потока, один ищет
числа Фибоначчи, второй простые числа, оба выводят результат на экран,
после остановки показать, сколько чисел каждого вида нашли.

Логика потоков во всех вариантах 10-А, 10-Б, 10-В, 10-Г одна и та же:
через 3 секунды главный поток останавливает оба потока, затем печатает
счётчики. Меняется только примитив синхронизации.

Почему в этом варианте выбраны именно Critical Section и Event

Оба потока (Фибоначчи и простые числа) не делят между собой никакие
данные - каждый считает своё. Единственный общий ресурс - консоль
(cout), в неё пишут оба потока, и без защиты строки могут перемешаться
посимвольно. Для защиты именно внутрипроцессного ресурса, без выхода за
пределы одного процесса, книга прямо рекомендует Critical Section как
более быстрый вариант (стр. 115) - мьютекс тут был бы избыточен, его
смысл в первую очередь в синхронизации МЕЖДУ процессами.

Второе, что нужно - как из главного потока сказать обоим рабочим
потокам "хватит, остановитесь". Это классическая задача оповещения
(6.4), то есть Event, а не Mutex/Semaphore (те не про оповещение, а про
взаимоисключение/ограничение доступа). Взят Event с ручным сбросом
(bManualReset=TRUE): после SetEvent он остаётся сигнальным навсегда, и
оба потока увидят сигнал на следующей же проверке, не важно, в какой
момент каждый из них сейчас находится в своём цикле.

Семафор в этом варианте не нужен вообще - ему нет ограниченного пула
ресурсов, к которому идёт доступ больше чем одним потоком одновременно
(семафор был бы нужен, например, если бы N потоков боролись за доступ к
5 файловым дескрипторам из пула).

Остальные примитивы (мьютекс, семафор, событие с автосбросом) показаны в
файлах labka 3 - 10б.md, labka 3 - 10в.md, labka 3 - 10г.md.

Решение на Win32 API

Мысль по коду: оба потока в цикле проверяют, не пришёл ли сигнал
остановки (WaitForSingleObject с интервалом 0 - книга прямо говорит,
что при dwMilliseconds=0 функция только проверяет состояние объекта, не
блокируя поток, стр. 116), если не пришёл - считают и печатают
очередное число, ждут немного (Sleep), и по кругу. Счётчики fibCount и
primeCount каждый пишет только свой поток, поэтому им самим
синхронизация не нужна - переменная не расшаривается на запись между
потоками. Главный поток читает оба счётчика только после
WaitForMultipleObjects(..., TRUE, ...), то есть когда оба потока уже
гарантированно завершились - гонки на чтении тоже нет.

```c
#include <windows.h>
#include <iostream>
using namespace std;

CRITICAL_SECTION csOutput;
HANDLE hStopEvent;

DWORD fibCount = 0;
DWORD primeCount = 0;

BOOL IsStopSignaled()
{
    // dwMilliseconds = 0 - функция только проверяет состояние объекта,
    // не блокирует поток (Побегайло, стр. 116)
    return WaitForSingleObject(hStopEvent, 0) == WAIT_OBJECT_0;
}

DWORD WINAPI FibonacciThread(LPVOID lpParam)
{
    unsigned long long a = 0, b = 1, next;

    EnterCriticalSection(&csOutput);
    cout << "[Fibonacci] " << a << endl;
    LeaveCriticalSection(&csOutput);
    fibCount++;

    while (!IsStopSignaled())
    {
        next = a + b;
        a = b;
        b = next;

        EnterCriticalSection(&csOutput);
        cout << "[Fibonacci] " << a << endl;
        LeaveCriticalSection(&csOutput);
        fibCount++;

        Sleep(150);
    }
    return 0;
}

BOOL IsPrime(unsigned long n)
{
    if (n < 2) return FALSE;
    for (unsigned long d = 2; d * d <= n; ++d)
        if (n % d == 0) return FALSE;
    return TRUE;
}

DWORD WINAPI PrimeThread(LPVOID lpParam)
{
    unsigned long n = 1;

    while (!IsStopSignaled())
    {
        ++n;
        if (IsPrime(n))
        {
            EnterCriticalSection(&csOutput);
            cout << "[Prime] " << n << endl;
            LeaveCriticalSection(&csOutput);
            primeCount++;
        }
        Sleep(150);
    }
    return 0;
}

int main()
{
    LARGE_INTEGER start, end, freq;

    QueryPerformanceFrequency(&freq);  // Частота счетчика
    QueryPerformanceCounter(&start);   // Начало
    
    HANDLE hThreads[2];
    DWORD dwThreadId;
    DWORD start = GetTickCount();

    InitializeCriticalSection(&csOutput);

    // ручной сброс (TRUE), начально несигнальное (FALSE) - CreateEvent,
    // Побегайло стр. 129
    hStopEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    if (hStopEvent == NULL)
        return GetLastError();

    hThreads[0] = CreateThread(NULL, 0, FibonacciThread, NULL, 0, &dwThreadId);
    if (hThreads[0] == NULL)
        return GetLastError();

    hThreads[1] = CreateThread(NULL, 0, PrimeThread, NULL, 0, &dwThreadId);
    if (hThreads[1] == NULL)
        return GetLastError();

    // даём потокам поработать 3 секунды
    Sleep(3000);

    // сигнал остановки - оба потока увидят его на следующей проверке
    SetEvent(hStopEvent);

    // ждём завершения обоих потоков разом (bWaitAll = TRUE)
    WaitForMultipleObjects(2, hThreads, TRUE, INFINITE);

    cout << endl << "Остановлено." << endl;
    cout << "Чисел Фибоначчи найдено: " << fibCount << endl;
    cout << "Простых чисел найдено: " << primeCount << endl;

    CloseHandle(hThreads[0]);
    CloseHandle(hThreads[1]);
    CloseHandle(hStopEvent);
    DeleteCriticalSection(&csOutput);
    DWORD end = GetTickCount();
    cout << end - start << endl;
    
    QueryPerformanceCounter(&end);     // Конец
    double elapsed = (double)(end.QuadPart - start.QuadPart) / freq.QuadPart;
    cout << elapsed << endl;
    return 0;
}
```
