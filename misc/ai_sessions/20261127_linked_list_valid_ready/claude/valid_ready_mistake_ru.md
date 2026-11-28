basics-graphics-music · лабораторная 5_5_1, контроллер связного списка · 27 ноября 2026

# Почему было неверно называть valid/ready Юрия нестандартным

Автор — Claude (Opus 5.5), по просьбе Юрия · [English version](valid_ready_mistake.md)

*Markdown-версия файла [valid_ready_mistake_ru.html](valid_ready_mistake_ru.html). Временные диаграммы нарисованы текстом по тем же данным симуляции: `‾` — 1, `_` — 0, `x` — неизвестное значение, `|` — начало нового значения шины, `-` — нет значения, `#` — такт с valid = ready = 1, `^` — передний фронт.*

## Кратко

В нескольких моих ответах утверждалось, что рукопожатие между `start_pointer_request_generator` и `linked_list_controller_1_fetching_next_from_constant_array` — нестандартный valid/ready. Затем контроллер был «исправлен», а в симуляции найдено 20 «нестандартных» фронтов.

**Это неверно.** По правилам рукопожатия AXI передача происходит на переднем фронте, где VALID и READY оба равны 1. До этого фронта источник обязан держать VALID и данные неизменными, а приёмник может посмотреть на данные раньше. Контроллер Юрия читает стартовый указатель в начале списка и поднимает READY на последнем элементе, поэтому каждый указатель читается один раз и подтверждается один раз.

Моё изменение — другой выбор микроархитектуры: подтверждать в начале списка, а не в конце. Никакой ошибки протокола оно не исправляло.

## 1. Дизайн

В лабораторной есть генератор стартовых указателей и контроллер, который обходит связный список, записанный в константные таблицы. Контроллер выдаёт один элемент таблицы за такт. Каждый список заканчивается узлом, у которого данные равны 0 и следующий указатель равен 0:

| Стартовый указатель | 1 | 2 | 6 | 7 | 9 |
|---|---|---|---|---|---|
| Узлы | 1 → 5 → 3 → 10 | 2 → 4 | 6 | 7 → 15 → 8 | 9 → 14 → 11 → 13 → 12 |
| Выход | A B C 0 | D 0 | 0 | E F 0 | G H I J 0 |

Логика рукопожатия в контроллере, без изменений по сравнению с коммитом Юрия `709da7c2`:

```systemverilog
    pointer_t current_pointer, next_pointer;
    logic next_pointer_valid;

    always_comb
    begin
        next_pointer = '0;

        if (out_data_valid)
            next_pointer = next_pointers [current_pointer];
        else if (start_pointer_valid)
            next_pointer = start_pointer;

        next_pointer_valid = (next_pointer != '0);
    end

    always_ff @ (posedge clock)
        if (reset)
            out_data_valid <= 1'b0;
        else
            out_data_valid <= next_pointer_valid;

    always_ff @ (posedge clock)
    begin
        current_pointer <= next_pointer;
        out_data        <= constant_data_array [next_pointer];
    end

    assign start_pointer_ready = ~ next_pointer_valid;
```

*`linked_list_controller_1_fetching_next_from_constant_array.sv`, строки 76–103*

Генератор из коммита посылает восемь запросов. Счётчик в нём увеличивается по `start_pointer_ready`:

```systemverilog
    logic [3:0] n_request;

    always_ff @ (posedge clock)
        if (reset)
            n_request <= '0;
        else if (start_pointer_ready)
            n_request <= n_request + 4'd1;

    assign start_pointer_valid = (n_request != 4'd8);

    always_comb
        case (n_request)
        4'd0:    start_pointer = pointer_t' (7);
        4'd1:    start_pointer = pointer_t' (6);
        4'd2:    start_pointer = pointer_t' (2);
        4'd3:    start_pointer = pointer_t' (1);
        4'd4:    start_pointer = pointer_t' (0);
        default: start_pointer = pointer_t' (9);
        endcase
```

*`start_pointer_request_generator.sv` в коммите 709da7c2, строки 12–30*

В тесте с одним списком последовательность заменена постоянным запросом:

```systemverilog
    assign start_pointer_valid = 1'b1;
    assign start_pointer       = pointer_t' (1);
```

*`start_pointer_request_generator.sv` в рабочем дереве (не закоммичен)*

## 2. Что было сказано

Мои ответы дословно, вместе с запросами, на которые они отвечали:

**Запрос**

> fix synthax error in …/lab_top.sv

**Мой ответ (фрагмент)**

> One thing in the design, which I left alone: `start_pointer_ready = ~ next_pointer_valid` is high in the cycle the controller is *not* taking a pointer. The generator moves on in that cycle. That works for this sequence, but it isn't standard valid/ready.

*Одна вещь в дизайне оставлена без изменений: `start_pointer_ready = ~ next_pointer_valid` равен 1 в том такте, когда контроллер *не* берёт указатель. Генератор переходит дальше именно в этом такте. Для этой последовательности это работает, но это не стандартный valid/ready.*

**Запрос**

> what about now?

**Мой ответ (фрагмент)**

> The handshake still has the issue I mentioned: the controller takes a start pointer while `start_pointer_ready` is 0, and the generator moves on later, when `ready` is 1. It gives the right sequence here, but it isn't standard valid/ready.

*В рукопожатии остаётся упомянутая проблема: контроллер берёт стартовый указатель, пока `start_pointer_ready` равен 0, а генератор переходит дальше позже, когда `ready` равен 1. Последовательность здесь получается правильной, но это не стандартный valid/ready.*

**Запрос**

> fix it for the standard valid/ready

**Мой ответ (фрагмент)**

> The controller now uses standard valid/ready: a start pointer moves only in a cycle where `start_pointer_valid` and `start_pointer_ready` are both 1. Only the controller changed; your generator was already correct.

*Теперь контроллер использует стандартный valid/ready: стартовый указатель передаётся только в такте, где `start_pointer_valid` и `start_pointer_ready` оба равны 1. Изменён только контроллер; генератор уже был правильным.*

**Запрос**

> in what clock cycles (simulation time) I can see a non-standard valid/ready bahaviour if I stash the changes?

**Мой ответ (фрагмент)**

> With both files stashed, 20 rising edges show non-standard valid/ready behaviour, between 45 ns and 505 ns.

*Если спрятать оба файла в stash, нестандартное поведение valid/ready видно на 20 передних фронтах, между 45 и 505 нс.*

## 3. Исходные предположения

1. **Передача — это такт, в котором приёмник начинает пользоваться данными.** Значит, `start_pointer_ready` должен быть равен 1 ровно в том такте, где контроллер загружает `start_pointer`.
2. **READY = 1 означает «я забираю данные прямо сейчас».** Поэтому READY = 1 в такте, где контроллер указатель не загружает, выглядело как потеря данных приёмником.
3. **Приёмник не должен пользоваться данными до подтверждения.** Это привычка из FIFO и skid-буферов, которые забирают данные по `valid & ready`. Это соглашение о стиле дизайна, а не правило протокола.
4. Ни одно из этих предположений не было сверено со спецификацией AXI, прежде чем выдать его за факт.

## 4. Ход рассуждений

1. В блоке `always_comb` ветка `else if (start_pointer_valid) next_pointer = start_pointer;` не содержит `start_pointer_ready` в условии.
2. `assign start_pointer_ready = ~ next_pointer_valid;` означает, что в такте, где контроллер загружает ненулевой указатель, `next_pointer_valid` равен 1, а значит `ready` равен 0.
3. Вместе с предположением 1 это прочитывалось как «загружает при ready = 0 и поднимает ready, когда не загружает», и это было названо нестандартным.
4. На просьбу исправить подтверждение было перенесено в начало списка:

```diff
@@ -76,13 +76,25 @@ import linked_list_controller_configuration_and_types_package::*;
     pointer_t current_pointer, next_pointer;
     logic next_pointer_valid;
 
+    // The controller is busy while it walks a list,
+    // i.e. while the current node has a next node.
+
+    wire list_continues
+        = out_data_valid & (next_pointers [current_pointer] != '0);
+
+    // Standard valid/ready handshake: a start pointer is transferred
+    // in a clock cycle when both start_pointer_valid
+    // and start_pointer_ready are 1.
+
+    assign start_pointer_ready = ~ list_continues;
+
     always_comb
     begin
         next_pointer = '0;
 
-        if (out_data_valid)
+        if (list_continues)
             next_pointer = next_pointers [current_pointer];
-        else if (start_pointer_valid)
+        else if (start_pointer_valid & start_pointer_ready)
             next_pointer = start_pointer;
 
         next_pointer_valid = (next_pointer != '0);
@@ -100,6 +112,4 @@ import linked_list_controller_configuration_and_types_package::*;
         out_data        <= constant_data_array [next_pointer];
     end
 
-    assign start_pointer_ready = ~ next_pointer_valid;
-
 endmodule
```

*Моё изменение контроллера, сейчас лежит в `stash@{0}`*

5. На просьбу назвать фронты была написана проверка, правила которой повторяли мои предположения:

```systemverilog
// My checker (scratch file vr_check.sv), committed controller

wire taken = v & ! odv;   // controller loads start_pointer at this edge

if (taken & ! r)          // "A": loads while ready = 0
    ...
if (v & r & ! taken)      // "B": valid = ready = 1, but no load
    ...
if (n != prev_n & ! prev_v)  // "C": generator counted a transfer while valid = 0
    ...
```

*Три правила моей проверки, сокращённо (комментарии в коде на английском)*

Проверка нашла 20 фронтов. Она была круговой: в ней было закодировано само предположение, поэтому её результат не мог это предположение проверить. Первые отмеченные ею фронты в тесте из коммита, с восемью запросами:

```text
slow_clk               /‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/
rst                    ‾‾‾‾\____________________________________________________________________
start_pointer_valid    ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
start_pointer_ready    ________________/‾‾‾\___/‾‾‾\_______/‾‾‾\_______________/‾‾‾‾‾‾‾\________
valid & ready                          ####    ####        ####                ########
start_pointer          |7                  |6      |2          |1                  |0  |9      |
i_spr.n_request        |0                  |1      |2          |3                  |4  |5      |
i_llc.current_pointer  --------|7  |15 |8  ----|6  ----|2  |4  ----|1  |5  |3  |10 --------|9  |
out_data_valid         ________/‾‾‾‾‾‾‾‾‾‾‾\___/‾‾‾\___/‾‾‾‾‾‾‾\___/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______/‾‾‾‾
out_data               --------|E  |F  |0  ----|0  ----|D  |0  ----|A  |B  |C  |0  --------|G  |
A                              ^               ^       ^           ^                       ^
B                                          ^       ^           ^                   ^
нс                     25  35  45  55  65  75  85  95  105 115 125 135 145 155 165 175 185 195 205
```

*Контроллер и генератор из коммита. Каждые четыре символа по горизонтали — один такт, метки `^` стоят на переднем фронте, где происходит событие. В тактах, отмеченных `####` в строке `valid & ready`, valid = ready = 1, поэтому передача происходит на фронте в конце такого такта.*

- **A** (45, 85, 105, 135, 195 нс): это было названо «берёт указатель при ready = 0». На самом деле контроллер читает указатель, который источник и так обязан держать неизменным, и правила это разрешают.
- **B** (75, 95, 125, 175 нс): это было названо «valid = ready = 1, но указатель игнорируется». На самом деле это рукопожатие, которое завершает передачу уже прочитанного указателя.

## 5. Что было неверно

Правила рукопожатия из спецификации AMBA AXI (Arm IHI 0022, раздел «Handshake process»), в пересказе:

1. Источник выставляет VALID, когда информация готова. Он не должен ждать READY, чтобы выставить VALID.
2. После выставления VALID источник держит VALID и информацию неизменными до переднего фронта, где VALID и READY оба равны 1. Этот фронт и есть передача.
3. Приёмник может выставить READY раньше VALID или дождаться VALID и только потом выставить READY. Он может и снять READY до прихода VALID.
4. Правила ничего не говорят о том, что приёмник делает с информацией до передачи. Раз источник обязан держать её неизменной, читать её заранее безопасно.

Сверка с этими правилами:

- **Фронты «A»:** контроллер читает указатель, неизменность которого гарантирует правило 2. Ничто не требует, чтобы READY был равен 1, когда приёмник впервые смотрит на данные.
- **Фронты «B»:** это и есть передачи. Источник переходит дальше, а контроллер, уже использовав указатель, больше его не берёт.
- **Фронт «C» (375 нс):** генератор из коммита засчитал передачу по одному `ready`, когда `valid` был равен 0, и `valid` снова поднялся для лишнего запроса. Это ошибка подсчёта внутри генератора; на шине это просто новый VALID, а не нарушение протокола. В версии генератора Юрия условие уже заменено на `start_pointer_valid & start_pointer_ready`.
- **Зависимость READY от VALID:** `ready = ~ next_pointer_valid` зависит от `start_pointer_valid`. Правило 3 это разрешает. Запрещена обратная зависимость, когда VALID ждёт READY, а здесь VALID от READY не зависит.

Значит, моё «исправление» не устраняло никакой ошибки протокола. Оно лишь перенесло подтверждение из конца списка в начало.

## 6. Поправка Юрия

> look at the current test with only 1 list. valid is accepted only after all the list is fetched. I do not see anything non-standard in it. if valid is not acknowledged by ready it is supposed to stay high and input valid pointer is supposed to be stable. This is the rules of AXI protocol.

*посмотри на текущий тест с одним списком. valid принимается только после того, как весь список выбран. Я не вижу в этом ничего нестандартного. Если valid не подтверждён сигналом ready, он должен оставаться в 1, а входной указатель должен быть стабильным. Таковы правила протокола AXI.*

Это и есть правила AXI, и тест с одним списком показывает их напрямую. `start_pointer_valid` остаётся равным 1, а указатель — равным 1, пока `start_pointer_ready` не поднимется на последнем элементе каждого списка `ABC`:

```text
slow_clk               /‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/
rst                    ‾‾‾‾\____________________________________________________________________
start_pointer_valid    ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
start_pointer_ready    ____________________/‾‾‾\_______________/‾‾‾\_______________/‾‾‾\________
valid & ready                              ####                ####                ####
start_pointer          |1                                                                      |
i_llc.current_pointer  --------|1  |5  |3  |10 ----|1  |5  |3  |10 ----|1  |5  |3  |10 ----|1  |
out_data_valid         ________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\___/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\___/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\___/‾‾‾‾
out_data               --------|A  |B  |C  |0  ----|A  |B  |C  |0  ----|A  |B  |C  |0  ----|A  |
передача                                       ^                   ^                   ^
чтение                         ^                   ^                   ^                   ^
нс                     25  35  45  55  65  75  85  95  105 115 125 135 145 155 165 175 185 195 205
```

*Тест с одним списком и контроллером Юрия. **чтение**: контроллер читает указатель (45, 95, 145, 195 нс). **передача**: valid = ready = 1 (85, 135, 185 нс). За каждым чтением следует ровно одна передача, а между ними источник держит указатель.*

## 7. Проверка после поправки

За весь прогон теста с одним списком (535 нс, Icarus Verilog 12.0, `tb.sv` из лабораторной):

- 10 передач и 10 чтений; за каждым чтением следует ровно одна передача до следующего чтения.
- 0 нарушений правила для источника: всякий раз, когда `valid` равен 1, а `ready` равен 0, в следующем такте `valid` по-прежнему равен 1, а указатель тот же.

```systemverilog
// Source-side AXI rule, checked on every rising edge (scratch file axi_trace.sv)

if (prev_v & ! prev_r & (! v | p != prev_p))
    source_errors ++;   // valid dropped or pointer changed before the handshake
```

*Правило для источника в том виде, в каком оно здесь проверено*

## 8. Окончательный вывод

**Контроллер Юрия — стандартный приёмник valid/ready в стиле AXI.** Он читает стартовый указатель заранее и подтверждает его на последнем элементе списка. Мой вариант подтверждает в начале. Оба соблюдают правила и различаются только временем:

|  | Контроллер Юрия (коммит 709da7c2) | Мой вариант (в stash@{0}) |
|---|---|---|
| Когда `start_pointer_ready` равен 1 | на последнем элементе списка | всегда, когда список не обходится |
| Когда происходит передача | в конце списка | в начале списка |
| Сколько ждёт источник | весь список | не ждёт лишнего |
| Тактов на список `ABC` | 5 (один пустой такт между списками) | 4 (списки подряд) |
| Передач за 535 нс теста | 10 | 13 |
| Нарушений правила для источника | 0 | 0 |

```text
slow_clk               /‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/
rst                    ‾‾‾‾\____________________________________________________________________
start_pointer_valid    ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
start_pointer_ready    ‾‾‾‾‾‾‾‾\___________/‾‾‾\___________/‾‾‾\___________/‾‾‾\___________/‾‾‾‾
valid & ready              ####            ####            ####            ####            ####
start_pointer          |1                                                                      |
i_llc.current_pointer  --------|1  |5  |3  |10 |1  |5  |3  |10 |1  |5  |3  |10 |1  |5  |3  |10 |
out_data_valid         ________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
out_data               --------|A  |B  |C  |0  |A  |B  |C  |0  |A  |B  |C  |0  |A  |B  |C  |0  |
передача + чтение              ^               ^               ^               ^               ^
нс                     25  35  45  55  65  75  85  95  105 115 125 135 145 155 165 175 185 195 205
```

*Мой вариант на том же тесте с одним списком. Передача и чтение происходят на одном фронте (45, 85, 125, 165, 205 нс), и списки идут друг за другом без пустого такта.*

Какой вариант нужен лабораторной — решение о том, чему учить, а не вопрос правильности. Подтверждение в конце проще и показывает, что READY может прийти намного позже VALID. Подтверждение в начале раньше освобождает источник и убирает пустой такт.

## 9. Выводы на будущее

- Утверждение о протоколе нужно сверять с правилами протокола, а не с привычками дизайна.
- Проверка должна кодировать спецификацию. Моя кодировала моё предположение, поэтому её 20 «нарушений» ничего не доказывали.
- «Нарушает протокол» и «другая микроархитектура» — разные вещи.
- Когда утверждение оспорено, нужно прогнать самый маленький пример. Здесь вопрос решил один список.

## 10. Состояние репозитория

- Рабочее дерево: контроллер — версия Юрия из коммита `709da7c2`. В генераторе — незакоммиченный тест с одним списком.
- `stash@{0}`: мой вариант контроллера вместе с исправлением генератора Юрия, `start_pointer_valid & start_pointer_ready`.
- Этот отчёт: `misc/ai_sessions/20261127_linked_list_valid_ready/claude/`, не добавлен в git.
- Временные диаграммы построены по данным симуляции, снятым в середине каждого такта; `tb.sv` подаёт на `slow_clk` сигнал `clk` (период 10 нс).

## Приложение A. Запросы дословно, с переводом

1. > fix synthax error in /home/verilog/projects/basics-graphics-music/labs/4_microarchitecture/5_5_linked_list_controller/5_5_1_linked_list_controller_fetching_next_from_constant_array/lab_top.sv

   *исправь синтаксическую ошибку в …/lab_top.sv*

2. > what about now?

   *а теперь?*

3. > fix it for the standard valid/ready

   *исправь это под стандартный valid/ready*

4. > in what clock cycles (simulation time) I can see a non-standard valid/ready bahaviour if I stash the changes?

   *в каких тактах (время симуляции) я увижу нестандартное поведение valid/ready, если спрячу изменения в stash?*

5. > look at the current test with only 1 list. valid is accepted only after all the list is fetched. I do not see anything non-standard in it. if valid is not acknowledged by ready it is supposed to stay high and input valid pointer is supposed to be stable. This is the rules of AXI protocol.

   *посмотри на текущий тест с одним списком. valid принимается только после того, как весь список выбран. Я не вижу в этом ничего нестандартного. Если valid не подтверждён сигналом ready, он должен оставаться в 1, а входной указатель должен быть стабильным. Таковы правила протокола AXI.*

6. > create a report in a separate HTML file "how I was wrong to call Yuri's valid/ready non-standard". Describe your assumptions, line of thought, what was incorrect, my correction and your final conclusion. Make two versions - English and Russian. Illustrate with waveforms and code.

   *создай отчёт в отдельном HTML-файле «почему было неверно называть valid/ready Юрия нестандартным». Опиши свои предположения, ход рассуждений, что было неверно, мою поправку и окончательный вывод. Сделай две версии — на английском и на русском. Проиллюстрируй временными диаграммами и кодом.*
