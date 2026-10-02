Задача 1 — код по темам глав 1-4

Задание открытое: "3-4 кода по пройденным темам, главы 1-4". Единственно правильного ответа тут нет, поэтому я сам выбрал 4 программы так, чтобы вместе они закрывали разные куски пройденного материала, а не повторяли один и тот же приём. Главы 1-2 сами по себе почти не дают кода (это определения и типы данных), поэтому реальный Win32-код у нас появляется с главы 3 — так и должно быть, это честно отражает структуру книги.

Что показывает каждая программа:
1. Поток, который стартует в подвешенном состоянии и запускается по команде (3.2, 3.4)
2. Гонка данных между двумя потоками без синхронизации, вживую (глава 2 + 3.3)
3. Процесс, запущенный подвешенным, и смена его приоритета снаружи, до старта (4.2, 4.7, 3.4)
4. Обработка ошибки Win32 через GetLastError и FormatMessage на реальном сбое (3.6, 4.2)

Виндовый код я не могу здесь скомпилировать (нет MSVC/Windows), поэтому он проверен только по логике API и по образцу уже разобранных примеров в lectures/03 и lectures/04.

Программа 1 - поток в подвешенном состоянии

Идея: создать поток так, чтобы он не начал работу сразу, а ждал команды - пригодится, когда нужно сначала что-то подготовить в главном потоке, и только потом дать рабочему потоку стартовать.

```c
#include <windows.h>
#include <iostream.h>

DWORD WINAPI Worker(LPVOID lpParam)
{
    cout << "Поток создан, жду возобновления..." << endl;
    // здесь могла бы быть полезная работа
    cout << "Поток возобновлён, работаю." << endl;
    return 0;
}

int main()
{
    HANDLE hThread;
    DWORD dwThreadId;

    // CREATE_SUSPENDED - поток создаётся, но не запускается
    hThread = CreateThread(NULL, 0, Worker, NULL, CREATE_SUSPENDED, &dwThreadId);
    if (hThread == NULL)
        return GetLastError();

    cout << "Главный поток что-то готовит..." << endl;
    cout << "Главный поток готов, возобновляю рабочий поток." << endl;

    ResumeThread(hThread);

    WaitForSingleObject(hThread, INFINITE);
    CloseHandle(hThread);

    cout << "Готово." << endl;
    return 0;
}
```

Механизм: флаг CREATE_SUSPENDED в CreateThread (раздел 3.2) - это то же самое, что создать поток и сразу вызвать SuspendThread, только без промежутка, когда поток уже мог бы успеть немного поработать. Счётчик приостановок потока становится равным 1 сразу при создании. ResumeThread (3.4) уменьшает счётчик до 0, и только тогда поток реально начинает выполняться. Дальше - обычные WaitForSingleObject и CloseHandle из раздела 3.2.


Программа 2 - гонка данных на живую

Идея: показать своими глазами то, что книга объясняет в главе 2 на примере функции g() с глобальной переменной - что происходит, если два потока меняют одну и ту же переменную без всякой защиты.

```c
#include <windows.h>
#include <iostream.h>

#define ITERATIONS 2000000

volatile int counter = 0;

DWORD WINAPI Increment(LPVOID lpParam)
{
    for (int i = 0; i < ITERATIONS; i++)
        counter++;
    return 0;
}

int main()
{
    HANDLE hThread1, hThread2;
    DWORD dwThreadId;

    hThread1 = CreateThread(NULL, 0, Increment, NULL, 0, &dwThreadId);
    hThread2 = CreateThread(NULL, 0, Increment, NULL, 0, &dwThreadId);

    WaitForSingleObject(hThread1, INFINITE);
    WaitForSingleObject(hThread2, INFINITE);

    cout << "Ожидалось: " << ITERATIONS * 2 << endl;
    cout << "Получилось: " << counter << endl;

    CloseHandle(hThread1);
    CloseHandle(hThread2);
    return 0;
}
```

Механизм: counter++ выглядит как одна операция, а реально это три шага - прочитать значение из памяти, прибавить единицу, записать обратно. Пока один поток читает-прибавляет-пишет, второй может успеть прочитать ещё старое значение - и тогда одно из двух прибавлений теряется. volatile здесь (см. разбор в 3.3) не спасает: он всего лишь запрещает компилятору закэшировать переменную в регистре, но не делает сами три шага одной неделимой операцией. Именно поэтому в главе 2 книга называет функции вроде g() небезопасными для потоков - без специальной защиты (критические секции, мьютексы - это глава 6, впереди), доступ нужно синхронизировать вручную, а здесь этого нарочно не сделано, чтобы увидеть проблему.


Программа 3 - процесс в подвешенном состоянии и смена приоритета снаружи

Идея: объединить сразу главу 3 (подвешенный старт) и главу 4 (процессы, приоритеты) - создать процесс так, чтобы он не начал выполняться сразу, посмотреть и поменять его приоритет снаружи, пока он ещё не стартовал, и только потом запустить.

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    STARTUPINFO si;
    PROCESS_INFORMATION pi;

    ZeroMemory(&si, sizeof(STARTUPINFO));
    si.cb = sizeof(STARTUPINFO);

    // CREATE_SUSPENDED - процесс создаётся, но его главный поток не стартует
    if (!CreateProcess(NULL, "notepad.exe", NULL, NULL, FALSE,
                        CREATE_SUSPENDED, NULL, NULL, &si, &pi))
    {
        return GetLastError();
    }

    DWORD dwClass = GetPriorityClass(pi.hProcess);
    cout << "Приоритет нового процесса по умолчанию: " << dwClass << endl;

    SetPriorityClass(pi.hProcess, BELOW_NORMAL_PRIORITY_CLASS);
    dwClass = GetPriorityClass(pi.hProcess);
    cout << "Приоритет после SetPriorityClass: " << dwClass << endl;

    // теперь можно запускать
    ResumeThread(pi.hThread);

    WaitForSingleObject(pi.hProcess, INFINITE);
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return 0;
}
```

Механизм: CREATE_SUSPENDED работает и для CreateProcess (4.2), не только для CreateThread - подвешивается первичный поток нового процесса, тот, о котором рассказывает 4.1. Пока процесс висит, можно спокойно прочитать и поменять его класс приоритета через дескриптор pi.hProcess функциями GetPriorityClass и SetPriorityClass (4.7), не боясь, что он уже начал что-то делать со старым приоритетом. ResumeThread (3.4) применяется здесь не к дескриптору из CreateThread, а к pi.hThread - дескриптору первичного потока процесса, но это тот же самый механизм.


Программа 4 - обработка ошибки при неудачном запуске процесса

Идея: специально вызвать реальную ошибку Win32 API и правильно её обработать - через GetLastError и FormatMessage, как учит раздел 3.6, только не на абстрактном примере, а на настоящем сбое CreateProcess из главы 4.

```c
#include <windows.h>
#include <iostream.h>

int main()
{
    STARTUPINFO si;
    PROCESS_INFORMATION pi;

    ZeroMemory(&si, sizeof(STARTUPINFO));
    si.cb = sizeof(STARTUPINFO);

    // такой программы не существует - это специально
    BOOL bResult = CreateProcess(NULL, "ProgramThatDoesNotExist.exe", NULL, NULL,
                                  FALSE, 0, NULL, NULL, &si, &pi);

    if (!bResult)
    {
        DWORD dwError = GetLastError();
        cout << "Не удалось запустить процесс, код ошибки = " << dwError << endl;

        LPVOID lpMsgBuf;
        FormatMessage(
            FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
            NULL, dwError, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            (LPTSTR)&lpMsgBuf, 0, NULL);

        cout << "Расшифровка: " << (char*)lpMsgBuf << endl;
        LocalFree(lpMsgBuf);
        return dwError;
    }

    WaitForSingleObject(pi.hProcess, INFINITE);
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return 0;
}
```

Механизм: CreateProcess не может найти "ProgramThatDoesNotExist.exe" ни по одному из путей поиска (раздел 4.2), возвращает FALSE, ничего не создав. По соглашению из главы 1 - раз функция вернула признак неудачи, дальше идём за подробностями к GetLastError и превращаем код в текст через FormatMessage (3.6), это тот же самый шаблон вызова, что и в готовой функции CoutErrorMessage из lectures/03.


Частые ошибки и путаницы

Путать CREATE_SUSPENDED у потока и у процесса - формально это один и тот же флаг, но у CreateThread он подвешивает сам создаваемый поток, а у CreateProcess - первичный поток нового процесса (pi.hThread), не сам процесс как объект.

Думать, что volatile защищает от гонки данных - не защищает, это видно по программе 2 напрямую: даже с volatile результат неверный, потому что volatile отвечает только за то, откуда компилятор читает и куда пишет значение, а не за атомарность операции целиком.

Не проверять возвращаемое значение CreateProcess/CreateThread и сразу лезть в pi.hProcess/hThread - если функция вернула FALSE/NULL, эти поля не заполнены, и все дальнейшие действия с ними бессмысленны или упадут.


