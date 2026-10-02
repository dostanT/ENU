Лабораторная работа 3-4 - Синхронизация процессов и потоков в ОС Windows

Вариант 10 (из открытого списка в labka 3.docx): два потока, один ищет
числа Фибоначчи, второй простые числа, оба выводят результат на экран,
после остановки показать, сколько чисел каждого вида нашли.

Логика потоков во всех вариантах 10-А, 10-Б, 10-В, 10-Г одна и та же:
через 3 секунды главный поток останавливает оба потока, затем печатает
счётчики. Меняется только примитив синхронизации.

Вариант 10-Б. Мьютекс вместо критической секции

Вывод в консоль защищён мьютексом: WaitForSingleObject(hOutMutex, INFINITE)
- захват, ReleaseMutex(hOutMutex) - освобождение. Сигнал остановки - событие
с ручным сбросом, как в варианте 10-А. Результат тот же, но каждый
захват и освобождение - обращение к объекту ядра, то есть дороже, чем
у критической секции. Для одного процесса это лишние затраты, мьютекс
оправдан, когда выводом делятся разные процессы (для этого ему задают имя
в CreateMutex).

```c
#include <windows.h>
#include <iostream>
using namespace std;

HANDLE hOutMutex;
HANDLE hStopEvent;

DWORD fibCount = 0;
DWORD primeCount = 0;

BOOL IsStopSignaled()
{
    return WaitForSingleObject(hStopEvent, 0) == WAIT_OBJECT_0;
}

void Print(const char* name, unsigned long long value)
{
    WaitForSingleObject(hOutMutex, INFINITE);   // захват мьютекса
    cout << "[" << name << "] " << value << endl;
    ReleaseMutex(hOutMutex);                    // освобождение мьютекса
}

DWORD WINAPI FibonacciThread(LPVOID lpParam)
{
    unsigned long long a = 0, b = 1, next;

    Print("Fibonacci", a);
    fibCount++;

    while (!IsStopSignaled())
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
    unsigned long n = 1;

    while (!IsStopSignaled())
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
    DWORD dwThreadId;

    // мьютекс создаётся свободным (bInitialOwner = FALSE), безымянный
    hOutMutex = CreateMutex(NULL, FALSE, NULL);
    if (hOutMutex == NULL)
        return GetLastError();

    // ручной сброс (TRUE), начально несигнальное (FALSE)
    hStopEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    if (hStopEvent == NULL)
        return GetLastError();

    hThreads[0] = CreateThread(NULL, 0, FibonacciThread, NULL, 0, &dwThreadId);
    if (hThreads[0] == NULL)
        return GetLastError();

    hThreads[1] = CreateThread(NULL, 0, PrimeThread, NULL, 0, &dwThreadId);
    if (hThreads[1] == NULL)
        return GetLastError();

    Sleep(3000);
    SetEvent(hStopEvent);
    WaitForMultipleObjects(2, hThreads, TRUE, INFINITE);

    cout << endl << "Остановлено." << endl;
    cout << "Чисел Фибоначчи найдено: " << fibCount << endl;
    cout << "Простых чисел найдено: " << primeCount << endl;

    CloseHandle(hThreads[0]);
    CloseHandle(hThreads[1]);
    CloseHandle(hStopEvent);
    CloseHandle(hOutMutex);
    
    QueryPerformanceCounter(&end);     // Конец
    double elapsed = (double)(end.QuadPart - start.QuadPart) / freq.QuadPart;
    cout << elapsed << endl;
    return 0;
}
```

Не скомпилировано по-настоящему (нет Windows/MSVC в этом окружении) -
проверено по логике API, не запуском.
