Лабораторная работа 3-4 - Синхронизация процессов и потоков в ОС Windows

Вариант 10 (из открытого списка в labka 3.docx): два потока, один ищет
числа Фибоначчи, второй простые числа, оба выводят результат на экран,
после остановки показать, сколько чисел каждого вида нашли.

Логика потоков во всех вариантах 10-А, 10-Б, 10-В, 10-Г одна и та же:
через 3 секунды главный поток останавливает оба потока, затем печатает
счётчики. Меняется только примитив синхронизации.

Вариант 10-В. Семафор

Вывод в консоль защищён бинарным семафором: CreateSemaphore(NULL, 1, 1, NULL)
- начальное значение 1 (одно свободное место), максимум 1. Захват места -
WaitForSingleObject(hOutSem, INFINITE) (значение 1 -> 0, второй поток
ждёт), освобождение - ReleaseSemaphore(hOutSem, 1, NULL) (значение 0 -> 1).
Семафор с максимумом 1 работает как мьютекс, но у него нет владельца:
ReleaseSemaphore может вызвать любой поток, а если поток завершится, не
освободив место, система семафор не освободит (у мьютекса в этом случае
следующий поток получает WAIT_ABANDONED). Настоящая сила семафора -
значение больше 1 (см. демонстрацию 4 ниже), здесь она не используется,
потому что в консоль должен писать ровно один поток.

```c
#include <windows.h>
#include <iostream>
using namespace std;

HANDLE hOutSem;
HANDLE hStopEvent;

DWORD fibCount = 0;
DWORD primeCount = 0;

BOOL IsStopSignaled()
{
    return WaitForSingleObject(hStopEvent, 0) == WAIT_OBJECT_0;
}

void Print(const char* name, unsigned long long value)
{
    WaitForSingleObject(hOutSem, INFINITE);     // занять единственное место
    cout << "[" << name << "] " << value << endl;
    ReleaseSemaphore(hOutSem, 1, NULL);         // вернуть место
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

    // начальное значение 1, максимальное 1: одно место, "бинарный" семафор
    hOutSem = CreateSemaphore(NULL, 1, 1, NULL);
    if (hOutSem == NULL)
        return GetLastError();

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
    CloseHandle(hOutSem);
    
    QueryPerformanceCounter(&end);     // Конец
    double elapsed = (double)(end.QuadPart - start.QuadPart) / freq.QuadPart;
    
    cout << elapsed << endl;
    return 0;
}
```

Не скомпилировано по-настоящему (нет Windows/MSVC в этом окружении) -
проверено по логике API, не запуском.
