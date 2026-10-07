#include <windows.h>
#include <io.h>
#include <fcntl.h>
#include <iostream>
#include <cstdio>

using namespace std;

static const wchar_t* ButtonName(DWORD state, DWORD mask)
{
    return (state & mask) ? L"нажата" : L"---";
}

static void PrintMouseEvent(const MOUSE_EVENT_RECORD& m)
{
    wprintf(L"MOUSE  X=%3d  Y=%3d  ", m.dwMousePosition.X, m.dwMousePosition.Y);

    wprintf(L"L=%s  R=%s  M=%s  ",
        ButtonName(m.dwButtonState, FROM_LEFT_1ST_BUTTON_PRESSED),
        ButtonName(m.dwButtonState, RIGHTMOST_BUTTON_PRESSED),
        ButtonName(m.dwButtonState, FROM_LEFT_2ND_BUTTON_PRESSED));

    DWORD flags = m.dwEventFlags;

    if (flags == 0)
    {
        wprintf(L"событие: КЛИК\n");
    }
    else if (flags & DOUBLE_CLICK)
    {
        wprintf(L"событие: ДВОЙНОЙ КЛИК\n");
    }
    else if (flags & MOUSE_HWHEELED)
    {
        SHORT delta = (SHORT)HIWORD(m.dwButtonState);
        wprintf(L"событие: ГОРИЗОНТ. СКРОЛЛ  delta=%d\n", delta);
    }
    else if (flags & MOUSE_WHEELED)
    {
        SHORT delta = (SHORT)HIWORD(m.dwButtonState);
        wprintf(L"событие: ВЕРТИКАЛЬН. СКРОЛЛ  delta=%d\n", delta);
    }
    else if (flags & MOUSE_MOVED)
    {
        wprintf(L"событие: ДВИЖЕНИЕ\n");
    }
    else
    {
        wprintf(L"событие: прочее (flags=0x%X)\n", flags);
    }
}

int wmain()
{
    _setmode(_fileno(stdout), _O_U16TEXT);

    HANDLE hIn = GetStdHandle(STD_INPUT_HANDLE);
    if (hIn == INVALID_HANDLE_VALUE)
    {
        wprintf(L"GetStdHandle failed, err=%lu\n", GetLastError());
        return 1;
    }

    DWORD oldMode = 0;
    if (!GetConsoleMode(hIn, &oldMode))
    {
        wprintf(L"GetConsoleMode failed, err=%lu\n", GetLastError());
        return 1;
    }

    DWORD newMode = oldMode;
    newMode |= ENABLE_MOUSE_INPUT;
    newMode &= ~ENABLE_QUICK_EDIT_MODE;

    if (!SetConsoleMode(hIn, newMode))
    {
        wprintf(L"SetConsoleMode failed, err=%lu\n", GetLastError());
        return 1;
    }

    BOOL running = TRUE;
    while (running)
    {
        INPUT_RECORD rec;
        DWORD n = 0;

        if (!ReadConsoleInput(hIn, &rec, 1, &n))
        {
            wprintf(L"ReadConsoleInput failed, err=%lu\n", GetLastError());
            break;
        }

        switch (rec.EventType)
        {
        case MOUSE_EVENT:
            PrintMouseEvent(rec.Event.MouseEvent);
            break;
        default:
            break;
        }
    }

    SetConsoleMode(hIn, oldMode);
    wprintf(L"\nВыход. Режим консоли восстановлен.\n");
    return 0;
}