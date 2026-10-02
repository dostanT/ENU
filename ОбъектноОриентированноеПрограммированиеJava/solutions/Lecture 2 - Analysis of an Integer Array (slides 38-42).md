Практика на паре - лекция 2, задание "Analysis of an Integer Array" (слайды 38-42)

Что здесь решается

В конце презентации второй лекции (файл teacher-lectures/2w_OOP Java_var 1.pdf, слайды 38-42) преподаватель даёт классную работу на 10-15 минут: "Analysis of an Integer Array" - анализ массива целых чисел. На слайде 40 дан готовый, уже проверенный код, на слайде 42 - пошаговый план и "Task for Students" из пяти пунктов плюс два необязательных (Extra). Сначала нужно понять, что считает программа, потом пройти пункты по порядку. Ниже - все семь пунктов, для каждого полная рабочая программа и её настоящий вывод. Все программы скомпилированы (javac из JDK 25, ключ -Xlint:all - предупреждений нет; сборка с --release 8 тоже проходит) и запущены; ввод с клавиатуры прогонялся через псевдотерминал, поэтому набранные числа видны рядом с приглашением, как в обычной консоли. Все числа пересчитаны отдельно на Python - совпали.

(Отдельно в этой же презентации, слайды 44-45, дано домашнее задание - шесть вариантов приложений на Swing. Оно здесь не решается, только классная работа.)

Что делает программа - на пальцах

Представь, что у тебя горсть бумажек с числами: 10, -5, 0, 8, -2, 15, 3. Ты берёшь их по одной и ведёшь несколько "блокнотиков":

- блокнот "самое большое" - сначала записываешь туда первую бумажку; если следующая больше - зачёркиваешь и пишешь новую;
- блокнот "самое маленькое" - то же самое, но наоборот;
- копилка "сумма" - в неё кладёшь каждое число;
- три счётчика: сколько было положительных, отрицательных и нулей - на каждой бумажке ставишь чёрточку в нужном столбике.

Когда бумажки кончились, делишь сумму на количество бумажек - это среднее. Программа ровно это и делает: анализирует массив (это "ряд ячеек одного типа", здесь int[] - ряд целых чисел) и печатает максимум, минимум, сумму, среднее и три счётчика. Один проход по массиву заполняет все блокнотики сразу.

Ручной прогон (трассировка) - как меняются переменные

Перед циклом: max = 10 и min = 10 (первое число массива numbers[0] - "пока самое большое и самое маленькое, что видел"), sum = 0, positive = 0, negative = 0, zero = 0.

- число 10: не больше max, не меньше min; sum = 10; положительное - positive = 1
- число -5: меньше min - min = -5; sum = 5; отрицательное - negative = 1
- число 0: sum = 5; не больше и не меньше нуля - попало в else - zero = 1
- число 8: sum = 13; positive = 2
- число -2: sum = 11; negative = 2
- число 15: больше max - max = 15; sum = 26; positive = 3
- число 3: sum = 29; positive = 4

После цикла: max = 15, min = -5, sum = 29, positive = 4, negative = 2, zero = 1. Среднее = 29 / 7 = 4.142857142857143 (в массиве 7 чисел). Именно это и выведет программа - можно сверить со скриншотом на слайде 41.

Пункт 1. Запустить данный код и убедиться, что результат тот же

Код со слайда 40 без единого изменения (только в файле Main.java, класс называется Main). Строка import java.util.Scanner в нём пока не нужна - Scanner здесь не используется, лишний импорт не мешает работе; понадобится он в пункте 3.

```java
import java.util.Scanner;
public class Main {
  public static void main(String[] args) {
    int[] numbers = {10, -5, 0, 8, -2, 15, 3};
  int max = numbers[0];
  int min = numbers[0];
  int sum = 0;
  int positive = 0;
  int negative = 0;
  int zero = 0;

    // process the array
       for (int num : numbers) {

      if (num > max) max = num;
      if (num < min) min = num;

      sum += num;

      if (num > 0) {
          positive++;
      } else if (num < 0) {
          negative++;
      } else {
          zero++;
      }
    }
    double average = (double) sum / numbers.length;
    // output results
       System.out.println("Array: ");
       for (int num : numbers) {
       System.out.print(num + " ");
    }
       System.out.println();
       System.out.println("Maximum value : " + max);
       System.out.println("Minimum value : " + min);
       System.out.println("Sum        : " + sum);
       System.out.println("Average value : " + average);
       System.out.println("Positive numbers: " + positive);
       System.out.println("Negative numbers: " + negative);
       System.out.println("Zero numbers : " + zero);
}
}
```

Вывод:

```
Array: 
10 -5 0 8 -2 15 3 
Maximum value : 15
Minimum value : -5
Sum        : 29
Average value : 4.142857142857143
Positive numbers: 4
Negative numbers: 2
Zero numbers : 1
```

Совпадает со слайдами 41 и 42 (максимум 15, минимум -5, сумма 29, среднее 4.142857142857143, положительных 4, отрицательных 2, нулей 1).

Разбор строк, которые стоит понять до изменений

- for (int num : numbers) - цикл "для каждого": на каждом обороте переменная num по очереди становится равной очередному элементу массива. Индексы (0, 1, 2...) здесь вести не нужно.
- if (num > max) max = num; - если увиденное число больше рекордного, оно становится новым рекордом. Скобки не нужны, потому что после if стоит один оператор.
- sum += num; - то же самое, что sum = sum + num: положить число в копилку.
- Цепочка if / else if / else - выбирается ровно одна ветка: если число больше нуля - positive, иначе если меньше нуля - negative, иначе (значит, равно нулю) - zero. Три ветки не пересекаются, поэтому ни одно число не посчитается дважды.
- (double) sum / numbers.length - явное преобразование типа: sum превращается в double до деления. Без этого Java делит целое на целое и отбрасывает дробную часть - проверено запуском: 29 / 7 даёт 4, а (double) 29 / 7 даёт 4.142857142857143. Важно, куда ставится скобка: (double) (sum / length) - это уже не то, там сначала целочисленное деление, потом превращение в double, и получится 4.0.
- numbers.length - количество элементов массива (без скобок, это не метод, а поле).

Пункт 2. Поменять значения массива и запустить снова

Заменяем одну строку - массив станет {7, -3, 0, 0, 12, -9, 4, 20, -1} (9 чисел, два нуля, чтобы проверить счётчик нулей). Всё остальное в коде не трогаем. Ожидание, посчитанное руками: максимум 20, минимум -9, сумма 7-3+0+0+12-9+4+20-1 = 30, среднее 30/9 = 3.333..., положительных 4 (7, 12, 4, 20), отрицательных 3 (-3, -9, -1), нулей 2.

Изменённая строка:

```java
int[] numbers = {7, -3, 0, 0, 12, -9, 4, 20, -1};
```

Вывод:

```
Array: 
7 -3 0 0 12 -9 4 20 -1 
Maximum value : 20
Minimum value : -9
Sum        : 30
Average value : 3.3333333333333335
Positive numbers: 4
Negative numbers: 3
Zero numbers : 2
```

Всё совпало с ожиданием. Программа подстроилась сама, потому что нигде в коде не зашито число 7 - размер берётся из numbers.length, а не вписан руками.

Пункты 3 и 4. Числа с клавиатуры и счётчик "больше заданного значения"

Пункт 3: вместо готового массива пользователь вводит, сколько чисел будет, и затем сами числа. Массив создаётся уже после того, как известно n: new int[n] - "выдай n пустых ячеек int" (в них пока нули). Дальше for заполняет ячейки по одной. Всё остальное (анализ и вывод) остаётся как в пункте 1 - поэтому в программу можно просто вставить прежний блок.

Две защиты, без которых программа легко ломается:

- n должно быть хотя бы 1. При n = 0 массив пустой, а строка int max = numbers[0] обращается к несуществующему первому элементу - проверено запуском: Java падает с ArrayIndexOutOfBoundsException: Index 0 out of bounds for length 0. Поэтому цикл while переспрашивает, пока n < 1.
- Пользователь может напечатать не число. Scanner.nextInt() на слове "abc" бросает исключение и программа падает. Поэтому перед чтением стоит проверка in.hasNextInt() ("следующее слово - целое число?"). Если нет - in.next() выбрасывает испорченное слово, и вопрос задаётся снова. Так же защищён и ввод порога.

Пункт 4: новое требование - посчитать, сколько чисел больше заданного значения (в примере со слайда - 10). Это тот же приём "счётчик", что positive и negative: перед циклом greater = 0, в цикле if (num > threshold) greater++. Порог тоже вводится с клавиатуры. Добавлено в тот же файл, после основного вывода.

```java
import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner in = new Scanner(System.in);

        // 1. how many numbers (must be at least 1, otherwise numbers[0] would crash)
        int n = 0;
        while (n < 1) {
            System.out.print("How many numbers? ");
            while (!in.hasNextInt()) {
                System.out.println("That is not an integer, try again.");
                in.next();
                System.out.print("How many numbers? ");
            }
            n = in.nextInt();
            if (n < 1) {
                System.out.println("Need at least 1 number.");
            }
        }

        // 2. read the numbers into the array
        int[] numbers = new int[n];
        for (int i = 0; i < n; i++) {
            System.out.print("Number " + (i + 1) + ": ");
            while (!in.hasNextInt()) {
                System.out.println("That is not an integer, try again.");
                in.next();
                System.out.print("Number " + (i + 1) + ": ");
            }
            numbers[i] = in.nextInt();
        }

        // 3. the same analysis as before
        int max = numbers[0];
        int min = numbers[0];
        int sum = 0;
        int positive = 0;
        int negative = 0;
        int zero = 0;

        for (int num : numbers) {
            if (num > max) max = num;
            if (num < min) min = num;
            sum += num;
            if (num > 0) {
                positive++;
            } else if (num < 0) {
                negative++;
            } else {
                zero++;
            }
        }
        double average = (double) sum / numbers.length;

        System.out.println("Array: ");
        for (int num : numbers) {
            System.out.print(num + " ");
        }
        System.out.println();
        System.out.println("Maximum value : " + max);
        System.out.println("Minimum value : " + min);
        System.out.println("Sum           : " + sum);
        System.out.println("Average value : " + average);
        System.out.println("Positive numbers: " + positive);
        System.out.println("Negative numbers: " + negative);
        System.out.println("Zero numbers    : " + zero);

        // 4. new requirement: how many numbers are greater than a given value
        System.out.print("Threshold: ");
        while (!in.hasNextInt()) {
            System.out.println("That is not an integer, try again.");
            in.next();
            System.out.print("Threshold: ");
        }
        int threshold = in.nextInt();
        int greater = 0;
        for (int num : numbers) {
            if (num > threshold) {
                greater++;
            }
        }
        System.out.println("Numbers greater than " + threshold + ": " + greater);
        in.close();
    }
}
```

Вывод, запуск 1 - массив со слайда, порог 10 (ожидание: больше 10 только 15, значит 1):

```
How many numbers? 7
Number 1: 10
Number 2: -5
Number 3: 0
Number 4: 8
Number 5: -2
Number 6: 15
Number 7: 3
Array: 
10 -5 0 8 -2 15 3 
Maximum value : 15
Minimum value : -5
Sum           : 29
Average value : 4.142857142857143
Positive numbers: 4
Negative numbers: 2
Zero numbers    : 1
Threshold: 10
Numbers greater than 10: 1
```

Вывод, запуск 2 - неправильный ввод (0 вместо количества, слово вместо числа, порог 1). Ожидание руками: массив 5 2 -4, сумма 3, среднее 3/3 = 1.0, больше 1 - числа 5 и 2, значит 2:

```
How many numbers? 3
Number 1: 5
Number 2: x
That is not an integer, try again.
Number 2: 2
Number 3: -4
Array: 
5 2 -4 
Maximum value : 5
Minimum value : -4
Sum           : 3
Average value : 1.0
Positive numbers: 2
Negative numbers: 1
Zero numbers    : 0
Threshold: 1
Numbers greater than 1: 2
```

Пункт 5. Меню: максимум / минимум / среднее / счётчики / выход

Программа один раз читает массив, а потом в цикле показывает меню и выполняет выбранное действие, пока не введут 0. Каждое действие - отдельный case внутри switch. Как работает switch: значение выбора сравнивается с каждой меткой case; при совпадении выполняется код до ближайшего break (без break Java "проваливается" и выполняет следующий case тоже - это самая частая ошибка со switch); default выполняется, если ни одна метка не подошла (например, ввели 9). Условие цикла while (choice != 0) завершает программу на выборе 0. Фигурные скобки вокруг каждого case нужны, чтобы переменные max, min, sum и т. д. в разных case не конфликтовали (у каждого case своя область видимости).

Меню кроме обязательных пунктов 1-4 и выхода включает ещё пункты 5-7: счётчик "больше заданного значения" (пункт 4 задания) и оба Extra (см. ниже) - так вся практика собрана в одной программе. Ввод целого числа вынесен в метод readInt(Scanner, String) - раз одна и та же проверка "число ли это?" нужна в пяти местах, её пишут один раз и вызывают.

```java
import java.util.Scanner;

public class Main {
    static int readInt(Scanner in, String prompt) {
        System.out.print(prompt);
        while (!in.hasNextInt()) {
            System.out.println("That is not an integer, try again.");
            in.next();
            System.out.print(prompt);
        }
        return in.nextInt();
    }

    public static void main(String[] args) {
        Scanner in = new Scanner(System.in);

        int n = 0;
        while (n < 1) {
            n = readInt(in, "How many numbers? ");
            if (n < 1) {
                System.out.println("Need at least 1 number.");
            }
        }
        int[] numbers = new int[n];
        for (int i = 0; i < n; i++) {
            numbers[i] = readInt(in, "Number " + (i + 1) + ": ");
        }

        int choice = -1;
        while (choice != 0) {
            System.out.println();
            System.out.println("1 - maximum");
            System.out.println("2 - minimum");
            System.out.println("3 - average");
            System.out.println("4 - count positive / negative / zero");
            System.out.println("5 - count numbers greater than a value");
            System.out.println("6 - print even numbers");
            System.out.println("7 - sum of positive numbers");
            System.out.println("0 - exit");
            choice = readInt(in, "Your choice: ");

            switch (choice) {
                case 1: {
                    int max = numbers[0];
                    for (int num : numbers) {
                        if (num > max) max = num;
                    }
                    System.out.println("Maximum value : " + max);
                    break;
                }
                case 2: {
                    int min = numbers[0];
                    for (int num : numbers) {
                        if (num < min) min = num;
                    }
                    System.out.println("Minimum value : " + min);
                    break;
                }
                case 3: {
                    int sum = 0;
                    for (int num : numbers) {
                        sum += num;
                    }
                    double average = (double) sum / numbers.length;
                    System.out.println("Average value : " + average);
                    break;
                }
                case 4: {
                    int positive = 0;
                    int negative = 0;
                    int zero = 0;
                    for (int num : numbers) {
                        if (num > 0) {
                            positive++;
                        } else if (num < 0) {
                            negative++;
                        } else {
                            zero++;
                        }
                    }
                    System.out.println("Positive numbers: " + positive);
                    System.out.println("Negative numbers: " + negative);
                    System.out.println("Zero numbers    : " + zero);
                    break;
                }
                case 5: {
                    int limit = readInt(in, "Greater than: ");
                    int greater = 0;
                    for (int num : numbers) {
                        if (num > limit) greater++;
                    }
                    System.out.println("Numbers greater than " + limit + ": " + greater);
                    break;
                }
                case 6: {
                    System.out.print("Even numbers: ");
                    boolean found = false;
                    for (int num : numbers) {
                        if (num % 2 == 0) {
                            System.out.print(num + " ");
                            found = true;
                        }
                    }
                    if (!found) {
                        System.out.print("none");
                    }
                    System.out.println();
                    break;
                }
                case 7: {
                    int positiveSum = 0;
                    for (int num : numbers) {
                        if (num > 0) positiveSum += num;
                    }
                    System.out.println("Sum of positive numbers: " + positiveSum);
                    break;
                }
                case 0:
                    System.out.println("Bye.");
                    break;
                default:
                    System.out.println("No such item, choose 0-7.");
            }
        }
        in.close();
    }
}
```

Вывод - введён массив со слайда, затем выбраны пункты 4, 5 (порог 10), 6, 7 и выход (повторяющееся меню между запусками не сокращалось):

```
How many numbers? 7
Number 1: 10
Number 2: -5
Number 3: 0
Number 4: 8
Number 5: -2
Number 6: 15
Number 7: 3

1 - maximum
2 - minimum
3 - average
4 - count positive / negative / zero
5 - count numbers greater than a value
6 - print even numbers
7 - sum of positive numbers
0 - exit
Your choice: 4
Positive numbers: 4
Negative numbers: 2
Zero numbers    : 1

1 - maximum
2 - minimum
3 - average
4 - count positive / negative / zero
5 - count numbers greater than a value
6 - print even numbers
7 - sum of positive numbers
0 - exit
Your choice: 5
Greater than: 10
Numbers greater than 10: 1

1 - maximum
2 - minimum
3 - average
4 - count positive / negative / zero
5 - count numbers greater than a value
6 - print even numbers
7 - sum of positive numbers
0 - exit
Your choice: 6
Even numbers: 10 0 8 -2 

1 - maximum
2 - minimum
3 - average
4 - count positive / negative / zero
5 - count numbers greater than a value
6 - print even numbers
7 - sum of positive numbers
0 - exit
Your choice: 7
Sum of positive numbers: 36

1 - maximum
2 - minimum
3 - average
4 - count positive / negative / zero
5 - count numbers greater than a value
6 - print even numbers
7 - sum of positive numbers
0 - exit
Your choice: 0
Bye.
```

Пункты 1, 2 и 3 (максимум, минимум, среднее) при том же массиве дали 15, -5 и 4.142857142857143 - совпало с расчётом на Python.

Пограничные случаи, проверенные запуском (строки меню убраны, остались приглашения и результаты). Ввод: 0, затем "abc", затем 3 числа 5 -4 6, пункт 6, выход:

```
How many numbers? 0
Need at least 1 number.
How many numbers? abc
That is not an integer, try again.
How many numbers? 3
Number 1: 5
Number 2: -4
Number 3: 6
Your choice: 6
Even numbers: -4 6 
Your choice: 0
Bye.
```

Числа без чётных (1 -3 5, пункт 6):

```
How many numbers? 3
Number 1: 1
Number 2: -3
Number 3: 5
Your choice: 6
Even numbers: none
Your choice: 0
Bye.
```

Extra 1 и 2. Чётные числа и сумма только положительных

Они включены в меню как пункты 6 и 7 (код выше).

Чётные числа: число чётное, если делится на 2 без остатка, то есть num % 2 == 0 (% - остаток от деления). Три особенности:

- ноль чётный (0 % 2 == 0), поэтому он попал в вывод: "Even numbers: 10 0 8 -2";
- отрицательные тоже проверяются правильно: -2 % 2 даёт 0, значит -2 чётное (проверено запуском);
- ловушка: для нечётных нельзя писать num % 2 == 1. У отрицательного нечётного остаток в Java отрицательный: -5 % 2 равно -1 (проверено запуском), и такая проверка пропустила бы -5. Правильно - num % 2 != 0.

Флаг found (boolean, "нашёл ли хоть одно") нужен, чтобы при отсутствии чётных напечатать "none", а не пустую строку.

Сумма положительных: та же копилка, что sum, но кладём в неё только если num > 0. Для массива со слайда 10 + 8 + 15 + 3 = 36 (ноль и отрицательные пропускаются) - совпало с выводом программы.

Частые ошибки в этой работе

- Целочисленное деление: sum / numbers.length без (double) даёт 4 вместо 4.142857142857143.
- Стартовать max и min с 0 вместо numbers[0]: для массива из одних отрицательных чисел максимум "останется" нулём, которого в массиве нет; для одних положительных так же испортится минимум. Стартуем с первого элемента - он точно из массива.
- Пустой массив (n = 0): numbers[0] падает с ArrayIndexOutOfBoundsException.
- Забытый break в switch: программа выполнит несколько пунктов подряд.
- num % 2 == 1 для проверки нечётности - не работает на отрицательных.
- Переменные в разных case без фигурных скобок: одинаковое имя (например sum) в двух case - ошибка компиляции "variable sum is already defined" (проверено).
- Забытое in.next() при неправильном вводе: бесконечный цикл сообщений об ошибке (проверено: без in.next() условие hasNextInt() остаётся ложным на каждом обороте), потому что испорченное слово остаётся во входном потоке.

Как запускать

В папке с файлом (имя файла обязано совпадать с именем класса - Main.java):

```
javac Main.java
java Main
```

В IntelliJ IDEA - как на слайдах 39 и 42: New Project - Java - имя проекта - Create, ПКМ на src - New - Java Class - Main, вставить код и нажать зелёную кнопку Run.
