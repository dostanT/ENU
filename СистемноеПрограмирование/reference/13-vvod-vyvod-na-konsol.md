Справочник. Глава 13. Ввод-вывод на консоль

Логика

- Высокий уровень: ReadConsole, WriteConsole, ReadFile, WriteFile - только СИМВОЛЫ (потоком), события мыши/размера игнорируются. ReadFile/WriteFile универсальные (консоль, файл, канал; консоль открывается как файл через CONIN$/CONOUT$), только ASCII. ReadConsole/WriteConsole только консоль, умеют ещё Unicode. Управляющие символы сами по себе не обрабатываются - это включают режимы (ENABLE_PROCESSED_*), режим принадлежит консоли, а не функции.
- ReadConsole при вводе пропускает события мыши и изменения размера.
- Низкий уровень ввода: записи INPUT_RECORD во входном буфере (очередь сообщений). ReadConsoleInput читает и УДАЛЯЕТ запись; PeekConsoleInput - читает, оставляя в очереди; WriteConsoleInput - вписать искусственное событие; GetNumberOfConsoleInputEvents - сколько записей; FlushConsoleInputBuffer - стереть очередь.
- На дескрипторе входного буфера можно ждать: WaitForSingleObject(hStdIn, INFINITE) - сигнален, когда в очереди есть запись (главы 6). Типичный цикл: ждать -> ReadConsoleInput -> switch по ir.EventType. Событие WINDOW_BUFFER_SIZE_EVENT можно обработать SetConsoleScreenBufferSize. FOCUS и MENU игнорируются.
- Низкий уровень вывода работает с ячейками буфера (CHAR_INFO). Три группы: последовательность символов (ReadConsoleOutputCharacter, WriteConsoleOutputCharacter), заливка одним символом (FillConsoleOutputCharacter), прямоугольник символ+цвет (ReadConsoleOutput, WriteConsoleOutput). Пары для ЦВЕТА - в главе 12 (те же роли). Для символов нет "SetConsoleTextCharacter": "что печатать дальше" - это просто WriteConsole/WriteFile.
- Очистка экрана: отдельной функции нет; FillConsoleOutputCharacter пробелом на весь буфер (nLength = X * Y, координата {0,0}).
- WriteConsoleOutputCharacter пишет в любую клетку и не двигает курсор.
- Координаты в Read/WriteConsoleOutput: lpReadRegion/lpWriteRegion - область НАСТОЯЩЕГО буфера; lpBuffer - ЛОКАЛЬНЫЙ массив CHAR_INFO размера dwBufferSize (X - столбцы, Y - строки); dwBufferCoord - координата внутри локального массива (обычно {0,0}). Размер массива должен соответствовать размеру области.
- Режимы (SetConsoleMode) зависят от дескриптора. Входной: ENABLE_LINE_INPUT (читать до Enter; без него - что доступно сейчас), ENABLE_ECHO_INPUT (эхо, только вместе с LINE_INPUT), ENABLE_PROCESSED_INPUT (Ctrl+C обрабатывает система; с LINE_INPUT ещё \b \r \n), ENABLE_WINDOW_INPUT (события размера окна приходят приложению), ENABLE_MOUSE_INPUT (события мыши приходят приложению). Первые три - для высокого уровня, последние два - для низкого. По умолчанию: LINE_INPUT, ECHO_INPUT, PROCESSED_INPUT. Экрана: ENABLE_PROCESSED_OUTPUT (WriteFile/WriteConsole обрабатывают \n \t \b \v \a), ENABLE_WRAP_AT_EOL_OUTPUT (перенос/прокрутка в конце строки).
- Снять один флаг: dwMode = dwMode & ~ENABLE_ECHO_INPUT. Без эха ввод "тихий" (например пароль).
- Без ENABLE_LINE_INPUT ReadFile возвращается после первого символа (читают по 1).
- Прокрутка: ScrollConsoleScreenBuffer двигает прямоугольник и заполняет освободившееся lpFill. Функция GoToNewLine: если (Y+1) < dwSize.Y - курсор вниз; иначе прокрутка вверх на строку (srScroll = строки с 1 по последнюю, Top = 1; coord {0,0}), пробел с текущими wAttributes, курсор остаётся на последней строке.
- Мышь: GetNumberOfConsoleMouseButtons - единственная функция без дескриптора консоли (мышь одна на систему).

Функции высокого уровня

BOOL ReadConsole(HANDLE hConsoleInput, LPVOID lpBuffer, DWORD nNumberOfCharsToRead, LPDWORD lpNumberOfCharsRead, LPVOID lpReserved);
- hConsoleInput - дескриптор ВХОДНОГО буфера (в книге в комментарии ошибочно "буфера экрана")
- lpBuffer - массив для символов
- nNumberOfCharsToRead - сколько символов читать
- lpNumberOfCharsRead - выходной: сколько прочитано
- lpReserved - NULL
Возврат: не 0 / FALSE.

BOOL WriteConsole(HANDLE hConsoleOutput, CONST VOID *lpBuffer, DWORD nNumberOfCharsToWrite, LPDWORD lpNumberOfCharsWritten, LPVOID lpReserved);
- hConsoleOutput - буфер экрана; lpBuffer - символы; nNumberOfCharsToWrite - сколько; lpNumberOfCharsWritten - выходной: сколько записано; lpReserved - NULL
Возврат: не 0 / FALSE.

BOOL ReadFile(HANDLE hFile, LPVOID lpBuffer, DWORD nNumberOfBytesToRead, LPDWORD lpNumberOfBytesRead, LPOVERLAPPED lpOverlapped);
BOOL WriteFile(HANDLE hFile, LPCVOID lpBuffer, DWORD nNumberOfBytesToWrite, LPDWORD lpNumberOfBytesWritten, LPOVERLAPPED lpOverlapped);
- параметры как у ReadConsole/WriteConsole, только байты; последний lpOverlapped = NULL для синхронного (в главе 13 всегда NULL; асинхронный - глава 24)
Возврат: не 0 / FALSE.

Функции низкого уровня: ввод

BOOL ReadConsoleInput(HANDLE hConsoleInput, PINPUT_RECORD lpBuffer, DWORD nLength, LPDWORD lpNumberOfEventsRead);
- hConsoleInput - входной буфер; lpBuffer - куда читать записи; nLength - сколько записей; lpNumberOfEventsRead - выходной: сколько прочитано
Прочитанная запись УДАЛЯЕТСЯ из буфера. Возврат: не 0 / FALSE.
PeekConsoleInput - те же параметры, запись остаётся в очереди.

BOOL WriteConsoleInput(HANDLE hConsoleInput, CONST INPUT_RECORD *lpBuffer, DWORD nLength, LPDWORD lpNumberOfEventsWritten);
- lpBuffer - записи для вставки; nLength - сколько; lpNumberOfEventsWritten - выходной
Эмуляция ввода (автотесты). Возврат: не 0 / FALSE.

BOOL GetNumberOfConsoleInputEvents(HANDLE hConsoleInput, LPDWORD lpNumberOfEvents);
- lpNumberOfEvents - выходной: сколько записей во входном буфере.

BOOL FlushConsoleInputBuffer(HANDLE hConsoleInput);
- очищает все непрочитанные записи.

BOOL GetNumberOfConsoleMouseButtons(LPDWORD lpNumberOfMouseButtons);
- lpNumberOfMouseButtons - выходной: число кнопок мыши. Дескриптора нет. Обычная мышь: 3.

Функции низкого уровня: вывод

BOOL ReadConsoleOutputCharacter(HANDLE hConsoleOutput, LPTSTR lpCharacter, DWORD nLength, COORD dwReadCoord, LPDWORD lpNumberOfCharsRead);
- lpCharacter - куда читать символы (выходной); nLength - сколько; dwReadCoord - координаты первого символа (читает слева направо с переходом на следующую строку); lpNumberOfCharsRead - сколько прочитано

BOOL WriteConsoleOutputCharacter(HANDLE hConsoleOutput, LPCTSTR lpCharacter, DWORD nLength, COORD dwWriteCoord, LPDWORD lpNumberOfCharsWritten);
- lpCharacter - символы; nLength - сколько; dwWriteCoord - куда (первая клетка); lpNumberOfCharsWritten - сколько записано. Курсор не двигается

BOOL FillConsoleOutputCharacter(HANDLE hConsoleOutput, TCHAR cCharacter, DWORD nLength, COORD dwWriteCoord, LPDWORD lpNumberOfCharsWritten);
- cCharacter - символ-заполнитель; nLength - длина области; dwWriteCoord - первая клетка; lpNumberOfCharsWritten - сколько заполнено. Цвет клеток не меняет

BOOL ReadConsoleOutput(HANDLE hConsoleOutput, PCHAR_INFO lpBuffer, COORD dwBufferSize, COORD dwBufferCoord, PSMALL_RECT lpReadRegion);
BOOL WriteConsoleOutput(HANDLE hConsoleOutput, CONST CHAR_INFO *lpBuffer, COORD dwBufferSize, COORD dwBufferCoord, PSMALL_RECT lpWriteRegion);
- lpBuffer - локальный массив CHAR_INFO; dwBufferSize - его размер (столбцы X, строки Y); dwBufferCoord - координата в нём первого элемента; lpReadRegion / lpWriteRegion - прямоугольник (SMALL_RECT) в буфере экрана
Все: не 0 / FALSE.

Режимы

BOOL SetConsoleMode(HANDLE hConsoleHandle, DWORD dwMode);
- hConsoleHandle - входной ИЛИ экранный дескриптор (набор флагов зависит от него)
- dwMode - комбинация флагов через |
BOOL GetConsoleMode(HANDLE hConsoleHandle, LPDWORD lpMode);
- lpMode - выходной: текущие флаги
Возврат: не 0 / FALSE.
Шаблон: GetConsoleMode(hStdIn, &dwMode); dwMode &= ~ENABLE_ECHO_INPUT; SetConsoleMode(hStdIn, dwMode);

Прокрутка

BOOL ScrollConsoleScreenBuffer(HANDLE hConsoleOutput, CONST SMALL_RECT *lpScrollRectangle, CONST SMALL_RECT *lpClipRectangle, COORD dwDestinationOrigin, CONST CHAR_INFO *lpFill);
- lpScrollRectangle - какой прямоугольник двигаем
- lpClipRectangle - прямоугольник отсечения: изменения только внутри него
- dwDestinationOrigin - куда попадёт левый верхний угол исходного прямоугольника
- lpFill - символ и атрибуты для освободившихся клеток
Возврат: не 0 / FALSE.

Опечатки книги в главе 13 (не путаться при сверке)
- в прототипе ReadConsole у hConsoleInput комментарий "дескриптор буфера экрана" - на деле входной буфер
- перед листингом 13.7 функция названа WriteConsoleInputCharacter - на деле WriteConsoleOutputCharacter
- GetNumberOfConsoleMouseButton (без s) в тексте - на деле GetNumberOfConsoleMouseButtons
- "режимы рассмотрены в разд. 13.3" - на деле 13.4
