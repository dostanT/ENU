Справочник. Глава 12. Работа с буфером экрана

Логика

- Буферов экрана у процесса может быть несколько, ВИДЕН только один - активный. Создать буфер (CreateConsoleScreenBuffer) не значит показать; показать - SetConsoleActiveScreenBuffer. Это двойная буферизация: готовишь кадр в неактивном буфере, потом мгновенно переключаешь.
- Новый буфер: заполнен пробелами, курсор (0, 0).
- Буфер = весь холст (включая прокрученное). Окно = видимая часть. SetConsoleScreenBufferSize меняет холст, не окно. Размер буфера не может быть меньше окна.
- Четыре функции атрибутов:
  - SetConsoleTextAttribute - цвет для БУДУЩЕГО вывода (WriteFile/WriteConsole после вызова); уже написанное не меняется
  - FillConsoleOutputAttribute - существующие клетки диапазона в ОДИН цвет, символы не трогает
  - WriteConsoleOutputAttribute - существующие клетки массивом РАЗНЫХ цветов (i-й элемент - i-й клетке)
  - ReadConsoleOutputAttribute - ЧИТАЕТ цвета клеток (единственная читающая)
- Атрибуты (цвет) - флаги BACKGROUND_*/FOREGROUND_* (глава 9).
- CONSOLE_CURSOR_INFO.dwSize - размер КУРСОРА в процентах (1-100) от ячейки символа; не путать с dwSize из CONSOLE_SCREEN_BUFFER_INFO (размер буфера в символах).

Структуры
CONSOLE_SCREEN_BUFFER_INFO { COORD dwSize; COORD dwCursorPosition; WORD wAttributes; SMALL_RECT srWindow; COORD dwMaximumWindowSize; }
- dwSize - размер буфера в символах (столбцы, строки)
- dwCursorPosition - координаты курсора
- wAttributes - цвет фона и текста
- srWindow - углы окна относительно буфера
- dwMaximumWindowSize - максимальный размер окна
CONSOLE_CURSOR_INFO { DWORD dwSize; BOOL bVisible; } - dwSize 1-100 (% ячейки), bVisible TRUE/FALSE

Функции

CreateConsoleScreenBuffer
HANDLE CreateConsoleScreenBuffer(DWORD dwDesiredAccess, DWORD dwShareMode, CONST SECURITY_ATTRIBUTES *lpSecurityAttributes, DWORD dwFlags, LPVOID lpScreenBufferData);
- dwDesiredAccess - GENERIC_READ (читать) | GENERIC_WRITE (писать)
- dwShareMode - 0 = нельзя делить с другими процессами; или FILE_SHARE_READ | FILE_SHARE_WRITE
- lpSecurityAttributes - NULL
- dwFlags - единственное значение CONSOLE_TEXTMODE_BUFFER
- lpScreenBufferData - зарезервировано, NULL
Возврат: дескриптор нового буфера; INVALID_HANDLE_VALUE при ошибке. Закрывать CloseHandle.

SetConsoleActiveScreenBuffer
BOOL SetConsoleActiveScreenBuffer(HANDLE hConsoleOutput);
- hConsoleOutput - буфер, который станет видимым
Возврат: не 0 / FALSE.

GetConsoleScreenBufferInfo
BOOL GetConsoleScreenBufferInfo(HANDLE hConsoleOutput, PCONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo);
- hConsoleOutput - буфер экрана
- lpConsoleScreenBufferInfo - выходная структура (см. выше)
Возврат: не 0 / FALSE.

SetConsoleScreenBufferSize
BOOL SetConsoleScreenBufferSize(HANDLE hConsoleOutput, COORD dwSize);
- hConsoleOutput - буфер
- dwSize - новый размер в символах (не меньше окна; нижняя граница зависит от шрифта и метрик SM_CXMIN/SM_CYMIN)
Возврат: не 0 / FALSE.

GetConsoleCursorInfo / SetConsoleCursorInfo
BOOL GetConsoleCursorInfo(HANDLE hConsoleOutput, PCONSOLE_CURSOR_INFO lpConsoleCursorInfo);
BOOL SetConsoleCursorInfo(HANDLE hConsoleOutput, CONST CONSOLE_CURSOR_INFO *lpConsoleCursorInfo);
- hConsoleOutput - буфер; lpConsoleCursorInfo - структура (для Get выходная, для Set входная)
Возврат: не 0 / FALSE.

SetConsoleCursorPosition
BOOL SetConsoleCursorPosition(HANDLE hConsoleOutput, COORD dwCursorPosition);
- dwCursorPosition - новая позиция курсора в буфере
Возврат: не 0 / FALSE.

SetConsoleTextAttribute
BOOL SetConsoleTextAttribute(HANDLE hConsoleOutput, WORD wAttribute);
- wAttribute - цвет фона и текста для будущего вывода. Пример: BACKGROUND_GREEN | BACKGROUND_INTENSITY | FOREGROUND_RED | FOREGROUND_INTENSITY
Возврат: не 0 / FALSE.

FillConsoleOutputAttribute
BOOL FillConsoleOutputAttribute(HANDLE hConsoleOutput, WORD wAttributes, DWORD nLength, COORD dwWriteCoord, LPDWORD lpNumberOfAttrsWritten);
- wAttributes - один атрибут для всех клеток
- nLength - сколько клеток заполнить
- dwWriteCoord - координаты первой клетки
- lpNumberOfAttrsWritten - выходной DWORD: сколько клеток реально заполнено
Пример: весь буфер - nLength = csbi.dwSize.X * csbi.dwSize.Y, координата {0,0}.
Возврат: не 0 / FALSE.

WriteConsoleOutputAttribute
BOOL WriteConsoleOutputAttribute(HANDLE hConsoleOutput, CONST WORD *lpAttribute, DWORD nLength, COORD dwWriteCoord, LPDWORD lpNumberOfAttrsWritten);
- lpAttribute - ВХОДНОЙ массив атрибутов (по одному на клетку)
- остальное как у Fill
Возврат: не 0 / FALSE.

ReadConsoleOutputAttribute
BOOL ReadConsoleOutputAttribute(HANDLE hConsoleOutput, LPWORD lpAttribute, DWORD nLength, COORD dwWriteCoord, LPDWORD lpNumberOfAttrsRead);
- lpAttribute - ВЫХОДНОЙ массив: сюда читаются атрибуты
- nLength - сколько клеток читать
- dwWriteCoord - координаты первой клетки
- lpNumberOfAttrsRead - выходной: сколько прочитано
Возврат: не 0 / FALSE.

Шаблон двойной буферизации
hNew = CreateConsoleScreenBuffer(GENERIC_READ | GENERIC_WRITE, 0, NULL, CONSOLE_TEXTMODE_BUFFER, NULL);
hOld = GetStdHandle(STD_OUTPUT_HANDLE);
SetConsoleActiveScreenBuffer(hNew); WriteConsole(hNew, text, sizeof(text), &dwWritten, NULL);
SetConsoleActiveScreenBuffer(hOld); CloseHandle(hNew);
