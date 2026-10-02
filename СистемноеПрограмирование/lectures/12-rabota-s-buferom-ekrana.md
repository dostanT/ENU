Глава 12. Работа с буфером экрана

Суть

Глава 11 занималась ОКНОМ консоли - тем, что видно снаружи. Эта глава - про сам буфер экрана изнутри: как его создать (и почему буферов может быть несколько, хотя показывается всегда только один), как узнать и поменять его размеры, как управлять курсором, и как читать/менять цвет отдельных ячеек уже написанного текста, а не только то, каким цветом писать новый.

12.1 Создание и активация буфера экрана

Буфер экрана создаётся функцией CreateConsoleScreenBuffer:

```
HANDLE CreateConsoleScreenBuffer(
    DWORD                       dwDesiredAccess,      // режимы доступа
    DWORD                       dwShareMode,          // режимы разделения доступа
    CONST SECURITY_ATTRIBUTES  *lpSecurityAttributes,  // атрибуты защиты
    DWORD                       dwFlags,              // тип буфера экрана
    LPVOID                      lpScreenBufferData     // зарезервировано
);
```

При успехе возвращает дескриптор нового буфера экрана, при неудаче - INVALID_HANDLE_VALUE. dwDesiredAccess - комбинация GENERIC_READ (разрешено читать данные буфера) и GENERIC_WRITE (разрешено писать). dwShareMode определяет, может ли буфер использоваться несколькими процессами одновременно: 0 - нельзя, либо комбинация FILE_SHARE_READ (разрешено совместное чтение) и FILE_SHARE_WRITE (разрешена совместная запись). lpSecurityAttributes - пока всегда NULL (атрибуты защиты по умолчанию). dwFlags может принимать только одно значение - CONSOLE_TEXTMODE_BUFFER. lpScreenBufferData зарезервирован для будущего использования и должен быть NULL.

После создания новый буфер экрана заполнен пробелами, а курсор установлен в позицию (0, 0). Но просто СОЗДАТЬ буфер ещё не значит его показать - у процесса может быть НЕСКОЛЬКО буферов экрана одновременно, но виден в окне в любой момент только ОДИН из них, активный. Сделать буфер активным (то есть реально начать показывать его содержимое в окне) - функция SetConsoleActiveScreenBuffer:

```
BOOL SetConsoleActiveScreenBuffer(HANDLE hConsoleOutput);
```

При успехе возвращает ненулевое значение, при неудаче - FALSE. Единственный параметр - дескриптор того буфера экрана, который нужно сделать активным.

Представь художника с несколькими мольбертами в мастерской, но зритель в галерее видит только ОДИН из них - тот, что сейчас развёрнут к смотровому окну. Художник может спокойно, никому не мешая, готовить рисунок на ВТОРОМ мольберте (CreateConsoleScreenBuffer создаёт этот "запасной холст"), а когда рисунок готов - мгновенно развернуть именно его к окну (SetConsoleActiveScreenBuffer), без какого-либо мерцания или показа промежуточных, недорисованных состояний зрителю. Это тот же самый приём, что в компьютерной графике называется двойной буферизацией (double buffering) - готовишь следующий кадр целиком "за кулисами", а зрителю показываешь только уже готовый результат, одним мгновенным переключением.

Пример - создание и переключение буфера экрана

Листинг 12.1 создаёт второй буфер экрана, выводит в него текст функцией WriteConsole (подробно эта функция разбирается в разделе 13.1), затем возвращается к старому буферу и пишет уже в него:

```c
#include <windows.h>
#include <conio.h>

int main()
{
    HANDLE hStdOutOld, hStdOutNew;  // дескрипторы буфера экрана
    DWORD  dwWritten;               // для количества выведенных символов

    // создаем буфер экрана
    hStdOutNew = CreateConsoleScreenBuffer(
        GENERIC_READ | GENERIC_WRITE,  // чтение и запись
        0,                              // не разделяемый
        NULL,                           // защита по умолчанию
        CONSOLE_TEXTMODE_BUFFER,        // текстовый режим
        NULL);                          // не используется

    if (hStdOutNew == INVALID_HANDLE_VALUE)
    {
        _cputs("Create console screen buffer failed.\n");
        return GetLastError();
    }
    // сохраняем старый буфер экрана
    hStdOutOld = GetStdHandle(STD_OUTPUT_HANDLE);
    // ждем команду на переход к новому буферу экрана
    _cputs("Press any key to set new screen buffer active.\n");
    _getch();

    // делаем активным новый буфер экрана
    if (!SetConsoleActiveScreenBuffer(hStdOutNew))
    {
        _cputs("Set new console active screen buffer failed.\n");
        return GetLastError();
    }

    // выводим текст в новый буфер экрана
    char text[] = "This is a new screen buffer.";
    if (!WriteConsole(
        hStdOutNew,   // дескриптор буфера экрана
        text,         // символы, которые выводим
        sizeof(text), // длина текста
        &dwWritten,   // количество выведенных символов
        NULL))        // не используется
      _cputs("Write console output character failed.\n");

    // выводим сообщение о вводе символа
    char str[] = "\nPress any key to set old screen buffer.";
    if (!WriteConsole(
        hStdOutNew,   // дескриптор буфера экрана
        str,          // символы, которые выводим
        sizeof(str),  // длина текста
        &dwWritten,   // количество выведенных символов
        NULL))        // не используется
      _cputs("Write console output character failed.\n");

    _getch();

    // восстанавливаем старый буфер экрана
    if (!SetConsoleActiveScreenBuffer(hStdOutOld))
    {
        _cputs("Set old console active screen buffer failed.\n");
        return GetLastError();
    }
    // пишем в старый буфер экрана
    _cputs("This is an old console screen buffer.\n");

    // закрываем новый буфер экрана
    CloseHandle(hStdOutNew);
    // ждем команду на завершение программы
    _cputs("Press any key to finish.\n");
    _getch();

    return 0;
}
```

Не скомпилировано по-настоящему (нет Windows/MSVC в этом окружении) - проверено по документации и логике API. Механизм по шагам: создаём второй буфер (hStdOutNew), пока он ещё НЕ активен - пользователь видит только исходный экран; после нажатия клавиши переключаемся на новый буфер (теперь виден он); пишем в него текст через WriteConsole; после следующего нажатия клавиши переключаемся ОБРАТНО на старый буфер (hStdOutOld) - и пишем уже в него, старым, привычным cputs. Новый буфер в конце закрывается через CloseHandle, как любой дескриптор.

12.2 Определение и установка параметров буфера экрана

Параметры буфера экрана можно определить функцией GetConsoleScreenBufferInfo:

```
BOOL GetConsoleScreenBufferInfo(
    HANDLE                      hConsoleOutput,          // дескриптор буфера экрана
    PCONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo // указатель на структуру параметров
);
```

При успехе возвращает ненулевое значение, при неудаче - FALSE. Заполняет структуру:

```c
typedef struct _CONSOLE_SCREEN_BUFFER_INFO {
    COORD      dwSize;              // размер буфера экрана в символах (столбцы, строки)
    COORD      dwCursorPosition;    // координаты курсора в символах
    WORD       wAttributes;         // цвет фона и цвет текста
    SMALL_RECT srWindow;            // левый верхний и правый нижний углы
                                     // окна относительно буфера экрана
    COORD      dwMaximumWindowSize; // максимальный размер окна
} CONSOLE_SCREEN_BUFFER_INFO;
```

Пример - чтение параметров буфера экрана

Листинг 12.2 читает и печатает все поля этой структуры для стандартного вывода:

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    HANDLE                     hStdOut;  // дескриптор стандартного вывода
    CONSOLE_SCREEN_BUFFER_INFO csbi;      // для параметров буфера экрана

    // читаем стандартный дескриптор вывода
    hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
    // читаем параметры буфера экрана
    if (!GetConsoleScreenBufferInfo(hStdOut, &csbi))
        cout << "Console screen buffer info failed." << endl;

    cout << "Console screen buffer info: " << endl << endl;
    // выводим на консоль параметры выходного буфера
    cout << "A number of columns = " << csbi.dwSize.X << endl;
    cout << "A number of rows = " << csbi.dwSize.Y << endl;
    cout << "X cursor coordinate = " << csbi.dwCursorPosition.X << endl;
    cout << "Y cursor coordinate = " << csbi.dwCursorPosition.Y << endl;
    cout << "Attributes = " << hex << csbi.wAttributes << dec << endl;
    cout << "Window upper corner = "
         << csbi.srWindow.Left << "," << csbi.srWindow.Top << endl;
    cout << "Window lower corner = "
         << csbi.srWindow.Right << "," << csbi.srWindow.Bottom << endl;
    cout << "Maximum number of columns = "
         << csbi.dwMaximumWindowSize.X << endl;
    cout << "Maximum number of rows = "
         << csbi.dwMaximumWindowSize.Y << endl << endl;

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API.

Размер буфера экрана можно ИЗМЕНИТЬ функцией SetConsoleScreenBufferSize:

```
BOOL SetConsoleScreenBufferSize(
    HANDLE hConsoleOutput,  // дескриптор буфера экрана
    COORD  dwSize           // новый размер буфера экрана
);
```

При успехе возвращает ненулевое значение, при неудаче - FALSE. Размер задаётся в символах и не может быть МЕНЬШЕ размера окна консоли (то есть нельзя сделать холст меньше, чем уже открытая на него смотровая рамка - см. главу 11, окно не может быть больше буфера). Минимальные размеры буфера экрана также ограничены системой и зависят от размера используемого шрифта и системных метрик SM_CXMIN и SM_CYMIN.

Пример - изменение размера буфера экрана

Листинг 12.3 запрашивает у пользователя новый размер (число столбцов и строк) и устанавливает его:

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    COORD  coord;    // для размера буфера экрана
    HANDLE hStdOut;  // дескриптор стандартного вывода

    // читаем дескриптор стандартного вывода
    hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);

    // вводим новый размер буфера экрана
    cout << "Enter new screen buffer size." << endl;
    cout << "A number of columns: ";
    cin >> coord.X;
    cout << "A number of rows: ";
    cin >> coord.Y;
    // устанавливаем новый размер буфера экрана
    if (!SetConsoleScreenBufferSize(hStdOut, coord))
    {
        cout << "Set console screen buffer size failed." << endl;
        return GetLastError();
    }

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API.

12.3 Функции для работы с курсором

Информацию о положении и видимости курсора можно получить функцией GetConsoleCursorInfo:

```
BOOL GetConsoleCursorInfo(
    HANDLE                hConsoleOutput,      // дескриптор буфера экрана
    PCONSOLE_CURSOR_INFO  lpConsoleCursorInfo  // информация о курсоре
);
```

При успехе возвращает ненулевое значение, при неудаче - FALSE, и заполняет структуру:

```c
typedef struct _CONSOLE_CURSOR_INFO {
    DWORD dwSize;
    BOOL  bVisible;
} CONSOLE_CURSOR_INFO, *PCONSOLE_CURSOR_INFO;
```

dwSize изменяется в интервале от 1 до 100 и определяет размер курсора в ПРОЦЕНТАХ от размера клетки для символа (то есть не в пикселях, а относительно ячейки текста), а bVisible определяет видимость курсора: TRUE - курсор виден, FALSE - невидим.

Установить размер и видимость курсора - функция SetConsoleCursorInfo:

```
BOOL SetConsoleCursorInfo(
    HANDLE                     hConsoleOutput,      // дескриптор буфера экрана
    CONST CONSOLE_CURSOR_INFO *lpConsoleCursorInfo  // информация о курсоре
);
```

При успехе возвращает ненулевое значение, при неудаче - FALSE.

Пример - чтение и установка параметров курсора

Листинг 12.4 читает текущие параметры курсора, печатает их, устанавливает новый размер, затем по очереди делает курсор невидимым и снова видимым:

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    char                c;
    HANDLE              hStdOut;  // дескриптор стандартного вывода
    CONSOLE_CURSOR_INFO cci;      // информация о курсоре

    // читаем дескриптор стандартного вывода
    hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
    // читаем информацию о курсоре
    if (!GetConsoleCursorInfo(hStdOut, &cci))
        cout << "Get console cursor info failed." << endl;
    // выводим информацию о курсоре
    cout << "Size of cursor in procents of char= " << cci.dwSize << endl;
    cout << "Visibility of cursor = " << cci.bVisible << endl;

    // читаем новый размер курсора
    cout << "Input a new size of cursor (1-100): ";
    cin >> cci.dwSize;
    // устанавливаем новый размер курсора
    if (!SetConsoleCursorInfo(hStdOut, &cci))
        cout << "Set console cursor info failed." << endl;

    cout << "Input any char to make the cursor invisible: ";
    cin >> c;
    // делаем курсор невидимым
    cci.bVisible = FALSE;
    // устанавливаем невидимый курсор
    if (!SetConsoleCursorInfo(hStdOut, &cci))
        cout << "Set console cursor info failed." << endl;

    cout << "Input any char to make the cursor visible: ";
    cin >> c;
    // делаем курсор видимым
    cci.bVisible = TRUE;
    // устанавливаем видимый курсор
    if (!SetConsoleCursorInfo(hStdOut, &cci))
        cout << "Set console cursor info failed." << endl;

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API.

Позиция курсора в буфере экрана устанавливается функцией SetConsoleCursorPosition:

```
BOOL SetConsoleCursorPosition(
    HANDLE hConsoleOutput,   // дескриптор буфера экрана
    COORD  dwCursorPosition  // новая позиция курсора
);
```

При успехе возвращает ненулевое значение, при неудаче - FALSE.

Пример - перемещение курсора в новую позицию

Листинг 12.5 запрашивает у пользователя новые X, Y координаты курсора и перемещает его туда:

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    char   c;
    HANDLE hStdOut;  // дескриптор стандартного вывода
    COORD  coord;    // для позиции курсора

    // читаем дескриптор стандартного вывода
    hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);

    cout << "Input new cursor position." << endl;
    cout << "X = ";
    cin >> coord.X;
    cout << "Y = ";
    cin >> coord.Y;

    // установить курсор в новую позицию
    if (!SetConsoleCursorPosition(hStdOut, coord))
    {
        cout << "Set cursor position failed." << endl;
        return GetLastError();
    }

    cout << "This is a new position." << endl;
    cout << "Input any char to exit: ";
    cin >> c;

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API.

12.4 Чтение и установка атрибутов консоли

Здесь важно с самого начала различить четыре похожие функции - легко перепутать, что каждая из них реально делает. Представь страницу с уже напечатанным текстом и цветной ручкой:

- SetConsoleTextAttribute - это выбор цвета ручки для того, что ты напишешь ДАЛЬШЕ. Уже написанное на странице не меняется ни капли.
- FillConsoleOutputAttribute - это маркер: закрашиваешь уже существующий прямоугольный кусок страницы ОДНИМ и тем же цветом, сами буквы под маркером не трогая.
- WriteConsoleOutputAttribute - это когда для каждой уже написанной буквы подряд берёшь СВОЙ отдельный цвет (первая буква - красная, вторая - синяя и так далее), то есть красишь по одной ячейке за раз, каждую в свой цвет.
- ReadConsoleOutputAttribute - обратное действие: считываешь, каким цветом СЕЙЧАС покрашена каждая из уже написанных ячеек подряд.

Установка атрибутов для ДАЛЬНЕЙШЕГО вывода - функция SetConsoleTextAttribute:

```
BOOL SetConsoleTextAttribute(
    HANDLE hConsoleOutput,  // дескриптор буфера экрана
    WORD   wAttribute       // цвет фона и цвета текста
);
```

При успехе возвращает ненулевое значение, при неудаче - FALSE. wAttribute задаёт новые цвета фона и текста, которыми будут выводиться СИМВОЛЫ, записанные в буфер функциями WriteFile и WriteConsole ПОСЛЕ этого вызова, а также отображаться на экране при чтении функциями ReadFile и ReadConsole.

Пример - установка атрибутов текста

Листинг 12.7 задаёт зелёный фон и красный текст для всего, что будет напечатано после этого вызова:

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    char   c;
    HANDLE hStdout;     // дескриптор стандартного вывода
    WORD   wAttribute;  // цвет фона и текста

    cout << "In order to set text attributes, input any char: ";
    cin >> c;

    // читаем стандартный дескриптор вывода
    hStdout = GetStdHandle(STD_OUTPUT_HANDLE);

    // задаем цвет фона зеленым, а цвет символов красным
    wAttribute = BACKGROUND_GREEN | BACKGROUND_INTENSITY |
        FOREGROUND_RED | FOREGROUND_INTENSITY;
    // устанавливаем новые атрибуты
    if (!SetConsoleTextAttribute(hStdout, wAttribute))
    {
        cout << "Set console text attribute failed." << endl;
        return GetLastError();
    }

    cout << "The text attributes was changed." << endl;

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API.

Установка атрибутов для УЖЕ имеющихся, ранее написанных клеток - функция FillConsoleOutputAttribute:

```
BOOL FillConsoleOutputAttribute(
    HANDLE   hConsoleOutput,         // дескриптор буфера экрана
    WORD     wAttributes,            // цвет фона и цвет текста
    DWORD    nLength,                // количество заполняемых клеток
    COORD    dwWriteCoord,           // координаты первой клетки
    LPDWORD  lpNumberOfAttrsWritten  // количество заполненных клеток
);
```

При успехе возвращает ненулевое значение, при неудаче - FALSE. Функция заполняет nLength клеток экрана, начиная с координаты dwWriteCoord, ОДНИМ И ТЕМ ЖЕ набором атрибутов wAttributes - то есть красит подряд идущий блок клеток в единый цвет, не трогая сами символы. lpNumberOfAttrsWritten должен указывать на переменную типа DWORD, в которую функция поместит реальное количество заполненных клеток.

Пример - заполнение всей консоли новыми атрибутами

Листинг 12.6 вычисляет размер буфера в клетках (ширина × высота) и заполняет ВЕСЬ буфер новым цветом, начиная с клетки (0,0):

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    char                        c;
    HANDLE                      hStdOut;    // дескриптор стандартного вывода
    WORD                        wAttribute; // цвет фона и текста
    DWORD                       dwLength;   // количество заполняемых клеток
    DWORD                       dwWritten;  // для количества заполненных клеток
    COORD                       coord;      // координаты первой клетки
    CONSOLE_SCREEN_BUFFER_INFO  csbi;       // для параметров буфера экрана

    cout << "In order to fill console attributes, input any char: ";
    cin >> c;
    // читаем стандартный дескриптор вывода
    hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hStdOut == INVALID_HANDLE_VALUE)
    {
        cout << "Get standard handle failed." << endl;
        return GetLastError();
    }
    // читаем параметры выходного буфера
    if (!GetConsoleScreenBufferInfo(hStdOut, &csbi))
    {
        cout << "Console screen buffer info failed." << endl;
        return GetLastError();
    }

    // вычисляем размер буфера экрана в символах
    dwLength = csbi.dwSize.X * csbi.dwSize.Y;
    // начинаем заполнять буфер с первой клетки
    coord.X = 0;
    coord.Y = 0;
    // устанавливаем цвет фона голубым, а цвет символов желтым
    wAttribute = BACKGROUND_BLUE | BACKGROUND_INTENSITY |
        FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_INTENSITY;
    // заполняем буфер атрибутами
    if (!FillConsoleOutputAttribute(
        hStdOut,    // стандартный дескриптор вывода
        wAttribute, // цвет фона и текста
        dwLength,   // длина буфера в символах
        coord,      // индекс первой клетки
        &dwWritten)) // количество заполненных клеток
    {
        cout << "Fill console output attribute failed." << endl;
        return GetLastError();
    }

    cout << "The fill attributes was changed." << endl;

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API.

Запись РАЗНЫХ атрибутов в подряд идущие клетки - функция WriteConsoleOutputAttribute:

```
BOOL WriteConsoleOutputAttribute(
    HANDLE        hConsoleOutput,       // дескриптор буфера экрана
    CONST WORD   *lpAttribute,          // указатель на атрибуты
    DWORD         nLength,              // количество заполняемых клеток
    COORD         dwWriteCoord,         // координаты первой клетки
    LPDWORD       lpNumberOfAttrsWritten // количество заполненных клеток
);
```

При успешном завершении возвращает ненулевое значение, при неудаче - FALSE. Все параметры этой функции, за исключением lpAttribute, имеют тот же смысл, что и соответствующие параметры FillConsoleOutputAttribute. Но lpAttribute здесь указывает на МАССИВ атрибутов - то есть в отличие от FillConsoleOutputAttribute (один и тот же цвет на весь диапазон), эта функция позволяет заполнять подряд идущие клетки НЕ одним, а разными атрибутами - i-й элемент массива достаётся i-й клетке.

Чтение атрибутов из подряд идущих клеток - функция ReadConsoleOutputAttribute:

```
BOOL ReadConsoleOutputAttribute(
    HANDLE   hConsoleOutput,       // дескриптор буфера экрана
    LPWORD   lpAttribute,          // указатель на атрибуты
    DWORD    nLength,              // количество читаемых клеток
    COORD    dwWriteCoord,         // координаты первой клетки
    LPDWORD  lpNumberOfAttrsRead   // количество прочитанных клеток
);
```

При успешном завершении возвращает ненулевое значение, при неудаче - FALSE. Назначение параметров hConsoleOutput и dwWriteCoord совпадает с назначением соответствующих параметров WriteConsoleOutputAttribute. lpAttribute указывает на область памяти, В КОТОРУЮ будут читаться атрибуты (то есть теперь это выходной параметр, а не входной, как в Write-функции). nLength - сколько клеток читать, lpNumberOfAttrsRead - сколько реально прочиталось.

Пример - установка и чтение атрибутов текста из последовательных клеток

Листинг 12.8 записывает 4 разных атрибута в 4 подряд идущие клетки (например под словом "текст"), а затем читает их обратно и печатает в шестнадцатеричном виде:

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    HANDLE hStdOut;          // дескриптор буфера экрана
    WORD   lpAttribute[4];   // массив клеток с атрибутами
    DWORD  nLength = 4;      // количество клеток
    COORD  dwCoord = {8, 0}; // координата первой клетки
    DWORD  NumberOfAttrs;    // количество обработанных клеток

    // читаем стандартный дескриптор вывода
    hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);

    // выводим демо-текст
    cout << "Console text attributes." << endl;
    // ждем команды на изменение атрибутов слова "текст"
    cout << "Press any key to change attributes.";
    cin.get();
    // устанавливаем новые атрибуты
    lpAttribute[0] = BACKGROUND_BLUE | BACKGROUND_INTENSITY |
                      FOREGROUND_GREEN | FOREGROUND_INTENSITY;
    lpAttribute[1] = BACKGROUND_GREEN | BACKGROUND_INTENSITY |
                      BACKGROUND_BLUE | FOREGROUND_INTENSITY;
    lpAttribute[2] = BACKGROUND_RED | BACKGROUND_INTENSITY |
                      FOREGROUND_GREEN | FOREGROUND_INTENSITY;
    lpAttribute[3] = BACKGROUND_GREEN | BACKGROUND_INTENSITY |
                      FOREGROUND_RED | FOREGROUND_INTENSITY;
    // записываем новые атрибуты в буфер экрана
    if (!WriteConsoleOutputAttribute(hStdOut, lpAttribute,
        nLength, dwCoord, &NumberOfAttrs))
    {
        cout << "Read console output attribute failed." << endl;
        return GetLastError();
    }
    // читаем атрибуты слова "текст"
    if (!ReadConsoleOutputAttribute(hStdOut, lpAttribute,
        nLength, dwCoord, &NumberOfAttrs))
    {
        cout << "Read console output attribute failed." << endl;
        return GetLastError();
    }
    // распечатываем атрибуты слова "текст"
    cout << hex;
    cout << "Attribute[0] = " << lpAttribute[0] << endl;
    cout << "Attribute[1] = " << lpAttribute[1] << endl;
    cout << "Attribute[2] = " << lpAttribute[2] << endl;
    cout << "Attribute[3] = " << lpAttribute[3] << endl;
    // ждем команду на завершение программы
    cout << "Press any key to exit.";
    cin.get();

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API. Обрати внимание: один и тот же массив lpAttribute сначала используется как ВХОДНОЙ параметр (что записать - WriteConsoleOutputAttribute), а затем как ВЫХОДНОЙ (куда прочитать - ReadConsoleOutputAttribute) - книга нарочно переиспользует один и тот же массив дважды, чтобы показать, что запись и чтение назад дают ровно то же самое.

Частые путаницы и ошибки

Путают четыре функции работы с атрибутами (см. аналогию в начале раздела 12.4). SetConsoleTextAttribute красит только БУДУЩИЙ вывод. FillConsoleOutputAttribute красит уже существующий диапазон клеток ОДНИМ цветом. WriteConsoleOutputAttribute красит уже существующий диапазон клеток массивом РАЗНЫХ цветов, по одному на клетку. ReadConsoleOutputAttribute - единственная из четырёх, что ЧИТАЕТ, а не пишет.

Путают "буфер экрана" и "окно консоли" (см. также частые путаницы главы 11). Буфер экрана - это весь холст целиком, включая то, что сейчас не видно (прокручено за пределы окна). Окно - это только видимая часть буфера. SetConsoleScreenBufferSize меняет размер ХОЛСТА, а не размер видимого окна.

Забывают, что у процесса может быть несколько буферов экрана, но виден в конкретный момент только ОДИН, активный (SetConsoleActiveScreenBuffer). Создание буфера (CreateConsoleScreenBuffer) само по себе ничего не показывает на экране.

Путают dwSize в CONSOLE_CURSOR_INFO с размером буфера экрана. Это размер именно КУРСОРА, в процентах (1-100) от высоты одной ячейки символа - никак не связан с dwSize из CONSOLE_SCREEN_BUFFER_INFO (это уже размер всего буфера в символах, другое поле другой структуры).

Источник

Конспект по главе 12 книги Побегайло, "Работа с буфером экрана" (стр. 188-202, см. book-toc.md, включая листинги 12.1-12.8 целиком). Ни один пример не скомпилирован (нет Windows) - объяснено по документации и логике API, как и во всех остальных конспектах этого предмета.
