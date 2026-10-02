Справочник. Глава 11. Работа с окном консоли

Логика

- Окно консоли - обычное окно Windows (HWND), внутри показывает часть буфера экрана. HWND (окно, GDI) и HANDLE буфера экрана (консольные функции) - два разных дескриптора двух разных объектов, друг друга не заменяют.
- Окно всегда не больше буфера экрана. Сначала увеличить буфер (SetConsoleScreenBufferSize, глава 12), потом окно.
- Координаты SMALL_RECT - ячейки буфера (столбцы/строки), не пиксели.
- Windows 98: SetConsoleWindowInfo фактически служит прокруткой буфера в окне.

Структура
SMALL_RECT { SHORT Left; SHORT Top; SHORT Right; SHORT Bottom; } - левый верхний и правый нижний углы окна (в ячейках буфера).

Функции

GetConsoleWindow
HWND GetConsoleWindow(VOID);
Возврат: HWND окна консоли; NULL если консоли нет. Только Windows 2000/XP. Тип HWND - обычное окно, с ним можно работать через GDI (GetDC, CreatePen, SelectObject, MoveToEx, LineTo; убирать: SelectObject со старым объектом, DeleteObject, ReleaseDC).

GetConsoleTitle
DWORD GetConsoleTitle(LPTSTR lpConsoleTitle, DWORD nSize);
- lpConsoleTitle - буфер для заголовка
- nSize - размер буфера в символах
Возврат: длина заголовка в символах; 0 при ошибке.

SetConsoleTitle
BOOL SetConsoleTitle(LPCTSTR lpConsoleTitle);
- lpConsoleTitle - строка нового заголовка
Возврат: не 0 / FALSE.

GetLargestConsoleWindowSize
COORD GetLargestConsoleWindowSize(HANDLE hConsoleOutput);
- hConsoleOutput - дескриптор буфера экрана (например GetStdHandle(STD_OUTPUT_HANDLE))
Возврат: COORD: X - макс. число столбцов, Y - макс. число строк окна (зависит от шрифта и размера экрана). При ошибке в X и Y нули (проверка: coord.X == 0 && coord.Y == 0).

SetConsoleWindowInfo
BOOL SetConsoleWindowInfo(HANDLE hConsoleOutput, BOOL bAbsolute, CONST SMALL_RECT *lpConsoleWindow);
- hConsoleOutput - дескриптор буфера экрана; должен быть открыт с GENERIC_WRITE
- bAbsolute - TRUE: lpConsoleWindow задаёт АБСОЛЮТНОЕ положение углов окна относительно буфера; FALSE: СДВИГ углов относительно текущего положения окна
- lpConsoleWindow - SMALL_RECT с углами
Возврат: не 0 / FALSE. Ошибка, если координаты выходят за буфер, не выполнено Left < Right и т.п. В Windows 98 при относительном сдвиге координаты правого нижнего угла могут быть только отрицательными (особенность 98).
