Справочник. Глава 9. Структура консольного приложения

Функций нет - структуры данных и константы.

Логика

- Консоль = интерфейс ввода-вывода текста. Состоит из: ОДНОГО входного буфера (очередь записей событий ввода) и ОДНОГО или НЕСКОЛЬКИХ буферов экрана (двумерные массивы символов + цвет).
- Два уровня ввода-вывода: высокий (только символы; события мыши, изменения размера игнорируются) и низкий (все события консоли).
- Событий ввода пять категорий: клавиатура, мышь, изменение размера окна, фокус, меню. Фокус и меню обрабатывает система, приложение их игнорирует. Реально нужны первые три.
- Автономное нажатие Alt (без другой клавиши) в очередь приложению не попадает - его перехватывает система.

INPUT_RECORD (запись входного буфера)
struct _INPUT_RECORD { 
WORD EventType; 
union { 
KEY_EVENT_RECORD KeyEvent; 
MOUSE_EVENT_RECORD MouseEvent; 
WINDOW_BUFFER_SIZE_RECORD WindowBufferSizeEvent; 
MENU_EVENT_RECORD MenuEvent; FOCUS_EVENT_RECORD FocusEvent; } Event; }
- EventType: KEY_EVENT, MOUSE_EVENT, WINDOW_BUFFER_SIZE_EVENT, MENU_EVENT, FOCUS_EVENT
- Event - union: осмысленна только та запись, что соответствует EventType (все пять в одной области памяти)

KEY_EVENT_RECORD
- bKeyDown (BOOL) - TRUE нажата, FALSE отпущена
- wRepeatCount (WORD) - число повторов при удержании
- wVirtualKeyCode (WORD) - код клавиши, НЕ зависит от клавиатуры
- wVirtualScanCode (WORD) - код, который генерирует именно эта клавиатура (может отличаться у производителей)
- uChar (union) - UnicodeChar (WCHAR) или AsciiChar (CHAR) - сам символ
- dwControlKeyState (DWORD) - флаги: CAPSLOCK_ON, ENHANCED_KEY (правый блок клавиатуры), LEFT_ALT_PRESSED, LEFT_CTRL_PRESSED, NUMLOCK_ON, RIGHT_ALT_PRESSED, RIGHT_CTRL_PRESSED, SCROLLLOCK_ON, SHIFT_PRESSED

MOUSE_EVENT_RECORD
- dwMousePosition (COORD) - координаты курсора относительно буфера экрана
- dwButtonState (DWORD) - нажатые кнопки: FROM_LEFT_1ST_BUTTON_PRESSED, RIGHTMOST_BUTTON_PRESSED, FROM_LEFT_2ND/3RD/4TH_BUTTON_PRESSED (нумерация от левой)
- dwControlKeyState (DWORD) - те же флаги, что у клавиатуры
- dwEventFlags (DWORD) - тип события: 0 (нажата/отпущена), DOUBLE_CLICK (второе нажатие подряд), MOUSE_MOVED (сдвиг), MOUSE_WHEELED (колесо, только с Windows 2000)

WINDOW_BUFFER_SIZE_RECORD
- dwSize (COORD) - новый размер БУФЕРА экрана в символах

CHAR_INFO (ячейка буфера экрана)
struct _CHAR_INFO { union { WCHAR UnicodeChar; CHAR AsciiChar; } Char; WORD Attributes; }
- Char - символ; Attributes - цвет фона и текста
- 0 = чёрный фон, белый текст (по умолчанию)
- Флаги фона: BACKGROUND_BLUE, BACKGROUND_GREEN, BACKGROUND_RED, BACKGROUND_INTENSITY
- Флаги текста: FOREGROUND_BLUE, FOREGROUND_GREEN, FOREGROUND_RED, FOREGROUND_INTENSITY
- RGB: 3 цвета включить/выключить = 8 комбинаций; INTENSITY - ярче. Белый = все три, чёрный = ни одного.
- Без фокуса ввода система сама приглушает цвета независимо от Attributes.
