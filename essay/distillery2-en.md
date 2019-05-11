Distillation as the first projection
====================================

_Alexander Konovalov, September 2018_

**This is a translation from [russian source](distillery2.md)**

Interpreter program, reducing complexity
========================================

During the discussion of distillation with colleagues, we had an idea
of an interpreter program, which can execute some programs with less 
algorithmic complexity than with straightforward interpretation.

The narration in this paper will be carried out, as before, **on intuitive
grounds,** but I will try to do the intermediate calculations strictly
formally, while avoiding any exaggeration as much as possible.

The further narration will be carried out, as in [the previous work](distillery-en.md),
in terms of the permutable Refal. And as before, the permutable Refal will
maintain multiplace functions like syntactic sugar.

The usual Refal interpreter has two memory locations: the program field, which
does not change during calculations, and the view-field, which describes
the current state of the calculations. The interpreter program works in steps,
replacing at each step in the view field an active invocation with its result
(according to the rules described in the program field).
The calculations are completed when the result is passive in the view-field —
there are no more function calls.

And if on the contrary: write an interpreter program, which has nothing
interesting in the view-field, but at each step the field of programs is
rewritten?

> Jew sits and thinks. Another Jew approaches.<br/>
> — What are you thinking about?<br/>
> — I think, why in the word "Moses" the letter "r".<br/>
> — It’s not there.<br/>
> — And if you insert?<br/>
> — For what?<br/>
> — My point exactly: for what?<br/>

Why do we write such an interpreter program? Reflections show that it will have
some interesting properties.

The interpreter arguments are the initial state of the the view-field and
the source program:

    <Int  .......... , ....... >
          view-field   program

For simplicity, we assume that the interpreter program by convention begins its
execution with some function `F`, which is called with a passive argument:

    <Int ....... , ....... >
         <F arg>   program

The usual Refal interpreter in this case would begin to rewrite the view-field,
changing the first argument for each iteration and keeping the second one
definite.

Ours will act differently (Why? Just because!). He will prepare the program
ideally for each next step. How? Using supercompilation. But, if
the supercompiler "eats away" a program with a constant argument, the residual
program will simply be a `Go` function that returns a constant. In order for
the supercompiler to produce a non-trivial residual program, you need to "feed"
it a program with parameters. Therefore, the interpreter program enters
the parameters:

    <Int-Loop <Scp .............arg............ >>
                   Go { = <F e.[ • ]> } program

> *Translation to English of this hunk of this paper is prepared by*
> **Solodilova Darya <solodilovaa@yandex.ru>** _at 2019-02-25_

Здесь к исходной программе была добавлена функция `Go`, вызываемая без
параметров, правая часть которой содержит исходный вызов функции
(но с небольшой модификацией).

Будем считать, что по соглашению суперкомпилятор `Scp` преобразует программу,
начиная с функции `Go`. Запись `e.[arg]` вводит параметр суперкомпилятора —
для него это просто некоторое константное неизвестное данное. Объектное
выражение `arg` интерпретируется как _имя_ этого параметра, что подчёркивается
записью его как имени переменной: `e.[arg]`.

Суперкомпилятор `Scp` с такого рода параметрами сделать ничего не может — они
для него чёрные ящики. Он его может либо поместить в остаточную
программу «как есть», либо, если по нему начинается прогонка, обобщить его
до переменной в let-узле.

Суперкомпилятор порождает некоторую остаточную программу. Поскольку на первой
(а вернее, на нулевой) итерации программа специализировалась в общем положении,
результат суперкомпиляции может оказаться тривиальным — с точностью до порядка
и переименования функций и переменных совпадать с исходной программой.

Но смотрим, что дальше делает `Int-Loop`:

    <Int-Loop ........ >
              program0

`Int-Loop` видит некоторую остаточную программу и начальную конфигурацию.
Возможны три случая:

1. Остаточная программа `program0` состоит из единственной функции `Go`
   с пассивной правой частью. В этом случае интерпретатор просто заменяет
   оставшиеся параметры в правой части на их значения (стирает `e.[` и `]`)
   и то, что получилось, возвращает как результат.
2. В тексте остаточной программы есть сужения по входным параметрам. Т.е.,
   например, где-то есть вызов `<Fn …, e.[arg], …>`, а в определении функции
   `Fn` её соответствующий параметр сужается в разных предложениях по-разному.
3. Остаточная программа не содержит нигде сужений по входным параметрам.

**В первом случае** мы имеем остановку интерпретатора с выдачей ответа.

**Второй случай** интереснее. В остаточной программе параметр `e.[arg]` будет
падать в функцию, где по нему будут выполняться одно или несколько сужений.
Поскольку мы используем перестановочный Рефал, все эти сужения будут независимы.
Пусть они имеют вид

    e.0 → P1
    e.0 → P2
    . . .
    e.0 → Pn

Интерпретатор применяет каждое из них к актуальному аргументу `arg`:

    arg : P1
    arg : P2
    . . .
    arg : Pn

Успешно может разрешиться не более одного клэша из нескольких. Если
не выполнился ни один, интерпретатор сообщает об ошибке невозможности
отождествления — аргумент не входит в область определения программы.

Успешно разрешившийся клэш присвоит значения переменным, входящим в `Pi`:

    arg1 ← v.1
    arg2 ← v.2
    . . .
    argK ← v.K

(Здесь `v` — это `s`, `t` или `e`.) Эти переменные и будут новыми параметрами,
а образец `Pi` — аргументом функции `F1` на следующую суперкомпиляцию:

    <Int-Loop .......................arg.................. >
              program0-b … <Fn …, e.[ • ], …> … program0-e

          ↓      ↓      ↓      ↓      ↓      ↓      ↓

    <Int-Loop <Scp ........................arg1.....argK................... >>
                   program0-b … <Fn …, …v.[ •  ]…v.[ •  ]…, …> … program0-e

    <Int-Loop ................arg1.......argJ.......argK.............. >>
              program1-b … v.[ •  ] … v.[ •  ] … v.[ •  ] … program1-e

В предельном случае `K` может оказаться равным нулю — образец `Pi` не содержит
переменных. В этом случае следующая суперкомпиляция просто проинтерпретирует
программу на константных данных и построит тривиальную программу из одного
предложения с пассивной правой частью. Этот случай соответствует корректной
остановке интерпретатора, мы его уже рассматривали.

Наконец, **третий случай** — сужений на параметры нет. Одной из причин может
быть бесконечная рекурсия вида

    Fi {
      EXPR = <Fi EXPR>
    }

В идеале суперкомпилятор должен обнаруживать в графе бесконечную рекурсию
и такие ветви отсекать. В таком случае интерпретатор будет видеть, что
граф (остаточная программа) пустой и выдавать сообщение об ошибке.

Другая причина — кривое обобщение, которое может быть как в корректной
программе, так и в зацикливающейся. Что может делать интерпретатор? Проще
всего «белый флаг» и начинать интерпретировать программу «по простому».
Либо искать какое-нибудь более интеллектуальное решение, например, строить
бесконечное дерево процесса до ближайшего ветвления. Понятно, что в обоих
случаях интерпретатор на зацикливающейся программе зависнет.

Можно ли научить суперкомпилятор никогда не обобщать входные параметры,
чтобы избежать третьего случая? Можно, но тогда сам суперкомпилятор рискует
зациклиться _(доказать не могу, чисто интуитивное предположение)._

В последующих примерах третий случай никогда не будет возникать. Рассмотрим
эти примеры.

### Соглашение о нотации MST-схем

Если аргументы функций на разных этажах схемы короткие, то их легко
изображать в строчку:

    <Int ........ , ....... >
         <Go arg>   program

Но если аргументы длинные, то схема удлиняется и перестаёт влезать в ширину
страницы:

    <Int ............................. , .................................. >
         <StartPointFunction argument>   the-better-program-for-interpreter

Строчки нижних этажей — это метакодированные выражения. Можно, используя
альтернативную нотацию (также представленную в текстах Турчина), записывать
так:

    <Int ↓{ <Go arg> }, ↓{ program }>

    <Int
      ↓{ <StartPointFunction argument> }
      ,
      ↓{ the-better-program-for-interpreter }
    >

Я буду записывать длинные метакодированные аргументы как строки, начинающиеся
со знака стрелки вниз, без фигурных скобок:

    <Int
      ↓ <StartPointFunction argument>
      ,
      ↓ the-better-program-for-iterpreter
    >

В последующих разделах нам потребуются приподнятые переменные:

    <Int ... e.X . , ....... >
         <Go  •  >   program

В «вертикальной нотации» приподнятые переменные будут окружаться знаками `#`:

    <Int
      ↓ <StartPointFunction #e.X#>
      ,
      ↓ the-better-program-for-interpreter
    >


Рекурсивное вычисление чисел Фибоначчи
--------------------------------------

Рассмотрим следующую программу:

    Fib {
      ε = 1;
      I = 1;
      I I e.N = <Add <Fib e.N> <Fib I e.N>>;
    }

Здесь (в порядке читерства) аргумент функции Фибоначчи представлен в единичной
системе счиления при помощи счётных палочек: `I`, `I I`, `I I I`…, результат
функции — как встроенный числовой тип данных Рефала.

Очевидно, что эта функция обладает экспоненциальной сложностью при вычислении
обычным интерпретатором. Посмотрим, как её будет вычислять наш интерпретатор.
Вычислим пятое число Фибоначчи:

    <Int
      ↓ <Fib I I I I I>
      ,
      ↓ Fib {
      ↓   ε = 1;
      ↓   I = 1;
      ↓   I I e.N = <Add <Fib e.N> <Fib I e.N>>;
      ↓ }
    >

Интерпретатор должен заменить аргумент на параметр и выполнить суперкомпиляцию
исходной программы:

    <Int-Loop
      <Scp
        ↓ Go { = <Fib e.[I I I I I]> }
        ↓
        ↓ Fib {
        ↓   ε = 1;
        ↓   I = 1;
        ↓   I I e.N = <Add <Fib e.N> <Fib I e.N>>;
        ↓ }
      >
    >

Нетрудно убедиться, что суперкомпилятор воспроизведёт исходную программу
с точностью до имён функций и переменных:

    <Int-Loop
      ↓ Go { = <F1 e.[I I I I I]> }
      ↓
      ↓ F1 {
      ↓   ε = 1;
      ↓   I = 1;
      ↓   I I e.0 = <Add <F1 e.0> <F1 I e.0>>;
      ↓ }
    >

Фрагмент входных данных падает на функцию `F1`, где имеются три различных
сужения аргумента:

    e.0 → ε
    e.0 → I
    e.0 → I I e.0

Строим клэши:

    I I I I I : ε        =>  fail
    I I I I I : I        =>  fail
    I I I I I : I I e.0  =>  I I I ← e.0

Последнее сужение применимо, делаем шаг:

    <Int-Loop
      <Scp
        ↓ Go { = <F1 I I e.[I I I]> }
        ↓
        ↓ F1 {
        ↓   ε = 1;
        ↓   I = 1;
        ↓   I I e.0 = <Add <F1 e.0> <F1 I e.0>>;
        ↓ }
      >
    >

[Построим граф суперкомпиляции программы](distillery/7000-fibint.png) (очевидные
транзитные шаги заменены многоточием):

Остаточная программа примет вид:

    Go { = <F1 e.[I I I] }

    F1 {
      ε = 2;
      I = 3;
      I I e.0 = <Add <F1 e.0> <F1 I e.0>>;
    }

Состояние интерпретатора:

    <Int-Loop
      ↓ Go { = <F1 e.[I I I]> }
      ↓
      ↓ F1 {
      ↓   ε = 2;
      ↓   I = 3;
      ↓   I I e.0 = <Add <F1 e.0> <F1 I e.0>>;
      ↓ }
    >

Шаг похож на предыдущий, имеем те же три сужения

    e.0 → ε
    e.0 → I
    e.0 → I I e.0

Строим клэши:

    I I I : ε        =>  fail
    I I I : I        =>  fail
    I I I : I I e.0  =>  I ← e.0

И новый шаг вычислений интерпретатора:

    <Int-Loop
      <Scp
        ↓ { Go = <F1 I I e.[I]> }
        ↓
        ↓ F1 {
        ↓   ε = 2;
        ↓   I = 3;
        ↓   I I e.0 = <Add <F1 e.0> <F1 I e.0>>;
        ↓ }
      >
    >

[Граф суперкомпиляции](distillery/7010-fibint.png) (тут для наглядности
транзитные шаги показаны полностью):

Состояние интерпретатора:

    <Int-Loop
      ↓ Go { = <F1 e.[I]> }
      ↓
      ↓ F1 {
      ↓   ε = 5;
      ↓   I = 8;
      ↓   I I e.0 = <Add <F1 e.0> <F1 I e.0>>;
      ↓ }
    >

Программа подобна предыдущей, сужения на `e.0` те же. Клэши:

    I : ε        =>  fail
    I : I        =>  success
    I : I I e.0  =>  fail

Новых параметров нет. Строим новое состояние интерпретатора:

    <Int-Loop
      <Scp
        ↓ Go { = <F1 I> }
        ↓
        ↓ F1 {
        ↓   ε = 5;
        ↓   I = 8;
        ↓   I I e.0 = <Add <F1 e.0> <F1 I e.0>>;
        ↓ }
      >
    >

Даже граф суперкомпиляции строить не нужно, очевидно, что следующий шаг
примет вид:

    <Int-Loop
      ↓ Go { = 8 }
    >

Или в «горизонтальной форме»:

    <Int-Loop .......... >
              Go { = 8 }

(Понятно, что метакод от символа есть сам символ, но я для единообразия его
всё равно опустил.)

Начальная конфигурация пассивна, остаточная программа пустая. Интерпретатор
выдаёт ответ `8`.

Можно заметить, что на каждой итерации интерпретатор сокращает входной аргумент
на `I I`, а интерпретируемая программа остаётся подобной программе на предыдущем
шаге. Таким образом, продолжительность суперкомпиляции на каждом шаге в целом
константна, число шагов пропорционально длине аргумента. Следовательно,
**сложность работы интерпретатора — линейна от аргумента функции!**


Наивное обращение списка
------------------------

Рассмотрим простой алгоритм обращения лисповского списка:

* если список пустой — то его обращение пустое,
* если список непустой — то его обращение есть конкатенация обращения хвоста
  и списка из одной головы.

На Хаскеле, где однонаправленный список встроен в язык, эту программу
можно описать как

    nrev x:xs = append (nrev xs) [x]
    nrev [] = []

    append (x:xs) ys = x : append xs ys
    append []     ys = ys

Изобразим эту программу на Рефале так. Cons-ячейку будем записывать как
`(t.Head t.Tail)`, пустой список — `NIL`.

Программа примет вид:

    nrev {
      (t.x t.xs) = <append <nrev t.xs> (t.x NIL)>;
      NIL = NIL;
    }

    append {
      (t.x t.xs) t.ys = (t.x <append t.xs t.ys>);
      NIL        t.ys = t.ys;
    }

Нетрудно показать, что программа имеет квадратичную сложность. Инвертируем
список из четырёх элементов:

    <nrev (1 (2 (3 (4 NIL))))>
    <append <nrev (2 (3 (4 NIL)))> (1 NIL)>
    <append <append <nrev (3 (4 NIL))> (2 NIL)> (1 NIL)>
    <append <append <append <nrev (4 NIL)> (3 NIL)> (2 NIL)> (1 NIL)>
    <append <append <append <append <nrev NIL> (4 NIL)> (3 NIL)> (2 NIL)> (1 NIL)>
    <append <append <append <append NIL (4 NIL)> (3 NIL)> (2 NIL)> (1 NIL)>
    <append <append <append (4 NIL) (3 NIL)> (2 NIL)> (1 NIL)>
    <append <append (4 <append NIL (3 NIL)>) (2 NIL)> (1 NIL)>
    <append <append (4 (3 NIL)) (2 NIL)> (1 NIL)>
    <append (4 <append (3 NIL) (2 NIL)>) (1 NIL)>
    <append (4 (3 <append NIL (2 NIL)>)) (1 NIL)>
    <append (4 (3 (2 NIL))) (1 NIL)>
    (4 <append (3 (2 NIL)) (1 NIL)>)
    (4 (3 <append (2 NIL) (1 NIL)>))
    (4 (3 (2 <append NIL (1 NIL)>)))
    (4 (3 (2 (1 NIL))))

16 шагов. Нетрудно убедиться, что для списка длины 5 мы получим 25 шагов.

Теперь интерпретируем нашим, суперкомпилирующим интерпретатором:

    <Int
      ↓ <nrev (1 (2 (3 (4 NIL))))>
      ,
      ↓ nrev {
      ↓   (t.x t.xs) = <append <nrev t.xs> (t.x NIL)>;
      ↓   NIL = NIL;
      ↓ }
      ↓
      ↓ append {
      ↓   (t.x t.xs) t.ys = (t.x <append t.xs t.ys>);
      ↓   NIL        t.ys = t.ys;
      ↓ }
    >

Нулевой шаг — ввод параметра и суперкомпиляция исходной программы:

    <Int-Loop
      <Scp
        ↓ Go { = <nrev t.[(1 (2 (3 (4 NIL))))]> }
        ↓
        ↓ nrev {
        ↓   (t.x t.xs) = <append <nrev t.xs> (t.x NIL)>;
        ↓   NIL = NIL;
        ↓ }
        ↓
        ↓ append {
        ↓   (t.x t.xs) t.ys = (t.x <append t.xs t.ys>);
        ↓   NIL        t.ys = t.ys;
        ↓ }
      >
    >

Суперкомпиляция повторит исходную программу с переименованием функций
и повышением местности.

    <Int-Loop
      ↓ <F1 t.[(1 (2 (3 (4 NIL))))]>
      ↓
      ↓ F1 {
      ↓   (t.1 t.0) = <F2 <F1 t.0>, (t.1 NIL)>;
      ↓   NIL = NIL;
      ↓ }
      ↓
      ↓ F2 {
      ↓   (t.1 t.0), t.2 = (t.1 <F1 t.0, t.2>);
      ↓   NIL,       t.2 = t.2;
      ↓ }
    >

Для параметра `t.[(1 (2 (3 (4 NIL))))]` имеем сужения:

    t.[…] → (t.1 t.0)
    t.[…] → NIL

Строим клэши

    (1 (2 (3 (4 NIL)))) : (t.1 t.0) => 1 ← t.1, (2 (3 (4 NIL))) ← t.0
    (1 (2 (3 (4 NIL)))) : NIL       => fail

Делаем шаг:

    <Int-Loop
      <Scp
        ↓ <F1 (t.[1] t.[(2 (3 (4 NIL)))])>
        ↓
        ↓ F1 {
        ↓   (t.1 t.0) = <F2 <F1 t.0>, (t.1 NIL)>;
        ↓   NIL = NIL;
        ↓ }
        ↓
        ↓ F2 {
        ↓   (t.1 t.0), t.2 = (t.1 <F1 t.0, t.2>);
        ↓   NIL,       t.2 = t.2;
        ↓ }
      >
    >

Суперкомпиляция нам даст следующий [граф](distillery/7020-nrev.png).

Нетрудно показать, что суперкомпилятор нам даст такой результат:

    <Int-Loop
      ↓ Go { = <F3 <F1 t.[(2 (3 (4 NIL)))]>> }
      ↓
      ↓ F1 {
      ↓   (t.1 t.0) = <F2 <F1 t.0>, (t.1 NIL)>;
      ↓   NIL = NIL;
      ↓ }
      ↓
      ↓ F2 {
      ↓   (t.1 t.0), t.2 = (t.1 <F1 t.0, t.2>);
      ↓   NIL,       t.2 = t.2;
      ↓ }
      ↓
      ↓ F3 {
      ↓   (t.1 t.0) = (t.1 <F3 t.0>);
      ↓   NIL = (t.[1] NIL);
      ↓ }
    >

Входной фрагмент `t.[1]` нигде не бьётся, фрагмент `t.[(2 (3 (4 NIL)))]` падает
на функцию `F1`, где имеются сужения для аргумента

    t.[…] → (t.1 t.0)
    t.[…] → NIL

Стоим клэши:

    (2 (3 (4 NIL))) : (t.1 t.0) => 2 ← t.1, (3 (4 NIL)) ← t.0
    (2 (3 (4 NIL))) : NIL       => fail

Переходим к следующему шагу:

    <Int-Loop
      <Scp
        ↓ <F3 <F1 (t.[2] t.[(3 (4 NIL))])>>
        ↓
        ↓ F1 {
        ↓   (t.1 t.0) = <F2 <F1 t.0>, (t.1 NIL)>;
        ↓   NIL = NIL;
        v }
        ↓
        ↓ F2 {
        ↓   (t.1 t.0), t.2 = (t.1 <F1 t.0, t.2>);
        ↓   NIL,       t.2 = t.2;
        ↓ }
        ↓
        ↓ F3 {
        ↓   (t.1 t.0) = (t.1 <F3 t.0>);
        ↓   NIL = (t.[1] NIL);
        ↓ }
      >
    >

    <Int-Loop
      ↓ Go { = <F3 <F1 t.[(3 (4 NIL))]>>
      ↓
      ↓ F1 {
      ↓   (t.1 t.0) = <F2 <F1 t.0>, (t.1 NIL)>;
      ↓   NIL = NIL;
      ↓ }
      ↓
      ↓ F2 {
      ↓   (t.1 t.0), t.2 = (t.1 <F1 t.0, t.2>);
      ↓   NIL,       t.2 = t.2;
      ↓ }
      ↓
      ↓ F3 {
      ↓   (t.1 t.0) = (t.1 <F3 t.0>);
      ↓   NIL = (t.[2] (t.[1] NIL));
      ↓ }
    >

Нетрудно показать, что следующие шаги будут:

    <Int-Loop
      <Scp
        ↓ Go { = <F3 <F1 (t.[3] t.[(4 NIL)]))>> }
        ↓
        ↓ F1 {
        ↓   (t.1 t.0) = <F2 <F1 t.0>, (t.1 NIL)>;
        ↓   NIL = NIL;
        ↓ }
        ↓
        ↓ F2 {
        ↓   (t.1 t.0), t.2 = (t.1 <F1 t.0, t.2>);
        ↓   NIL,       t.2 = t.2;
        ↓ }
        ↓
        ↓ F3 {
        ↓   (t.1 t.0) = (t.1 <F3 t.0>);
        ↓   NIL = (t.[2] (t.[1] NIL));
        ↓ }
      >
    >

    <Int-Loop
      ↓ Go { = <F3 <F1 t.[(4 NIL)]>> }
      ↓
      ↓ F1 {
      ↓   (t.1 t.0) = <F2 <F1 t.0>, (t.1 NIL)>;
      ↓   NIL = NIL;
      ↓ }
      ↓
      ↓ F2 {
      ↓   (t.1 t.0), t.2 = (t.1 <F1 t.0, t.2>);
      ↓   NIL,       t.2 = t.2;
      ↓ }
      ↓
      ↓ F3 {
      ↓   (t.1 t.0) = (t.1 <F3 t.0>);
      ↓   NIL = (t.[3] (t.[2] (t.[1] NIL)));
      ↓ }
    >

    <Int-Loop
      <Scp
        ↓ Go { = <F3 <F1 (t.[4] t.[NIL])>> }
        ↓
        ↓ F1 {
        ↓   (t.1 t.0) = <F2 <F1 t.0>, (t.1 NIL)>;
        ↓   NIL = NIL;
        ↓ }
        ↓
        ↓ F2 {
        ↓   (t.1 t.0), t.2 = (t.1 <F1 t.0, t.2>);
        ↓   NIL,       t.2 = t.2;
        ↓ }
        ↓
        ↓ F3 {
        ↓   (t.1 t.0) = (t.1 <F3 t.0>);
        ↓   NIL = (t.[3] (t.[2] (t.[1] NIL)));
        ↓ }
      >
    >

    <Int-Loop
      ↓ Go { = <F3 <F1 t.[NIL]>> }
      ↓
      ↓ F1 {
      ↓   (t.1 t.0) = <F2 <F1 t.0>, (t.1 NIL)>;
      ↓   NIL = NIL;
      ↓ }
      ↓
      ↓ F2 {
      ↓   (t.1 t.0), t.2 = (t.1 <F1 t.0, t.2>);
      ↓   NIL,       t.2 = t.2;
      ↓ }
      ↓
      ↓ F3 {
      ↓   (t.1 t.0) = (t.1 <F3 t.0>);
      ↓   NIL = (t.[4] (t.[3] (t.[2] (t.[1] NIL))));
      ↓ }
    >

Имеем те же сужения и клэши

    NIL : (t.1 t.2) => fail
    NIL : NIL       => success



    <Int-Loop
      <Scp
        ↓ Go { <F3 <F1 NIL>> }
        ↓
        ↓ F1 {
        ↓   (t.1 t.0) = <F2 <F1 t.0>, (t.1 NIL)>;
        ↓   NIL = NIL;
        ↓ }
        ↓
        ↓ F2 {
        ↓   (t.1 t.0), t.2 = (t.1 <F1 t.0, t.2>);
        ↓   NIL,       t.2 = t.2;
        ↓ }
        ↓
        ↓ F3 {
        ↓   (t.1 t.0) = (t.1 <F3 t.0>);
        ↓   NIL = (t.[4] (t.[3] (t.[2] (t.[1] NIL))));
        ↓ }
      >
    >

    <Int-Loop ............................................ >
              Go { = (t.[4] (t.[3] (t.[2] (t.[1] NIL)))) }

Функция `Go` едиственная, её правая часть — пассивная, интерпретатор стирает
в ней `t.[` и `]` и то, что получилось, возвращает как результат:
`(4 (3 (2 (1 NIL))))`.

Нетрудно заметить, что здесь тоже на каждом шаге уровень вложенности входного
аргумента уменьшается на единицу, а значит, вычисления тоже выполняются
линейно.


Двойной проход по списку
------------------------

Рассмотрим программу, которая делает два прохода по строке, заменяя в ней
сначала `'A'` на `'B'`, а потом `'B'` на `'C'`:

    Fabc { e.X = <Fbc <Fab e.X>> }

    Fab { e.X = <DoFab ε, eX> }

    DoFab {
      e.Res, 'A' e.Arg = <DoFab e.Res 'B', e.Arg>;
      e.Res, s.Y e.Arg ! s.Y ≠ 'A' = <DoFab e.Res s.Y, e.Arg>;
      e.Res, ε = e.Res;
    }

    Fbc { e.X = <DoFbc ε, e.X> }

    DoFbc {
      e.Res, 'B' e.Arg = <DoFbc e.Res 'C', e.Arg>;
      e.Res, s.Y e.Arg ! s.Y ≠ 'B' = <DoFbc e.Res s.Y, e.Arg>;
      e.Res, ε = e.Res;
    }

Эта программа выполняется и так за линейное время, ускорить её никак нельзя.
Но пример рассмотреть нужно, поскольку он продемонстрирует некоторые тонкости
работы нашего интерпретатора.

Рассмотрим вычисление функции `<Fabc 'BARDAK'>`. Запускаем интерпретатор:

    <Int
      ↓ <Fabc 'BARDAK'>
      ,
      ↓ Fabc { e.X = <Fbc <Fab e.X>> }
      ↓
      ↓ Fab { e.X = <DoFab ε, eX> }
      ↓
      ↓ DoFab {
      ↓   e.Res, 'A' e.Arg = <DoFab e.Res 'B', e.Arg>;
      ↓   e.Res, s.Y e.Arg ! s.Y ≠ 'A' = <DoFab e.Res s.Y, e.Arg>;
      ↓   e.Res, ε = e.Res;
      ↓ }
      ↓
      ↓ Fbc { e.X = <DoFbc ε, e.X> }
      ↓
      ↓ DoFbc {
      ↓   e.Res, 'B' e.Arg = <DoFbc e.Res 'C', e.Arg>;
      ↓   e.Res, s.Y e.Arg ! s.Y ≠ 'B' = <DoFbc e.Res s.Y, e.Arg>;
      ↓   e.Res, ε = e.Res;
      ↓ }
    >

    <Int-Loop
      <Scp
        ↓ Go { = <Fabc e.['BARDAK']> }
        ↓
        ↓ Fabc { e.X = <Fbc <Fab e.X>> }
        ↓
        ↓ Fab { e.X = <DoFab ε, eX> }
        ↓
        ↓ DoFab {
        ↓   e.Res, 'A' e.Arg = <DoFab e.Res 'B', e.Arg>;
        ↓   e.Res, s.Y e.Arg ! s.Y ≠ 'A' = <DoFab e.Res s.Y, e.Arg>;
        ↓   e.Res, ε = e.Res;
        ↓ }
        ↓
        ↓ Fbc { e.X = <DoFbc ε, e.X> }
        ↓
        ↓ DoFbc {
        ↓   e.Res, 'B' e.Arg = <DoFbc e.Res 'C', e.Arg>;
        ↓   e.Res, s.Y e.Arg ! s.Y ≠ 'B' = <DoFbc e.Res s.Y, e.Arg>;
        ↓   e.Res, ε = e.Res;
        ↓ }
      >
    >

Граф суперкомпиляции рассматривать не буду, поскольку его можно найти
[в предыдущем эссе](essay.md). Следующий шаг:

    <Int-Loop
      ↓ Go { = <F1 ε, e.['BARDAK']> }
      ↓
      ↓ F1 {
      ↓   e.1, 'A' e.0 = <F1 e.1 'B', e.0>;
      ↓   e.1, s.2 e.0 ! s.2 ≠ 'A' = <F1 e.1 s.2, e.0>;
      ↓   e.1, ε = <F2 ε, e.1>;
      ↓ }
      ↓
      ↓ F2 {
      ↓   e.3, 'B' e.1 = <F2 e.3 'C', e.1>;
      ↓   e.3, s.4 e.1 ! s.4 ≠ 'B' = <F2 e.3 s.4, e.1>;
      ↓   e.3, ε = e.3;
      ↓ }
    >

Параметр `e.['BARDAK']` падает в функцию `F1`, где по его значению происходит
ветвление. Строим клэши:

    'BARDAK' : 'A' e.0             => fail
    'BARDAK' : s.2 e.0 ! s.2 ≠ 'A' => 'B' ← s.2, 'ARDAK' ← e.0
    'BARDAK' : ε                   => fail

Разбиваем параметр на `s.['B'] e.['ARDAK']`:

    <Int-Loop
      <Scp
        ↓ Go { = <F1 ε, s.['B'] e.['ARDAK']> }
        ↓
        ↓ F1 {
        ↓   e.1, 'A' e.0 = <F1 e.1 'B', e.0>;
        ↓   e.1, s.2 e.0 ! s.2 ≠ 'A' = <F1 e.1 s.2, e.0>;
        ↓   e.1, ε = <F2 ε, e.1>;
        ↓ }
        ↓
        ↓ F2 {
        ↓   e.3, 'B' e.1 = <F2 e.3 'C', e.1>;
        ↓   e.3, s.4 e.1 ! s.4 ≠ 'B' = <F2 e.3 s.4, e.1>;
        ↓   e.3, ε = e.3;
        ↓ }
      >
    >

