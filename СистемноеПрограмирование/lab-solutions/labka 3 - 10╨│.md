Лабораторная работа 3-4 - Синхронизация процессов и потоков в ОС Windows

Вариант 10 (из открытого списка в labka 3.docx): два потока, один ищет
числа Фибоначчи, второй простые числа, оба выводят результат на экран,
после остановки показать, сколько чисел каждого вида нашли.

Логика потоков во всех вариантах 10-А, 10-Б, 10-В, 10-Г одна и та же:
через 3 секунды главный поток останавливает оба потока, затем печатает
счётчики. Меняется только примитив синхронизации.

Вариант 10-Г. Событие с автоматическим сбросом (Manual Event -> Auto Event)

В варианте 10-А сигнал остановки - событие с ручным сбросом:
CreateEvent(NULL, TRUE, FALSE, NULL). После одного SetEvent оно остаётся
сигнальным, пока не будет вызван ResetEvent, поэтому оба потока при
своей проверке WaitForSingleObject(hStopEvent, 0) получают WAIT_OBJECT_0.

При замене на автосброс - CreateEvent(NULL, FALSE, FALSE, NULL) - оставить
одно общее событие нельзя. Событие с автосбросом становится несигнальным
сразу после того, как ОДИН поток успешно прошёл функцию ожидания. Если оба
потока опрашивают одно такое событие, а главный поток вызвал SetEvent один
раз, то сигнал получит только тот поток, чья проверка выполнится первой.
Второй поток увидит уже несигнальное событие и продолжит работать бесконечно,
а WaitForMultipleObjects(2, hThreads, TRUE, INFINITE) в главном потоке
никогда не вернётся (вывод по логике API, не проверено запуском).

Поэтому в варианте с автосбросом у каждого потока своё событие
(hStopFib и hStopPrime), а главный поток вызывает SetEvent для каждого.
Дескриптор своего события поток получает через параметр lpParam функции
CreateThread. Проверка WaitForSingleObject(hStop, 0) сама сбрасывает
событие, но это не мешает: получив сигнал, поток сразу завершается.
Защита вывода - критическая секция, как в варианте 10-А.

Ручной сброс: одно событие, освобождает всех ждущих ("открыть дорогу всем"),
снимается только ResetEvent. Автосброс: освобождает одного ждущего,
сбрасывается само ("один билет"), для двух потоков нужны два билета.

```c
#include <windows.h>
#include <iostream>
using namespace std;

CRITICAL_SECTION csOutput;

DWORD fibCount = 0;
DWORD primeCount = 0;

void Print(const char* name, unsigned long long value)
{
    EnterCriticalSection(&csOutput);
    cout << "[" << name << "] " << value << endl;
    LeaveCriticalSection(&csOutput);
}

DWORD WINAPI FibonacciThread(LPVOID lpParam)
{
    HANDLE hStop = (HANDLE)lpParam;     // своё событие остановки (автосброс)
    unsigned long long a = 0, b = 1, next;

    Print("Fibonacci", a);
    fibCount++;

    // проверка с интервалом 0 не блокирует; при WAIT_OBJECT_0 событие
    // автоматически становится несигнальным, поток выходит из цикла
    while (WaitForSingleObject(hStop, 0) != WAIT_OBJECT_0)
    {
        next = a + b;
        a = b;
        b = next;

        Print("Fibonacci", a);
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
    HANDLE hStop = (HANDLE)lpParam;     // своё событие остановки (автосброс)
    unsigned long n = 1;

    while (WaitForSingleObject(hStop, 0) != WAIT_OBJECT_0)
    {
        ++n;
        if (IsPrime(n))
        {
            Print("Prime", n);
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
    HANDLE hStopFib, hStopPrime;
    DWORD dwThreadId;

    InitializeCriticalSection(&csOutput);

    // автосброс (bManualReset = FALSE), начально несигнальное (FALSE)
    hStopFib   = CreateEvent(NULL, FALSE, FALSE, NULL);
    hStopPrime = CreateEvent(NULL, FALSE, FALSE, NULL);
    if (hStopFib == NULL || hStopPrime == NULL)
        return GetLastError();

    hThreads[0] = CreateThread(NULL, 0, FibonacciThread, (LPVOID)hStopFib, 0, &dwThreadId);
    if (hThreads[0] == NULL)
        return GetLastError();

    hThreads[1] = CreateThread(NULL, 0, PrimeThread, (LPVOID)hStopPrime, 0, &dwThreadId);
    if (hThreads[1] == NULL)
        return GetLastError();

    Sleep(3000);

    // два потока - два сигнала (по одному на каждое событие)
    SetEvent(hStopFib);
    SetEvent(hStopPrime);

    WaitForMultipleObjects(2, hThreads, TRUE, INFINITE);

    cout << endl << "Остановлено." << endl;
    cout << "Чисел Фибоначчи найдено: " << fibCount << endl;
    cout << "Простых чисел найдено: " << primeCount << endl;

    CloseHandle(hThreads[0]);
    CloseHandle(hThreads[1]);
    CloseHandle(hStopFib);
    CloseHandle(hStopPrime);
    DeleteCriticalSection(&csOutput);
    
    QueryPerformanceCounter(&end);     // Конец
    double elapsed = (double)(end.QuadPart - start.QuadPart) / freq.QuadPart;
    cout << elapsed << endl;
    return 0;
}
```

Не скомпилировано по-настоящему (нет Windows/MSVC в этом окружении) -
проверено по логике API, не запуском.
