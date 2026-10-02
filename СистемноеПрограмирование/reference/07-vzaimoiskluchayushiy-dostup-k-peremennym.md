Справочник. Глава 7. Взаимоисключающий доступ к переменным (Interlocked-функции)

Логика

- Для одной простой операции над одной переменной критическая секция/мьютекс избыточны (дорого, мьютекс ещё и переключение в режим ядра). Interlocked-функции = атомарные ("блокирующие") операции: прочитать-изменить-записать одним неделимым шагом, наполовину выполненной операции никто не увидит.
- Обычный counter++ = 3 шага (прочитать, прибавить, записать); между ними может вклиниться другой поток -> потеря прибавления (гонка данных). InterlockedIncrement(&counter) - без окна.
- Требование ко всем: адрес переменной выровнен на границу слова (кратен 32). Выполняется само, если переменная объявлена как long, unsigned long, LONG, ULONG, DWORD.
- Можно использовать между потоками РАЗНЫХ процессов, если процессы делят память через отображение файлов в память (глава 30).
- Что возвращает - главная путаница:
  - InterlockedExchange, InterlockedCompareExchange, InterlockedExchangeAdd -> СТАРОЕ значение
  - InterlockedIncrement, InterlockedDecrement -> НОВОЕ значение
- Пример из книги: producer кладёт число в контейнер n, consumer забирает; volatile long n. Потоки в примере останавливаются TerminateThread (только для демонстрации; нормальный способ - события и ExitThread, раздел 8.6).

Функции

InterlockedExchange (замена значения)
LONG InterlockedExchange(LPLONG lpTarget, LONG lValue);
- lpTarget - адрес переменной, значение которой заменяется
- lValue - новое значение
Возврат: старое значение переменной.

InterlockedCompareExchange (условная замена)
PVOID InterlockedCompareExchange(PVOID *Destination, PVOID Exchange, PVOID Comperand);
- Destination - адрес переменной
- Exchange - новое значение
- Comperand - значение для сравнения: замена происходит ТОЛЬКО если текущее значение равно Comperand
Возврат: старое значение. Если возврат == Comperand - замена была; иначе нет.
Пример: положить товар, только если контейнер пуст: InterlockedCompareExchange((PVOID*)&n, (PVOID)goods, 0); - быстрый producer не затрёт ещё не забранное число.

InterlockedIncrement / InterlockedDecrement (+1 / -1)
LONG InterlockedIncrement(LPLONG lpAddend);
LONG InterlockedDecrement(LPLONG lpAddend);
- lpAddend - адрес переменной
Возврат: НОВОЕ значение.

InterlockedExchangeAdd (прибавить произвольное)
LONG InterlockedExchangeAdd(LPLONG lpAddend, LONG Increment);
- lpAddend - адрес переменной
- Increment - что прибавить (может быть отрицательным)
Возврат: СТАРОЕ значение. Increment/Decrement - частные случаи с +1/-1, но возвращают новое значение (удобно для счётчика).

Когда какую

- просто поменять значение - InterlockedExchange
- поменять, только если значение такое-то - InterlockedCompareExchange
- счётчик на 1 - Increment/Decrement
- прибавить N - InterlockedExchangeAdd
