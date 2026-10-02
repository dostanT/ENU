Справочник. Глава 6. Синхронизация потоков в Windows

Логика: какой механизм когда

- Одна простая переменная - Interlocked* (глава 7), самый лёгкий.
- Взаимное исключение внутри ОДНОГО процесса - критическая секция (CRITICAL_SECTION). Быстрая: не объект ядра, вход/выход без переключения в режим ядра.
- Взаимное исключение между РАЗНЫМИ процессами - мьютекс (объект ядра, есть имя).
- Оповестить ждущих, что что-то произошло - событие. Ручной сброс - освобождает всех; автосброс - одного.
- Пустить до N потоков одновременно - семафор (считающий).
- Критическую секцию держать как можно короче: тяжёлые операции (ввод-вывод, расчёты) - до входа или после выхода.

Объекты синхронизации (общее)

- Объект ядра в двух состояниях: сигнальном и несигнальном. Четыре класса: 1) мьютекс, событие, семафор; 2) ожидающий таймер (сигнален по истечении интервала); 3) job, процесс, поток (сигнальны по завершении - поэтому WaitForSingleObject(hThread) работает); 4) сигналящие об изменении (изменение каталога, консольный ввод).
- Функции ожидания блокируют поток, пока объект не станет сигнальным.
- Мьютекс сигнален, если ни один поток им не владеет. Владелец - один поток. Семафор сигнален, если значение > 0 (ожидание уменьшает на 1). Событие - по SetEvent.
- Ждущие обслуживаются по FIFO (но при асинхронном событии ядро может убрать поток из очереди, и он встанет в конец).

Критическая секция

Владелец - поток (Leave может вызвать только тот, кто вошёл). Вход рекурсивный: повторный Enter тем же потоком не блокирует, увеличивает счётчик; на каждый Enter нужен свой Leave.
Каждая функция принимает один параметр: LPCRITICAL_SECTION lpCriticalSection (указатель на общий CRITICAL_SECTION cs).
- VOID InitializeCriticalSection(LPCRITICAL_SECTION lpCriticalSection); - подготовить, один раз до использования
- VOID EnterCriticalSection(LPCRITICAL_SECTION lpCriticalSection); - войти, блокируется, если занято
- BOOL TryEnterCriticalSection(LPCRITICAL_SECTION lpCriticalSection); - попытка без блокировки; не 0 = вошёл (или уже внутри), FALSE = занято. Только Windows 2000
- VOID LeaveCriticalSection(LPCRITICAL_SECTION lpCriticalSection); - выйти
- VOID DeleteCriticalSection(LPCRITICAL_SECTION lpCriticalSection); - освободить ресурсы, когда больше не нужна
Порядок: Initialize -> (потоки: Enter ... Leave) -> Delete.
Без секции целостность вывода нарушается (числа разных потоков внутри одной строки).

WaitForSingleObject
DWORD WaitForSingleObject(HANDLE hHandle, DWORD dwMilliseconds);
- hHandle - объект синхронизации, который ждём
- dwMilliseconds - сколько ждать: 0 = только проверить состояние, не ждать; INFINITE = ждать бесконечно; иное = таймаут в мс
Возврат: WAIT_OBJECT_0 (объект сигнален), WAIT_ABANDONED (забытый мьютекс), WAIT_TIMEOUT (время вышло), WAIT_FAILED (ошибка).
Захват мьютекса и семафора - тоже WaitForSingleObject.

WaitForMultipleObjects
DWORD WaitForMultipleObjects(DWORD nCount, CONST HANDLE *lpHandles, BOOL bWaitAll, DWORD dwMilliseconds);
- nCount - сколько объектов (не больше MAXIMUM_WAIT_OBJECTS)
- lpHandles - массив дескрипторов (без повторов)
- bWaitAll - TRUE: ждать пока ВСЕ станут сигнальными; FALSE: пока ХОТЯ БЫ ОДИН
- dwMilliseconds - как у WaitForSingleObject
Возврат: WAIT_OBJECT_0 ... WAIT_OBJECT_0 + nCount - 1; WAIT_ABANDONED_0 ... WAIT_ABANDONED_0 + nCount - 1; WAIT_TIMEOUT; WAIT_FAILED. При bWaitAll = FALSE индекс сработавшего = возврат - WAIT_OBJECT_0. При TRUE любое значение из диапазона = все сигнальны (ABANDONED_0-диапазон: и хотя бы один забытый мьютекс).
Пример: WaitForMultipleObjects(2, hThread, TRUE, INFINITE) - дождаться двух потоков.

Мьютекс (Mutex = mutual exclusion)

Как: захват - любая функция ожидания; освобождение - ReleaseMutex. Один поток - владелец. Имена чувствительны к регистру, длина не больше MAX_PATH.
HANDLE CreateMutex(LPSECURITY_ATTRIBUTES lpMutexAttributes, BOOL bInitialOwner, LPCTSTR lpName);
- lpMutexAttributes - атрибуты защиты; NULL (ненаследуемый, доступ всем)
- bInitialOwner - TRUE: создатель сразу владелец; FALSE: свободен. Если используешь CreateMutex, чтобы получить доступ к возможно уже существующему мьютексу - FALSE (не знаешь, кто создаст первым)
- lpName - имя для доступа из других процессов; NULL = безымянный
Возврат: дескриптор; NULL при ошибке. Если мьютекс с таким именем уже есть - вернёт его дескриптор, GetLastError = ERROR_ALREADY_EXISTS.

BOOL ReleaseMutex(HANDLE hMutex);
- hMutex - дескриптор мьютекса
Возврат: не 0 - успех; FALSE - ошибка, в том числе если вызывающий поток не владелец.

HANDLE OpenMutex(DWORD dwDesiredAccess, BOOL bInheritHandle, LPCTSTR lpName);
- dwDesiredAccess - MUTEX_ALL_ACCESS (полный) или SYNCHRONIZE (только ожидание/захват и ReleaseMutex)
- bInheritHandle - TRUE: дескриптор наследуемый
- lpName - имя существующего мьютекса
Возврат: дескриптор; NULL при неудаче.

Забытый мьютекс (abandoned): поток завершился, не вызвав ReleaseMutex. ОС освобождает его сама, следующий получает WAIT_ABANDONED (защищённые данные могут быть в неопределённом состоянии) - отличать от WAIT_OBJECT_0.
Классический пример: два процесса, именованный мьютекс "DemoMutex"; родитель CreateMutex, потомок OpenMutex(SYNCHRONIZE, FALSE, "DemoMutex").

События

Событие = оповещение "действие произошло" (аналог Condition из главы 5).
- Ручной сброс (manual-reset): сигнальное, пока явно не вызван ResetEvent; пропускает всех ждущих ("стартовый выстрел").
- Автоматический сброс (auto-reset): освобождается ровно один ждущий поток, событие само становится несигнальным ("один билет").
HANDLE CreateEvent(LPSECURITY_ATTRIBUTES lpSecurityAttributes, BOOL bManualReset, BOOL bInitialState, LPCTSTR lpName);
- lpSecurityAttributes - NULL
- bManualReset - TRUE ручной сброс, FALSE автоматический
- bInitialState - TRUE создаётся сигнальным, FALSE несигнальным
- lpName - имя; NULL = безымянное
Возврат: дескриптор; NULL при ошибке; если имя уже есть - ERROR_ALREADY_EXISTS.

BOOL SetEvent(HANDLE hEvent); - перевести в сигнальное
BOOL ResetEvent(HANDLE hEvent); - в несигнальное (для ручного сброса единственный способ снять сигнал)
BOOL PulseEvent(HANDLE hEvent); - разовый импульс: ручной сброс: освобождает ВСЕХ ждущих ("барьер") и сразу несигнальное; автосброс: освобождает одного; если никто не ждёт - остаётся несигнальным
- hEvent - дескриптор события; возврат не 0 / FALSE
HANDLE OpenEvent(DWORD dwDesiredAccess, BOOL bInheritHandle, LPCTSTR lpName);
- dwDesiredAccess - EVENT_ALL_ACCESS (любые действия), EVENT_MODIFY_STATE (SetEvent/ResetEvent), SYNCHRONIZE (только ожидание); можно комбинировать
- bInheritHandle - наследуемость; lpName - имя
Возврат: дескриптор; NULL при неудаче.

Семафор

Значение уменьшается на 1 при успешном ожидании; сигнален при значении > 0. Бинарный (0/1) ~ мьютекс/крит. секция; считающий - для подсчёта ресурсов.
HANDLE CreateSemaphore(LPSECURITY_ATTRIBUTES lpSemaphoreAttribute, LONG lInitialCount, LONG lMaximumCount, LPCTSTR lpName);
- lpSemaphoreAttribute - NULL
- lInitialCount - начальное значение (0 <= значение <= lMaximumCount)
- lMaximumCount - максимум (сколько всего "мест")
- lpName - имя; NULL = безымянный
Возврат: дескриптор; NULL при ошибке; имя уже существует: возвращает его дескриптор (initial/maximum игнорируются), ERROR_ALREADY_EXISTS.

BOOL ReleaseSemaphore(HANDLE hSemaphore, LONG lReleaseCount, LPLONG lpPreviousCount);
- hSemaphore - семафор
- lReleaseCount - на сколько увеличить значение (положительное)
- lpPreviousCount - выходной: предыдущее значение; можно NULL
Возврат: не 0 - успех; FALSE, если значение + lReleaseCount > максимума (значение не меняется).

HANDLE OpenSemaphore(DWORD dwDesiredAccess, BOOL bInheritHandle, LPCTSTR lpName);
- dwDesiredAccess - SEMAPHORE_ALL_ACCESS, SEMAPHORE_MODIFY_STATE (только ReleaseSemaphore), SYNCHRONIZE (только ожидание; только Windows NT/2000)
Пример "производитель-потребитель": семафор с initial 0, maximum 10; производитель после каждого элемента ReleaseSemaphore(hSem, 1, NULL); потребитель перед чтением WaitForSingleObject(hSem, INFINITE).

Закрывать дескрипторы мьютекса/события/семафора - CloseHandle (сами не закрываются).

Другие примитивы (только названия)
- барьер - группа потоков ждёт, пока дойдут все
- read-write lock - читателей много, писатель один и без читателей
- future/promise - результат вычисления одного потока другому
- condition variable - ждать выполнения условия, о котором оповестит другой поток
