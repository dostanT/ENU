Глава 13. Ввод-вывод на консоль

Суть

Главы 10-12 разобрали, как консоль создать, как управлять её окном и буфером экрана как единым целым (размер, курсор, цвет). Эта глава - про сам процесс чтения и записи: как реально прочитать то, что ввёл пользователь, и вывести что-то на экран, на двух уровнях из главы 9 (высоком - видны только символы, и низком - видны вообще любые события), плюс отдельно - как настроить ПОВЕДЕНИЕ этого ввода-вывода (режимы) и как программно "проkрутить" уже написанный текст, когда место на экране кончилось. Это самая длинная глава части III и самая "рабочая" - именно эти функции реально читают и пишут то, что видит пользователь, а не просто настраивают консоль как объект.

13.1 Ввод-вывод высокого уровня

Вспомни аналогию из главы 9 (раздел 9.1) - телефонный звонок против видеоконференции. Функции этого раздела - ReadConsole, WriteConsole, ReadFile и WriteFile - это как раз "телефонный звонок": им вообще не важно, что ещё происходит в консоли (мышь, изменение размера окна) - только сами символы. Первые две функции умеют говорить ТОЛЬКО с консолью. Вторые две - более универсальные "операторы": с равным успехом дозвонятся и до консоли, и до обычного файла, и до канала передачи данных, потому что консоль в Windows, как уже было в главе 10 (раздел 10.3), можно открыть как обычный файл через имена CONIN$/CONOUT$ - а раз это открывается как файл, то и читать/писать в него можно теми же самыми "файловыми" функциями.

Чтение строки символов из входного буфера консоли - функция ReadConsole:

```
BOOL ReadConsole(
    HANDLE   hConsoleInput,         // дескриптор входного буфера консоли
    LPVOID   lpBuffer,              // массив для ввода символов
    DWORD    nNumberOfCharsToRead,  // количество читаемых символов
    LPDWORD  lpNumberOfCharsRead,   // количество прочитанных символов
    LPVOID   lpReserved             // зарезервировано
);
```

При успехе возвращает ненулевое значение, при неудаче - FALSE. lpReserved всегда должен быть NULL. ReadConsole вводит символы последовательно друг за другом, при этом курсор передвигается в следующую свободную позицию. Если включён режим отображения введённых символов (эхо-вывод), а он включён по умолчанию, то при вводе символы отображаются на экране - подробно режимы ввода-вывода разбираются в разделе 13.4 этой же главы. Кроме того, пока идёт ввод символов из входного буфера, эта функция игнорирует все остальные события ввода (мышь, изменение размера окна) - если они пришли, ReadConsole их просто пропускает, как будто их не было.

Запись строки символов в буфер экрана - функция WriteConsole:

```
BOOL WriteConsole(
    HANDLE   hConsoleOutput,          // дескриптор буфера экрана
    CONST VOID *lpBuffer,             // массив с символами для вывода
    DWORD    nNumberOfCharsToWrite,   // количество записываемых символов
    LPDWORD  lpNumberOfCharsWritten,  // количество записанных символов
    LPVOID   lpReserved                // зарезервировано
);
```

При успехе - ненулевое значение, при неудаче - FALSE. lpReserved также всегда NULL.

Пример - чтение и запись строки через ReadConsole/WriteConsole

Листинг 13.1 выводит приглашение, читает строку с клавиатуры, затем ждёт любой символ перед выходом:

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    HANDLE hStdOut, hStdIn;  // дескрипторы консоли
    DWORD  dwWritten, dwRead;// для количества символов
    char   buffer[80];       // для ввода символов
    char   str[] = "Input any string:";
    char   c;

    // читаем дескрипторы консоли
    hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
    hStdIn  = GetStdHandle(STD_INPUT_HANDLE);
    if (hStdOut == INVALID_HANDLE_VALUE || hStdIn == INVALID_HANDLE_VALUE)
    {
        cout << "Get standard handle failed." << endl;
        return GetLastError();
    }
    // выводим сообщения о вводе строки
    if (!WriteConsole(hStdOut, &str, sizeof(str), &dwWritten, NULL))
    {
        cout << "Write console failed." << endl;
        return GetLastError();
    }
    // вводим строку
    if (!ReadConsole(hStdIn, &buffer, sizeof(buffer), &dwRead, NULL))
    {
        cout << "Read console failed." << endl;
        return GetLastError();
    }
    // ждем команду на завершение работы
    cout << "Input any char to exit: ";
    cin >> c;

    return 0;
}
```

Не скомпилировано по-настоящему (нет Windows) - проверено по документации и логике API. Механизм по шагам: WriteConsole печатает приглашение "Input any string:", ReadConsole ждёт, пока пользователь наберёт строку и нажмёт Enter (по умолчанию действует построчный режим ввода - см. раздел 13.4), сама набираемая строка при этом автоматически появляется на экране (эхо-вывод, тоже по умолчанию), и только после этого управление возвращается программе.

Теперь про ReadFile и WriteFile - тот самый "универсальный оператор". По списку параметров они аналогичны ReadConsole/WriteConsole, единственное отличие - последний параметр указывает на синхронный или асинхронный ввод-вывод (подробно это разбирается в главе 24, про файлы; в примерах этой главы он всегда NULL, то есть синхронный).

Пример - чтение и запись строки через ReadFile/WriteFile

Листинг 13.2 делает то же самое, что листинг 13.1, но универсальными файловыми функциями, в цикле, пока не введут "q":

```c
#include <windows.h>

HANDLE hStdOut, hStdIn;

int main(void)
{
    LPSTR lpszPrompt1 = "Input 'q' and press Enter to exit.\n";
    LPSTR lpszPrompt2 = "Input string and press Enter:\n";
    CHAR  chBuffer[80];
    DWORD cRead, cWritten;

    // читаем дескрипторы стандартного ввода и вывода
    hStdIn  = GetStdHandle(STD_INPUT_HANDLE);
    hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hStdIn == INVALID_HANDLE_VALUE || hStdOut == INVALID_HANDLE_VALUE)
    {
        MessageBox(NULL, "Get standard handle failed", "Win32 API error",
            MB_OK | MB_ICONINFORMATION);
        return GetLastError();
    }
    // по умолчанию установлены режимы ввода: ENABLE_LINE_INPUT,
    // ENABLE_ECHO_INPUT, ENABLE_PROCESSED_INPUT

    // выводим сообщение о том, как выйти из цикла чтения
    if (!WriteFile(
        hStdOut,               // дескриптор стандартного вывода
        lpszPrompt1,            // строка, которую выводим
        lstrlen(lpszPrompt1),   // длина строки
        &cWritten,              // количество записанных байтов
        NULL))                  // синхронный вывод
    {
        MessageBox(NULL, "Write file failed", "Win32 API error",
            MB_OK | MB_ICONINFORMATION);
        return GetLastError();
    }
    // цикл чтения
    for (;;)
    {
        // выводим сообщение о вводе строки
        if (!WriteFile(hStdOut, lpszPrompt2, lstrlen(lpszPrompt2),
            &cWritten, NULL))
        {
            MessageBox(NULL, "Write file failed", "Win32 API error",
                MB_OK | MB_ICONINFORMATION);
            return GetLastError();
        }
        // вводим строку с клавиатуры и дублируем ее на экран
        if (!ReadFile(
            hStdIn,     // дескриптор стандартного ввода
            chBuffer,   // буфер для чтения
            80,         // длина буфера
            &cRead,     // количество прочитанных байтов
            NULL))      // синхронный ввод
        {
            MessageBox(NULL, "Write file failed", "Win32 API error",
                MB_OK | MB_ICONINFORMATION);
            return GetLastError();
        }
        // выход из программы
        if (chBuffer[0] == 'q')
            return 1;
    }

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API. Обрати внимание: в этом листинге НЕТ отдельного вызова WriteFile, который бы "дублировал" введённую строку на экран - и тем не менее комментарий в коде говорит "дублируем ее на экран". Дублирование происходит само, бесплатно, потому что входной дескриптор находится в режиме ENABLE_ECHO_INPUT (это и есть тот самый режим по умолчанию, о котором явно написано в комментарии чуть выше) - систем сама печатает на экран каждый символ, который ты вводишь, ReadFile для этого ничего специально не делает.

В конце раздела книга явно поясняет разницу между всеми четырьмя функциями. С консолью WriteFile, ReadFile, WriteConsole и ReadConsole читают и записывают символы ПОТОКОМ (последовательно, символ за символом, а не структурированными записями - это отличие важно держать в голове для сравнения со следующим разделом). ReadFile и WriteFile работают только с символами в кодировке ASCII. ReadConsole и WriteConsole отличаются от файловых функций только тем, что умеют работать ещё и с Unicode-символами. Управляющие символы (переводы строк и т.п.) сами по себе ReadConsole/WriteConsole не обрабатывают - обработку конкретных управляющих символов включает отдельный режим (ENABLE_PROCESSED_OUTPUT/ENABLE_PROCESSED_INPUT), разобранный в разделе 13.4, и этот режим действует одинаково что для файловых, что для консольных функций - потому что режим принадлежит самому объекту-консоли, а не конкретной функции, через которую к ней обращаются.

13.2 Ввод низкого уровня

Функции этого раздела работают не с "текстом", а напрямую с ЗАПИСЯМИ входного буфера консоли - то есть со структурой INPUT_RECORD из главы 9 (раздел 9.2, тегированный union на пять типов событий: клавиатура, мышь, изменение размера окна, фокус, меню). Раз каждое событие - это отдельная запись в очереди, то и логика работы с очередью такая же, как с любой очередью сообщений: можно прочитать следующее сообщение (и оно исчезнет из очереди), можно подсмотреть его не трогая (как непрочитанное уведомление на экране блокировки - текст уже видно, но сообщение остаётся непрочитанным, ждёт открытия), можно самому вписать в очередь искусственное сообщение, можно посчитать, сколько сообщений скопилось, можно вообще стереть всю очередь разом.

Чтение записей из входного буфера - функция ReadConsoleInput:

```
BOOL ReadConsoleInput(
    HANDLE         hConsoleInput,        // дескриптор входного буфера консоли
    PINPUT_RECORD  lpBuffer,             // буфер данных
    DWORD          nLength,              // количество читаемых записей
    LPDWORD        lpNumberOfEventsRead  // количество прочитанных записей
);
```

При успехе - ненулевое значение, при неудаче - FALSE. Важная деталь: после того как запись прочитана функцией ReadConsoleInput, она УДАЛЯЕТСЯ из входного буфера - то есть это "открыть сообщение", оно пропадает из очереди непрочитанных. hConsoleInput - дескриптор входного буфера консоли. lpBuffer - куда читать записи. nLength - сколько записей хотим прочитать. lpNumberOfEventsRead - по этому адресу функция вернёт, сколько записей реально прочиталось.

Если нужно прочитать записи, НЕ удаляя их из очереди (это "подсмотреть уведомление, не открывая"), используется функция PeekConsoleInput - её параметры полностью совпадают с параметрами ReadConsoleInput, отдельного прототипа книга для неё не приводит именно поэтому.

Пример - обработка всех типов событий входного буфера

Листинг 13.3 - цикл, который вызывает ReadConsoleInput по одной записи за раз и диспетчеризует её по типу события через switch по полю EventType (сравни со структурой INPUT_RECORD из lectures/09, раздел 9.2 - тут используется ровно она):

```c
#include <windows.h>
#include <iostream.h>

HANDLE hStdIn, hStdOut;  // для дескрипторов стандартного ввода и вывода
BOOL   bRead = TRUE;      // для цикла обработки событий

// функция обработки сообщений от клавиатуры
VOID KeyEventProc(KEY_EVENT_RECORD kir)
{
    cout << "\tKey event record:" << endl;
    // просто выводим на консоль содержимое записи
    cout << "bKeyDown = " << hex << kir.bKeyDown << endl;
    cout << "wRepeatCount = " << dec << kir.wRepeatCount << endl;
    cout << "wVirtualKeyCode = " << hex << kir.wVirtualKeyCode << endl;
    cout << "wVirtualScanCode = " << kir.wVirtualScanCode << endl;
    cout << "uChar.AsciiChar = " << kir.uChar.AsciiChar << endl;
    cout << "dwControlKeyState = " << kir.dwControlKeyState << endl;

    // если ввели букву 'q', то выходим из цикла обработки событий
    if (kir.uChar.AsciiChar == 'q')
        bRead = FALSE;
}

// функция обработки сообщений от мыши
VOID MouseEventProc(MOUSE_EVENT_RECORD mer)
{
    cout << "\tMouse event record:" << endl << dec;
    // просто выводим на консоль содержимое записи
    cout << "dwMousePosition.X = " << mer.dwMousePosition.X << endl;
    cout << "dwMousePosition.Y = " << mer.dwMousePosition.Y << endl;
    cout << "dwButtonState = " << hex << mer.dwButtonState << endl;
    cout << "dwControlKeyState = " << mer.dwControlKeyState << endl;
    cout << "dwEventFlags = " << mer.dwEventFlags << endl;
}

// функция обработки сообщения об изменении размеров окна
VOID ResizeEventProc(WINDOW_BUFFER_SIZE_RECORD wbsr)
{
    // изменяем размеры буфера вывода
    SetConsoleScreenBufferSize(hStdOut, wbsr.dwSize);
}

int main()
{
    INPUT_RECORD ir;         // входная запись
    DWORD        cNumRead;   // для количества прочитанных записей

    // получить дескрипторы стандартного ввода и вывода
    hStdIn = GetStdHandle(STD_INPUT_HANDLE);
    if (hStdIn == INVALID_HANDLE_VALUE)
    {
        cout << "Get standard input handle failed." << endl;
        return GetLastError();
    }
    hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hStdOut == INVALID_HANDLE_VALUE)
    {
        cout << "Get standard output handle failed." << endl;
        return GetLastError();
    }
    // начинаем обработку событий ввода
    cout << "Begin input event queue processing." << endl;
    cout << "Input 'q' to quit." << endl << endl;
    // цикл обработки событий ввода
    while (bRead)
    {
        // ждем событие ввода
        WaitForSingleObject(hStdIn, INFINITE);

        // читаем запись ввода
        if (!ReadConsoleInput(
            hStdIn,     // дескриптор ввода
            &ir,        // буфер для записи
            1,          // читаем одну запись
            &cNumRead)) // количество прочитанных записей
        {
            cout << "Read console input failed." << endl;
            break;
        }

        // вызываем соответствующий обработчик
        switch (ir.EventType)
        {
        case KEY_EVENT:  // событие ввода с клавиатуры
            KeyEventProc(ir.Event.KeyEvent);
            break;

        case MOUSE_EVENT:  // событие ввода с мыши
            MouseEventProc(ir.Event.MouseEvent);
            break;

        case WINDOW_BUFFER_SIZE_EVENT:  // изменения размеров окна
            ResizeEventProc(ir.Event.WindowBufferSizeEvent);
            break;

        case FOCUS_EVENT:  // события фокуса ввода игнорируем
            break;

        case MENU_EVENT:  // события меню игнорируем
            break;

        default:  // неизвестное событие
            cout << "Unknown event type.";
            break;
        }
    }

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API. Механизм: WaitForSingleObject(hStdIn, INFINITE) - вход в консоль сам является объектом ядра, на котором можно ждать (см. главу 6) - он "сигнален", когда в очереди есть хотя бы одна необработанная запись; когда дождались, ReadConsoleInput читает ровно одну запись и удаляет её из очереди; switch по ir.EventType вызывает нужный обработчик - для KEY_EVENT печатает все поля KeyEventRecord и проверяет, не 'q' ли это (тогда выставляет bRead=FALSE и цикл на следующей итерации завершится); для MOUSE_EVENT просто печатает поля; для WINDOW_BUFFER_SIZE_EVENT не печатает ничего, а сразу вызывает SetConsoleScreenBufferSize (глава 12, раздел 12.2) с новым размером - то есть буфер экрана программно подстраивается под новый размер окна; FOCUS_EVENT и MENU_EVENT явно игнорируются (как и предупреждала глава 9 - это два типа событий, которые обрабатывает сама система, а не приложение).

Книга отдельно отмечает практическую деталь именно про этот пример: в Windows 2000 листинг 13.3 нормально работает только в полноэкранном режиме консоли. Чтобы он заработал и в обычном оконном режиме (для русской локализации), нужно правой кнопкой мыши щёлкнуть по значку консольного приложения, перейти на вкладку "Общие" в свойствах и снять флажок "Выделение мышью" в группе "Редактирование" - иначе система сама перехватывает мышь для выделения текста, и события мыши до программы просто не доходят.

Запись событий во входной буфер (искусственно, программой, а не реальным пользователем) - функция WriteConsoleInput:

```
BOOL WriteConsoleInput(
    HANDLE               hConsoleInput,          // дескриптор входного буфера консоли
    CONST INPUT_RECORD  *lpBuffer,                // указатель на буфер с записями
    DWORD                nLength,                 // количество записываемых записей
    LPDWORD              lpNumberOfEventsWritten  // количество записанных записей
);
```

При успехе - ненулевое значение, при неудаче - FALSE. Это как самому заполнить бланк на ресепшене за клиента, а не ждать, пока клиент придёт и заполнит сам: программа кладёт в очередь входного буфера запись о событии, как будто его сгенерировал реальный пользователь. Пригодится, например, для автотестирования (эмулировать нажатия клавиш без живого человека за клавиатурой).

Количество записей, уже накопившихся во входном буфере - функция GetNumberOfConsoleInputEvents:

```
BOOL GetNumberOfConsoleInputEvents(
    HANDLE   hConsoleInput,      // дескриптор входного буфера консоли
    LPDWORD  lpNumberOfEvents    // указатель на количество записей
);
```

При успехе - ненулевое значение, при неудаче - FALSE.

Очистка входного буфера целиком (все накопленные, ещё не прочитанные события выбрасываются разом) - функция FlushConsoleInputBuffer:

```
BOOL FlushConsoleInputBuffer(
    HANDLE hConsoleInput  // дескриптор входного буфера консоли
);
```

При успехе - ненулевое значение, при неудаче - FALSE.

Пример - запись события, подсчёт записей и очистка буфера ввода

Листинг 13.4 показывает все три функции подряд: сначала считает, сколько записей уже есть в буфере, потом сам записывает туда одну искусственную запись о нажатии клавиши, снова считает (число должно увеличиться на 1), затем очищает буфер и считает третий раз (должен получиться 0):

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    HANDLE       hStdIn;          // для дескриптора стандартного ввода
    INPUT_RECORD ir;              // входная запись
    DWORD        dwNumberWritten; // количество записанных записей
    DWORD        dwNumber;        // для количества записей в буфере ввода

    // получить дескриптор стандартного ввода
    hStdIn = GetStdHandle(STD_INPUT_HANDLE);
    if (hStdIn == INVALID_HANDLE_VALUE)
    {
        cout << "Get standard input handle failed." << endl;
        return GetLastError();
    }
    // подсчитываем записи в буфере ввода
    if (!GetNumberOfConsoleInputEvents(hStdIn, &dwNumber))
    {
        cout << "Get number of console input events failed." << endl;
        return GetLastError();
    }
    // печатаем количество событий ввода
    cout << "Number of console input events = " << dwNumber << endl;
    // инициализируем запись события ввода
    ir.EventType = KEY_EVENT;
    ir.Event.KeyEvent.bKeyDown = 0x1;
    ir.Event.KeyEvent.wRepeatCount = 1;
    ir.Event.KeyEvent.wVirtualKeyCode = 0x43;
    ir.Event.KeyEvent.wVirtualScanCode = 0x2e;
    ir.Event.KeyEvent.uChar.AsciiChar = 'c';
    ir.Event.KeyEvent.dwControlKeyState = 0x20;
    // записываем запись в буфер ввода
    if (!WriteConsoleInput(hStdIn, &ir, 1, &dwNumberWritten))
    {
        cout << "Write console input failed." << endl;
        return GetLastError();
    }
    cout << "Write one record into the input buffer." << endl;
    // подсчитываем записи в буфере ввода
    if (!GetNumberOfConsoleInputEvents(hStdIn, &dwNumber))
    {
        cout << "Get number of console input events failed." << endl;
        return GetLastError();
    }
    // печатаем количество событий ввода
    cout << "Number of console input events = " << dwNumber << endl;
    // очищаем входной буфер
    cout << "Flush console input buffer." << endl;
    if (!FlushConsoleInputBuffer(hStdIn))
    {
        cout << "Flush console input buffer failed." << endl;
        return GetLastError();
    }
    // подсчитываем записи в буфере ввода
    if (!GetNumberOfConsoleInputEvents(hStdIn, &dwNumber))
    {
        cout << "Get number of console input events failed." << endl;
        return GetLastError();
    }
    // печатаем количество событий ввода
    cout << "Number of console input events = " << dwNumber << endl;

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API. По логике API вывод должен быть примерно такой последовательностью: сначала какое-то небольшое число (сколько событий пользователь уже успел накопить до этого момента, например 0, если ничего не нажимал), затем то же число +1 (после WriteConsoleInput), затем 0 (после FlushConsoleInputBuffer, вне зависимости от того, что было до очистки).

Количество кнопок у мыши, подключённой к системе - функция GetNumberOfConsoleMouseButtons:

```
BOOL GetNumberOfConsoleMouseButtons(
    LPDWORD lpNumberOfMouseButtons  // количество кнопок у мыши
);
```

При успехе - ненулевое значение, при неудаче - FALSE; по адресу lpNumberOfMouseButtons функция запишет число кнопок. Обрати внимание - это ЕДИНСТВЕННАЯ функция во всей главе 13, у которой в параметрах нет дескриптора консоли вообще. И это не опечатка: мышь - это одно физическое устройство на весь компьютер, она не привязана к конкретной консоли или конкретному процессу, поэтому и спрашивать "сколько у неё кнопок" бессмысленно через дескриптор чего бы то ни было - ответ один и тот же для всей системы.

Пример - определение количества кнопок мыши

Листинг 13.5:

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    DWORD dwNumber;  // для количества кнопок у мыши

    // подсчитываем количество кнопок у мыши
    if (!GetNumberOfConsoleMouseButtons(&dwNumber))
    {
        cout << "Get number of console mouse buttons failed." << endl;
        return GetLastError();
    }
    // выводим количество кнопок у мыши
    cout << "Number of console mouse buttons = " << dwNumber << endl;

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API. По логике API для обычной мыши с левой, правой кнопками и колесом-кнопкой результат должен быть 3.

13.3 Вывод низкого уровня

Эти функции работают напрямую с элементами буфера экрана - то есть с ячейками CHAR_INFO из главы 9 (раздел 9.3: символ + Attributes в одной структуре). Книга делит их на три группы: чтение/запись ПОСЛЕДОВАТЕЛЬНОСТИ символов подряд (ReadConsoleOutputCharacter, WriteConsoleOutputCharacter), заполнение диапазона ОДНИМ символом (FillConsoleOutputCharacter), и чтение/запись целого ПРЯМОУГОЛЬНИКА символов сразу с их атрибутами (ReadConsoleOutput, WriteConsoleOutput).

Заметь: глава 12 (раздел 12.4) уже показывала практически такую же четвёрку функций - но для ЦВЕТА ячеек (SetConsoleTextAttribute/FillConsoleOutputAttribute/WriteConsoleOutputAttribute/ReadConsoleOutputAttribute, см. lectures/12). Здесь та же самая схема ролей, но не для цвета, а для самих СИМВОЛОВ. Только ролей тут не четыре, а фактически три - потому что роль "задать значение для БУДУЩЕГО вывода" (как SetConsoleTextAttribute для цвета) для символов отдельной функции не требует: то, что будет напечатано ДАЛЬШЕ, и так целиком определяется вызовом WriteConsole/WriteFile из раздела 13.1 - специальной "SetConsoleTextCharacter" просто не существует, потому что эту роль уже закрывает раздел 13.1.

Группа 1 - чтение и запись последовательности символов.

Чтение последовательности символов из буфера экрана - функция ReadConsoleOutputCharacter:

```
BOOL ReadConsoleOutputCharacter(
    HANDLE   hConsoleOutput,       // дескриптор буфера экрана
    LPTSTR   lpCharacter,          // указатель на буфер с символами
    DWORD    nLength,              // количество читаемых символов
    COORD    dwReadCoord,          // координаты первого читаемого символа
    LPDWORD  lpNumberOfCharsRead   // количество прочитанных символов
);
```

При успехе - ненулевое значение, при неудаче - FALSE. dwReadCoord задаёт координаты (столбец, строка) первого символа, с которого начинается чтение - дальше читаются nLength символов ПОДРЯД, слева направо, с переходом на следующую строку буфера, если строка кончилась.

Пример - чтение последовательности символов из буфера экрана

Листинг 13.6 печатает 'a' и 'b', затем читает их обратно из буфера экрана и печатает количество и сами прочитанные символы:

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    HANDLE hConsoleOutput;                  // для дескриптора буфера экрана
    CHAR   lpBuffer[80];                    // буфер для ввода
    COORD  dwReadCoord = {0, 0};            // координаты первого элемента в буфере
    DWORD  nNumberOfCharsRead;               // количество прочитанных символов

    // получаем дескриптор буфера экрана
    hConsoleOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hConsoleOutput == INVALID_HANDLE_VALUE)
    {
        cout << "Get standard handle failed." << endl;
        return GetLastError();
    }
    // выводим те символы, которые будем читать
    cout << 'a' << 'b' << endl;
    // читаем эти символы в буфер
    if (!ReadConsoleOutputCharacter(
        hConsoleOutput,     // дескриптор буфера экрана
        lpBuffer,           // буфер для ввода символов
        2,                  // количество читаемых символов
        dwReadCoord,        // координата первого символа
        &nNumberOfCharsRead)) // количество прочитанных символов
    {
        cout << "Read consoleoutput character failed." << endl;
        return GetLastError();
    }
    // выводим количество прочитанных символов и сами символы
    cout << "Number of chars read: " << nNumberOfCharsRead << endl;
    cout << "Read chars: " << lpBuffer[0] << lpBuffer[1] << endl;

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API. По логике API должно напечататься: сначала "ab", затем "Number of chars read: 2", затем "Read chars: ab" - то есть символы, только что напечатанные на экран через cout, действительно физически лежат в буфере экрана как данные, и их можно прочитать оттуда обратно отдельной функцией, а не только увидеть глазами.

Запись последовательности символов в буфер экрана - функция WriteConsoleOutputCharacter:

```
BOOL WriteConsoleOutputCharacter(
    HANDLE   hConsoleOutput,          // дескриптор буфера экрана
    LPCTSTR  lpCharacter,             // указатель на массив символов
    DWORD    nLength,                 // количество записываемых символов
    COORD    dwWriteCoord,            // координаты первого символа в буфере экрана
    LPDWORD  lpNumberOfCharsWritten   // количество символов, записанных в буфер экрана
);
```

При успехе - ненулевое значение, при неудаче - FALSE. Записывает последовательность символов lpCharacter в буфер экрана начиная с позиции dwWriteCoord, длиной nLength символов. Обрати внимание: книга во вступительном предложении перед листингом 13.7 по ошибке называет эту функцию "WriteConsoleInputCharacter" - это опечатка (перепутано Input/Output), сама сигнатура функции и код листинга используют правильное имя WriteConsoleOutputCharacter, оно и есть верное.

Пример - запись последовательности символов в буфер экрана

Листинг 13.7:

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    HANDLE hConsoleOutput;                    // для дескриптора буфера экрана
    CHAR   lpBuffer[] = "abcd";                // буфер с символами для вывода
    COORD  dwWriteCoord = {10, 10};            // координаты первого элемента в буфере
    DWORD  nNumberOfCharsWritten;               // количество записанных символов

    // получаем дескриптор буфера экрана
    hConsoleOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hConsoleOutput == INVALID_HANDLE_VALUE)
    {
        cout << "Get standard handle failed." << endl;
        return GetLastError();
    }
    // записываем символы в буфер экрана
    if (!WriteConsoleOutputCharacter(
        hConsoleOutput,        // дескриптор буфера экрана
        lpBuffer,               // буфер для ввода символов
        sizeof(lpBuffer),       // количество записываемых символов
        dwWriteCoord,           // координата первого символа
        &nNumberOfCharsWritten)) // количество записанных символов
    {
        cout << "Read console output character failed." << endl;
        return GetLastError();
    }
    // выводим количество записанных символов
    cout << "Number of chars written: " << nNumberOfCharsWritten << endl;

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API. Разница с обычным cout/WriteConsole принципиальна: здесь можно написать текст НЕ в текущую позицию курсора, а в любую произвольную клетку (10, 10), не трогая курсор вообще - курсор после этого вызова остаётся там же, где и был.

Группа 2 - заполнение буфера экрана одним символом.

```
BOOL FillConsoleOutputCharacter(
    HANDLE   hConsoleOutput,          // дескриптор буфера экрана
    TCHAR    cCharacter,              // символ-заполнитель
    DWORD    nLength,                 // длина заполняемой области
    COORD    dwWriteCoord,            // координаты первой клетки буфера экрана
    LPDWORD  lpNumberOfCharsWritten   // количество заполненных клеток
);
```

При успехе - ненулевое значение, при неудаче - FALSE. Ровно тот же принцип, что у FillConsoleOutputAttribute из главы 12 (раздел 12.4) - заполняет nLength клеток подряд, начиная с dwWriteCoord, одним и тем же символом cCharacter, не трогая цвет клеток.

Пример - заполнение и очистка буфера экрана символом

Листинг 13.8 сначала заполняет весь буфер введённым пользователем символом, затем очищает его пробелами - вот так на практике и устроена "очистка экрана" в консольных программах, отдельной функции ClearScreen в Win32 API нет, это FillConsoleOutputCharacter с символом-пробелом на весь размер буфера:

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    char                        c;
    HANDLE                      hStdOut;    // дескриптор стандартного вывода
    DWORD                       dwLength;   // количество заполняемых клеток
    DWORD                       dwWritten;  // для количества заполненных клеток
    COORD                       coord;      // координаты первой клетки
    CONSOLE_SCREEN_BUFFER_INFO  csbi;       // для параметров буфера экрана

    // читаем дескриптор стандартного вывода
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
    // устанавливаем координаты первой клетки
    coord.X = 0;
    coord.Y = 0;
    // вводим символ-заполнитель
    cout << "Input any char to fill screen buffer: ";
    cin >> c;
    // заполняем буфер экрана символом-заполнителем
    if (!FillConsoleOutputCharacter(hStdOut, c, dwLength, coord, &dwWritten))
    {
        cout << "Fill console output character failed." << endl;
        return GetLastError();
    }
    // ждем команды на очищение буфера экрана
    cout << "In order to clear screen buffer, press any char: ";
    cin >> c;
    // очищаем буфер экрана пробелами
    if (!FillConsoleOutputCharacter(hStdOut, ' ', dwLength, coord, &dwWritten))
    {
        cout << "Fill console output character failed." << endl;
        return GetLastError();
    }

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API.

Группа 3 - чтение и запись прямоугольных областей (символ + цвет сразу, через CHAR_INFO).

```
BOOL ReadConsoleOutput(
    HANDLE       hConsoleOutput,   // дескриптор буфера экрана
    PCHAR_INFO   lpBuffer,         // указатель на буфер с данными
    COORD        dwBufferSize,     // размер буфера с данными
    COORD        dwBufferCoord,    // координаты для первого элемента в буфере
    PSMALL_RECT  lpReadRegion      // область ввода в буфере экрана
);
```

При успехе - ненулевое значение, при неудаче - FALSE. Тут две РАЗНЫЕ системы координат, легко перепутать: lpReadRegion - это какой кусок НАСТОЯЩЕГО буфера экрана консоли читаем (левый верхний и правый нижний углы прямоугольника); lpBuffer - это ТВОЙ СОБСТВЕННЫЙ локальный массив в памяти программы, куда это складывается, и функция обращается с ним как с двумерным массивом CHAR_INFO размера dwBufferSize (X - столбцы, Y - строки), а dwBufferCoord - это координата ВНУТРИ этого локального массива, с которой начинается запись (обычно просто (0,0) - с самого начала своего массива).

Пример - чтение прямоугольной области из буфера экрана

Листинг 13.9 читает область 2x2 клетки (символы 'a','b' на первой строке и 'c','d' на второй) обратно из буфера экрана:

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    HANDLE     hConsoleOutput;               // для дескриптора буфера экрана
    CHAR_INFO  lpBuffer[4];                  // буфер для ввода
    COORD      dwBufferSize = {2, 2};        // размеры буфера
    COORD      dwBufferCoord = {0, 0};       // координаты первого элемента в буфере
    SMALL_RECT ReadRegion = {0, 0, 1, 1};    // прямоугольник, который читаем

    // выводим символы, которые будем читать
    cout << 'a' << 'b' << endl << 'c' << 'd' << endl;
    // получаем дескриптор вывода
    hConsoleOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hConsoleOutput == INVALID_HANDLE_VALUE)
    {
        cout << "Get standard handle failed." << endl;
        return GetLastError();
    }
    // читаем символы
    if (!ReadConsoleOutput(hConsoleOutput, lpBuffer, dwBufferSize,
        dwBufferCoord, &ReadRegion))
    {
        cout << "Read console input failed." << endl;
        return GetLastError();
    }
    // распечатываем прочитанные символы
    cout << "Read cells." << hex << endl;
    for (int i = 0; i < 4; ++i)
        cout << lpBuffer[i].Attributes << ' ' << lpBuffer[i].Char.AsciiChar << endl;

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API. Размер локального массива (4 = 2x2) специально подобран точно под размер читаемого прямоугольника (0,0)-(1,1), который тоже 2x2 клетки - это не случайность, а обязательное условие: сколько клеток описывает lpReadRegion, столько элементов и должно быть в lpBuffer, иначе либо часть данных не поместится, либо часть массива останется незаполненной.

```
BOOL WriteConsoleOutput(
    HANDLE            hConsoleOutput,   // дескриптор буфера экрана
    CONST CHAR_INFO  *lpBuffer,         // указатель на буфер с данными
    COORD             dwBufferSize,     // размер буфера с данными
    COORD             dwBufferCoord,    // координаты первого элемента в буфере
    PSMALL_RECT       lpWriteRegion     // область вывода в буфере экрана
);
```

При успехе - ненулевое значение, при неудаче - FALSE. Записывает символы и их атрибуты из lpBuffer в область буфера экрана, заданную lpWriteRegion. Остальные параметры имеют тот же смысл, что у ReadConsoleOutput.

Пример - заполнение прямоугольной области в буфере экрана

Листинг 13.10 заполняет массив ci размером во весь стандартный экран (80 столбцов на 25 строк) одним и тем же цветом (синий фон) и пробелами, а затем записывает его в прямоугольник буфера экрана, координаты которого вводит пользователь:

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    HANDLE     hStdOut;         // дескриптор стандартного вывода
    CHAR_INFO  ci[80*25];       // прямоугольник, из которого будем выводить
    COORD      size;            // размеры этого прямоугольника
    // координаты левого угла прямоугольника, из которого выводим
    COORD      coord;
    // координаты левого угла прямоугольника, в который пишем
    SMALL_RECT sr;

    // читаем стандартный дескриптор вывода
    hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
    // заполняем прямоугольник, который будем выводить, пробелами
    for (int i = 0; i < 80*25; ++i)
    {
        ci[i].Char.AsciiChar = ' ';
        ci[i].Attributes = BACKGROUND_BLUE | BACKGROUND_INTENSITY;
    }
    // устанавливаем левый угол многоугольника, из которого пишем
    coord.X = 0;
    coord.Y = 0;
    // устанавливаем размеры прямоугольника, который пишем
    size.X = 80;
    size.Y = 25;
    // вводим координаты левого верхнего угла многоугольника,
    // в который пишем
    cout << "Input left coordinate to write: ";
    cin >> sr.Left;
    cout << "Input top coordinate to write: ";
    cin >> sr.Top;
    // вводим координаты правого нижнего угла многоугольника,
    // в который пишем
    cout << "Input right coordinate to write: ";
    cin >> sr.Right;
    cout << "Input down coordinate to write: ";
    cin >> sr.Bottom;

    // пишем прямоугольник в буфер экрана
    if (!WriteConsoleOutput(
        hStdOut,   // дескриптор буфера экрана
        ci,        // прямоугольник, из которого пишем
        size,      // размеры этого прямоугольника
        coord,     // и его левый угол
        &sr))      // прямоугольник, в который пишем
    {
        cout << "Write console output failed." << endl;
        return GetLastError();
    }

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API. Размер локального массива ci здесь жёстко зашит как 80x25 (типичный стандартный размер консоли), а не вычислен через GetConsoleScreenBufferInfo, как это делалось в некоторых листингах главы 12 - если у реального пользователя буфер экрана окажется другого размера, этот конкретный листинг работал бы некорректно (за пределами введённого пользователем прямоугольника массив ci просто не был бы полностью использован либо, наоборот, не хватило бы данных - книга не разбирает этот случай отдельно, а просто фиксирует размер).

13.4 Режимы ввода-вывода консоли

Уже несколько раз в этой главе встречались фразы вроде "по умолчанию включён режим построчного ввода" или "по умолчанию включён режим эхо-вывода" - раздел 13.4 наконец объясняет, откуда берутся эти режимы и как их менять. Установка режимов - функция SetConsoleMode:

```
BOOL SetConsoleMode(
    HANDLE  hConsoleHandle,  // дескриптор ввода или вывода
    DWORD   dwMode           // режим ввода или вывода
);
```

При успехе - ненулевое значение, при неудаче - FALSE. Смысл dwMode зависит от того, ЧТО за дескриптор передан в hConsoleHandle - входного буфера или буфера экрана, наборы флагов разные.

Если hConsoleHandle - это дескриптор ВХОДНОГО буфера, dwMode - произвольная комбинация (через побитовое ИЛИ) следующих флагов:

- ENABLE_LINE_INPUT - функции ReadFile и ReadConsole читают символы, пока не встретят Enter; без этого флага читается всё, что уже доступно во входном буфере на момент вызова, не дожидаясь Enter.
- ENABLE_ECHO_INPUT - прочитанные символы выводятся на экран (то самое "эхо"); имеет смысл только вместе с ENABLE_LINE_INPUT.
- ENABLE_PROCESSED_INPUT - комбинация Ctrl+C обрабатывается самой системой; если используется вместе с ENABLE_LINE_INPUT, системой же обрабатываются и управляющие символы \b, \r, \n.
- ENABLE_WINDOW_INPUT - события изменения размера окна обрабатываются приложением.
- ENABLE_MOUSE_INPUT - события от мыши обрабатываются приложением.

Обрати внимание на закономерность, которая связывает этот список с разделами 13.1-13.3 этой же главы: ENABLE_LINE_INPUT, ENABLE_ECHO_INPUT и ENABLE_PROCESSED_INPUT влияют на работу функций ВЫСОКОГО уровня (раздел 13.1 - ReadFile/ReadConsole), а ENABLE_WINDOW_INPUT и ENABLE_MOUSE_INPUT - на функции НИЗКОГО уровня (раздел 13.2) - то есть это не случайный список из пяти несвязанных флагов, а прямое продолжение того самого разделения "высокий/низкий уровень" из главы 9.

Если hConsoleHandle - это дескриптор буфера ЭКРАНА, dwMode - комбинация:

- ENABLE_PROCESSED_OUTPUT - функции WriteFile и WriteConsole обрабатывают управляющие символы \n, \t, \b, \v и \a при выводе (переводят строку, двигают табуляцию и так далее, а не печатают как обычный символ); то же самое происходит при отображении на экране того, что вводят ReadFile и ReadConsole.
- ENABLE_WRAP_AT_EOL_OUTPUT - разрешает переносить (прокручивать) буфер экрана, когда вывод доходит до конца строки.

Чтение текущих установленных режимов - функция GetConsoleMode:

```
BOOL GetConsoleMode(
    HANDLE   hConsoleHandle,  // входной или выходной дескриптор консоли
    LPDWORD  lpMode           // указатель на флаги режимов консоли
);
```

При успехе - ненулевое значение, при неудаче - FALSE; по адресу lpMode запишутся текущие флаги.

Пример - отключение режима эхо-вывода

Листинг 13.11 читает текущий режим входного дескриптора, снимает ровно один флаг (ENABLE_ECHO_INPUT), не трогая остальные, и дальше читает строки в цикле - при вводе символы на экране появляться не будут:

```c
#include <windows.h>

HANDLE hStdOut, hStdIn;

int main(void)
{
    LPSTR lpszPrompt1 = "Input ESC and press Enter to exit.\n";
    LPSTR lpszPrompt2 = "Input string and press Enter:\n";
    CHAR  chBuffer[80];
    DWORD cRead, cWritten;
    DWORD dwOldMode, dwNewMode;

    // читаем дескрипторы стандартного ввода и вывода
    hStdIn  = GetStdHandle(STD_INPUT_HANDLE);
    hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hStdIn == INVALID_HANDLE_VALUE || hStdOut == INVALID_HANDLE_VALUE)
    {
        MessageBox(NULL, "Get standard handle failed.", "Win32 API error",
            MB_OK | MB_ICONINFORMATION);
        return GetLastError();
    }
    // читаем режимы, установленные по умолчанию
    if (!GetConsoleMode(hStdIn, &dwOldMode))
    {
        MessageBox(NULL, "Get console mode failed.", "Win32 API error",
            MB_OK | MB_ICONINFORMATION);
        return GetLastError();
    }
    // отключаем режим ENABLE_ECHO_INPUT
    dwNewMode = dwOldMode & ~ENABLE_ECHO_INPUT;
    // устанавливаем новый режим
    if (!SetConsoleMode(hStdIn, dwNewMode))
    {
        MessageBox(NULL, "Set console mode failed.", "Win32 API error",
            MB_OK | MB_ICONINFORMATION);
        return GetLastError();
    }
    // выводим сообщение о том, как выйти из цикла чтения
    if (!WriteConsole(hStdOut, lpszPrompt1, lstrlen(lpszPrompt1),
        &cWritten, NULL))
    {
        MessageBox(NULL, "Write file failed.", "Win32 API error",
            MB_OK | MB_ICONINFORMATION);
        return GetLastError();
    }
    // цикл чтения
    for (;;)
    {
        // выводим сообщение о вводе строки
        if (!WriteConsole(hStdOut, lpszPrompt2, lstrlen(lpszPrompt2),
            &cWritten, NULL))
        {
            MessageBox(NULL, "Write file failed.", "Win32 API error",
                MB_OK | MB_ICONINFORMATION);
            return GetLastError();
        }
        // вводим строку с клавиатуры
        if (!ReadConsole(hStdIn, chBuffer, 80, &cRead, NULL))
        {
            MessageBox(NULL, "Read file failed.", "Win32 API error",
                MB_OK | MB_ICONINFORMATION);
            return GetLastError();
        }
        // выход из программы
        if (chBuffer[0] == '\033')
            return 1;
        // дублируем строку на экране
        if (!WriteConsole(hStdOut, chBuffer, cRead, &cWritten, NULL))
        {
            MessageBox(NULL, "Write file failed.", "Win32 API error",
                MB_OK | MB_ICONINFORMATION);
            return GetLastError();
        }
    }

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API. Механизм: & ~ENABLE_ECHO_INPUT - это побитовое И с побитовым НЕ маски флага, стандартный приём "снять один конкретный бит, не трогая остальные" (уже встречался похожим образом в главе 4 с DisablePriorityBoost); ENABLE_LINE_INPUT и ENABLE_PROCESSED_INPUT остаются как были, меняется только эхо. Результат такого отключения - режим "тихого ввода", когда пользователь печатает, Enter завершает строку как обычно, но на экране во время печати ничего не появляется, а после чтения строка выводится уже сама программа, явным отдельным вызовом WriteConsole в конце цикла - ровно то, что нужно, например, для ввода пароля на экран, хотя сама книга этот пример паролем не называет.

13.5 Прокрутка буфера экрана

Представь консоль высотой, скажем, в 5 видимых строк, и курсор уже стоит на самой последней (пятой) строке - написать что-то на "следующей" строке уже физически некуда, свободного места снизу больше нет. Ровно то же самое происходит в любом текстовом терминале или чате: когда новая строка не помещается, весь уже написанный текст "уезжает" на одну строку вверх, а внизу освобождается пустое место под новую строку. Именно эту операцию - взять кусок буфера экрана и целиком сдвинуть его в другое место, заполнив то, что осталось "оголено", каким-то символом - выполняет функция ScrollConsoleScreenBuffer:

```
BOOL ScrollConsoleScreenBuffer(
    HANDLE             hConsoleOutput,      // дескриптор буфера экрана
    CONST SMALL_RECT  *lpScrollRectangle,   // исходный прямоугольник
    CONST SMALL_RECT  *lpClipRectangle,     // прямоугольник отсечения
    COORD              dwDestinationOrigin, // целевой прямоугольник
    CONST CHAR_INFO   *lpFill               // символ-заполнитель
);
```

При успехе - ненулевое значение, при неудаче - FALSE. lpScrollRectangle - какой прямоугольник ДВИГАЕМ (исходное содержимое). lpClipRectangle - прямоугольник ОТСЕЧЕНИЯ: изменения в буфере экрана происходят только внутри него, за его пределами буфер не трогается вообще (это предохранитель от случайного повреждения соседних областей экрана). dwDestinationOrigin - куда попадёт левый верхний угол исходного прямоугольника после перемещения. lpFill - символ (и атрибуты) для заполнения тех клеток целевой области, которые НЕ перекрылись содержимым исходного прямоугольника - то есть то самое "оголившееся" место.

Пример - прокрутка буфера экрана при переходе на новую строку

Листинг 13.12 - функция GoToNewLine, которая переводит курсор на следующую строку, а если курсор уже на последней строке буфера - вместо этого прокручивает весь буфер на одну строку вверх (главное практическое применение ScrollConsoleScreenBuffer):

```c
#include <windows.h>

HANDLE hStdOut, hStdIn;

// функция перехода на новую строку в буфере экрана
int GoToNewLine(void)
{
    CONSOLE_SCREEN_BUFFER_INFO csbi;     // информация о буфере экрана
    SMALL_RECT                 srScroll; // перемещаемый прямоугольник
    SMALL_RECT                 srClip;   // рассматриваемая область
    COORD                      coord;    // новое положение
    CHAR_INFO                  ci;       // символ-заполнитель

    // читаем информацию о буфере экрана
    if (!GetConsoleScreenBufferInfo(hStdOut, &csbi))
    {
        MessageBox(NULL, "Get console screen buffer info failed.",
            "Win32 API error", MB_OK | MB_ICONINFORMATION);
        return 0;
    }
    // переходим на первый столбец
    csbi.dwCursorPosition.X = 0;
    // если это не последняя строка,
    if ((csbi.dwCursorPosition.Y + 1) < csbi.dwSize.Y)
        // то переводим курсор на следующую строку
        csbi.dwCursorPosition.Y += 1;
    // иначе прокручиваем буфер экрана
    else
    {
        // координаты прямоугольника, который прокручиваем
        srScroll.Left   = 0;
        srScroll.Top    = 1;
        srScroll.Right  = csbi.dwSize.X;
        srScroll.Bottom = csbi.dwSize.Y;
        // координаты прямоугольника буфера экрана
        srClip.Left   = 0;
        srClip.Top    = 0;
        srClip.Right  = csbi.dwSize.X;
        srClip.Bottom = csbi.dwSize.Y;
        // устанавливаем новые координаты левого угла прямоугольника srScroll
        coord.X = 0;
        coord.Y = 0;
        // устанавливаем атрибуты и символ-заполнитель для последней строки
        ci.Attributes = csbi.wAttributes;
        ci.Char.AsciiChar = ' ';
        // прокручиваем прямоугольник srScroll
        if (!ScrollConsoleScreenBuffer(
            hStdOut,    // дескриптор стандартного вывода
            &srScroll,  // прокручиваемый прямоугольник
            &srClip,    // буфер экрана
            coord,      // начало буфера экрана
            &ci))       // атрибуты и символ-заполнитель
        {
            MessageBox(NULL, "Set console window info failed.",
                "Win32 API error", MB_OK | MB_ICONINFORMATION);
            return 0;
        }
    }
    // теперь устанавливаем курсор
    if (!SetConsoleCursorPosition(hStdOut, csbi.dwCursorPosition))
    {
        MessageBox(NULL, "Set console cursor position failed.",
            "Win32 API error", MB_OK | MB_ICONINFORMATION);
        return 0;
    }

    return 0;
}

int main(void)
{
    LPSTR lpszPrompt = "Press ESC to exit.\n";
    CHAR  c;
    DWORD cRead, cWritten;
    DWORD dwOldMode, dwNewMode;

    // читаем дескрипторы стандартного ввода и вывода
    hStdIn  = GetStdHandle(STD_INPUT_HANDLE);
    hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hStdIn == INVALID_HANDLE_VALUE || hStdOut == INVALID_HANDLE_VALUE)
    {
        MessageBox(NULL, "Get standard handle failed.", "Win32 API error",
            MB_OK | MB_ICONINFORMATION);
        return GetLastError();
    }
    // читаем режимы, установленные по умолчанию
    if (!GetConsoleMode(hStdIn, &dwOldMode))
    {
        MessageBox(NULL, "Get console mode failed.", "Win32 API error",
            MB_OK | MB_ICONINFORMATION);
        return GetLastError();
    }
    // отключаем режимы ENABLE_LINE_INPUT и ENABLE_ECHO_INPUT
    dwNewMode = dwOldMode & ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT);
    // устанавливаем новый режим
    if (!SetConsoleMode(hStdIn, dwNewMode))
    {
        MessageBox(NULL, "Set console mode failed.", "Win32 API error",
            MB_OK | MB_ICONINFORMATION);
        return GetLastError();
    }
    // выводим сообщение о том, как выйти из цикла чтения
    if (!WriteFile(hStdOut, lpszPrompt, lstrlen(lpszPrompt),
        &cWritten, NULL))
    {
        MessageBox(NULL, "Write file failed.", "Win32 API error",
            MB_OK | MB_ICONINFORMATION);
        return GetLastError();
    }
    // цикл чтения
    for (;;)
    {
        // читаем следующий символ
        if (!ReadFile(hStdIn, &c, 1, &cRead, NULL))
        {
            MessageBox(NULL, "Write file failed.", "Win32 API error",
                MB_OK | MB_ICONINFORMATION);
            return GetLastError();
        }
        // выбор действия
        switch (c)
        {
        // переход на новую строку
        case '\r':
            if (!GoToNewLine())
            {
                MessageBox(NULL, "Go to a new line failed.",
                    "Win32 API error", MB_OK | MB_ICONINFORMATION);
                return GetLastError();
            }
            break;
        // выход из программы
        case '\033':
            return 1;
        // распечатываем введенный символ
        default:
            if (!WriteFile(hStdOut, &c, cRead, &cWritten, NULL))
            {
                MessageBox(NULL, "Write file failed.", "Win32 API error",
                    MB_OK | MB_ICONINFORMATION);
                return GetLastError();
            }
        }
    }

    return 0;
}
```

Не скомпилировано по-настоящему - проверено по документации и логике API.

Разберём GoToNewLine по шагам на конкретных числах. Пусть высота буфера csbi.dwSize.Y = 5 (строки с индексами 0,1,2,3,4), курсор стоит на csbi.dwCursorPosition.Y = 2 (третья строка). Проверка (Y+1) < dwSize.Y даёт (2+1) < 5, то есть 3 < 5 - истина, значит простой случай: курсор просто переводится на Y=3, никакой прокрутки, буфер не трогаем. Теперь пусть курсор стоит на последней строке, Y = 4: проверка даёт (4+1) < 5, то есть 5 < 5 - ложь, свободных строк снизу больше нет, нужен другой путь. Тогда srScroll описывает ВСЁ, кроме самой первой строки (Top=1, то есть строки с 1 по 4 - именно строка 0 и должна "исчезнуть" при прокрутке вверх на одну позицию, ей просто некуда деваться). srClip - это буфер целиком (0 по 4), то есть отсечения по факту нет, работать разрешено с любой клеткой буфера. coord = (0,0) - это и есть суть прокрутки ВВЕРХ: содержимое прямоугольника srScroll (который начинался со строки 1) переносится так, что теперь начинается со строки 0 - другими словами, каждая строка сдвигается на одну позицию вверх, а бывшая строка 1 становится строкой 0, бывшая 2 становится 1, и так далее. У этого сдвига образуется "хвост" - последняя строка (была 4, теперь физически осталась пустой, потому что содержимого туда не переехало) - и вот её заполняет lpFill: ci.Char.AsciiChar = ' ' (пробел) с ci.Attributes = csbi.wAttributes (те же цвета, что сейчас в буфере, а не какие-то произвольные). После прокрутки курсор всё равно нужно поставить явно - SetConsoleCursorPosition(hStdOut, csbi.dwCursorPosition), где csbi.dwCursorPosition.X уже был обнулён в начале функции, а Y остался равен 4 (в ветке прокрутки Y НЕ увеличивался) - то есть курсор остаётся на "последней" визуальной строке, только теперь она уже пустая и готова принять новый текст.

В main() этого листинга отключены сразу ДВА режима - и ENABLE_LINE_INPUT, и ENABLE_ECHO_INPUT (в отличие от листинга 13.11, где отключался только ECHO). Без ENABLE_LINE_INPUT ReadFile перестаёт ждать Enter и возвращает управление сразу после первого же введённого символа - поэтому цикл читает буквально по одному символу за раз (&c, 1, ...) и сам вручную решает, что с ним делать: '\r' (Enter) - вызвать GoToNewLine (перевести курсор и, если нужно, прокрутить буфер); '\033' (Esc) - выйти; любой другой символ - напечатать его через WriteFile, потому что раз эхо тоже отключено, без этой явной печати введённый символ на экране бы не появился вообще. Так вручную, по кирпичикам, собирается ровно то поведение, которое обычно даёт режим по умолчанию (ENABLE_LINE_INPUT + ENABLE_ECHO_INPUT) сам, бесплатно - это наглядно показывает, что стандартный ввод-вывод строкой это не какая-то магия, а именно комбинация этих самых флагов и ровно такой же логики, которую тут прописали руками.

Частые путаницы и ошибки

Путают ReadConsoleInput и PeekConsoleInput. ReadConsoleInput удаляет прочитанную запись из очереди входного буфера (как открытое сообщение). PeekConsoleInput с ТЕМИ ЖЕ параметрами читает запись, но оставляет её в очереди (как непрочитанное уведомление, которое можно посмотреть ещё раз).

Путают "высокий" и "низкий" уровень ввода-вывода (разделы 13.1 и 13.2-13.3) со сложностью кода. Дело не в том, что низкоуровневые функции сложнее написать, а в том, ЧТО ИМЕННО они видят: высокий уровень видит только символы, низкий - любое событие консоли, включая мышь и изменение размера окна (та же путаница уже отмечалась в lectures/09 применительно к самой концепции уровней).

GetNumberOfConsoleMouseButtons - единственная функция всей главы, у которой нет параметра-дескриптора консоли. Это не опечатка и не недосмотр: мышь - устройство всей системы, а не конкретной консоли, поэтому спрашивать "через какую консоль" бессмысленно.

Путают четвёрку функций работы с СИМВОЛАМИ (раздел 13.3: ReadConsoleOutputCharacter/WriteConsoleOutputCharacter/FillConsoleOutputCharacter) с четвёркой функций работы с ЦВЕТОМ из главы 12 (раздел 12.4: те же роли, но Attribute вместо Character). Для символов "четвёртой" функции (аналога SetConsoleTextAttribute) не существует - роль "что печатать дальше" уже закрыта обычным WriteConsole/WriteFile из раздела 13.1.

В ReadConsoleOutput/WriteConsoleOutput путают систему координат lpReadRegion/lpWriteRegion (координаты внутри настоящего буфера экрана консоли) с dwBufferCoord (координаты внутри твоего же локального массива lpBuffer в памяти программы) - это две разные, независимые сетки координат.

В режимах ввода (раздел 13.4) путают, на какие функции влияет какой флаг: ENABLE_LINE_INPUT, ENABLE_ECHO_INPUT, ENABLE_PROCESSED_INPUT относятся к функциям высокого уровня (13.1), а ENABLE_WINDOW_INPUT и ENABLE_MOUSE_INPUT - к функциям низкого уровня (13.2), не наоборот.

Опечатки самой книги в этой главе, на которые стоит обратить внимание, чтобы не запутаться при последующей сверке с оригиналом: в прототипе ReadConsole у параметра hConsoleInput стоит комментарий "дескриптор буфера экрана" - скопировано по ошибке с соседней функции WriteConsole, на самом деле это дескриптор ВХОДНОГО буфера консоли; в тексте перед листингом 13.7 функция один раз названа "WriteConsoleInputCharacter" вместо правильного WriteConsoleOutputCharacter; в тексте про GetNumberOfConsoleMouseButtons и в её прототипе название один раз напечатано без буквы s на конце ("GetNumberOfConsoleMouseButton"), тогда как рабочий код в листинге 13.5 верно использует полное имя с s (это и есть настоящее имя функции в Win32 API); и в разделе 13.1 фраза "режимы управления вводом-выводом рассмотрены в разд. 13.3" на самом деле должна указывать на разд. 13.4 - именно там, а не в 13.3 (это раздел про вывод низкого уровня), разбираются режимы.

Источник

Конспект по главе 13 книги Побегайло, "Ввод-вывод на консоль" (стр. 203-234, часть III, см. book-toc.md), включая листинги 13.1-13.12 целиком. Ни один пример не скомпилирован (нет Windows) - объяснено по документации и логике API, как и во всех остальных конспектах этого предмета.
