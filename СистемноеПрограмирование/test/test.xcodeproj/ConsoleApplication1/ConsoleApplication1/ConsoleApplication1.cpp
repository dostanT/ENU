#include <windows.h>
#include <iostream>
using namespace std;

int main()
{
    // --- Шаг 1: печатаем на экран как обычно ---
    cout << "1. This goes to the console.\n";

    // --- Шаг 2: открываем файл и подменяем STDOUT на него ---
    HANDLE hFile = CreateFile(
        L"output.txt",              // имя файла на диске
        GENERIC_WRITE,             // пишем в файл
        0,                         // никому больше не даём открыть
        NULL,                      // защита по умолчанию
        CREATE_ALWAYS,             // создать заново (или перезаписать)
        FILE_ATTRIBUTE_NORMAL,     // обычный файл
        NULL                       // шаблон не нужен
    );

    if (hFile == INVALID_HANDLE_VALUE)
    {
        cout << "CreateFile failed: " << GetLastError() << "\n";
        return 1;
    }

    // Запоминаем старый STDOUT, чтобы потом вернуть обратно
    HANDLE hOldStdOut = GetStdHandle(STD_OUTPUT_HANDLE);

    // Подменяем: теперь STDOUT ведёт в файл
    SetStdHandle(STD_OUTPUT_HANDLE, hFile);

    // --- Шаг 3: печатаем — уходит в файл, не на экран ---
    cout << "2. This goes to the FILE." << "\n";

    // --- Шаг 4: возвращаем STDOUT обратно на консоль ---
    SetStdHandle(STD_OUTPUT_HANDLE, hOldStdOut);

    // --- Шаг 5: снова печатаем на экран ---
    cout << "3. This goes to the console again." << "\n";

    // Закрываем дескриптор файла — он больше не нужен
    CloseHandle(hFile);

    return 0;
}