#include <windows.h>
#include <iostream.h>

// Рабочий поток: просто выводит сообщения и считает до трёх
DWORD WINAPI Worker(LPVOID lpParam)
{
    cout << "Рабочий поток: стартовал." << endl;
    for (int i = 1; i <= 3; i++)
    {
        cout << "Рабочий поток: шаг " << i << endl;
        Sleep(500);
    }
    cout << "Рабочий поток: завершён." << endl;
    return 0;
}

// Функция для расшифровки кода ошибки Win32 в текст
void PrintError(DWORD dwError)
{
    LPVOID lpMsgBuf;
    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL, dwError, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPTSTR)&lpMsgBuf, 0, NULL);

    cout << "Ошибка " << dwError << ": " << (char*)lpMsgBuf << endl;
    LocalFree(lpMsgBuf);
}

int main()
{
    HANDLE hThread;
    DWORD dwThreadId;

    // Создаём поток в подвешенном состоянии
    hThread = CreateThread(NULL, 0, Worker, NULL, CREATE_SUSPENDED, &dwThreadId);
    if (hThread == NULL)
    {
        PrintError(GetLastError());
        return 1;
    }

    cout << "Главный поток: рабочий поток создан, но пока стоит на паузе." << endl;
    cout << "Главный поток: делаю свои дела..." << endl;
    Sleep(1000);
    cout << "Главный поток: теперь запускаю рабочий поток." << endl;

    // Запускаем поток
    if (ResumeThread(hThread) == (DWORD)-1)
    {
        PrintError(GetLastError());
        CloseHandle(hThread);
        return 1;
    }

    // Ждём завершения потока
    WaitForSingleObject(hThread, INFINITE);

    cout << "Главный поток: рабочий поток завершился, закрываю дескриптор." << endl;
    CloseHandle(hThread);

    cout << "Готово." << endl;
    return 0;
}
