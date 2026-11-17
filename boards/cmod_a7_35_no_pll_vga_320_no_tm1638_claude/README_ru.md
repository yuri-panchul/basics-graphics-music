*Создано Claude Opus 5.5 (`claude-opus-5-5`) в Claude Code 2.1.325, уровень усилий xhigh, по промпту Юрия Панчула. Дословный промпт — в [приложении](#приложение-промпты).*

# Cmod A7-35T без TM1638 и без MMCM: VGA 320x480

Конфигурация платы `cmod_a7_35_no_pll_vga_320_no_tm1638_claude`. English version: [README.md](README.md).

Это [cmod_a7_35_no_pll_vga_320_claude](../cmod_a7_35_no_pll_vga_320_claude/README_ru.md) без модуля TM1638. **Упражнения
получают две кнопки Cmod A7 в качестве своих кнопок и два её светодиода в
качестве своих светодиодов, а семисегментного индикатора нет.** Всё остальное
— как у cmod_a7_35_no_pll_vga_320_claude: тактовая частота 12 МГц без MMCM, VGA 320x480 с пикселями ровно в два при частоте строк 30 кГц, которую некоторые мониторы не принимают, микрофон, ЦАП, выводы и соединения. Другие конфигурации без TM1638 —
[cmod_a7_35_no_tm1638_claude](../cmod_a7_35_no_tm1638_claude/README_ru.md), [cmod_a7_35_no_pll_vga_304_no_tm1638_claude](../cmod_a7_35_no_pll_vga_304_no_tm1638_claude/README_ru.md).

## Содержание

* [Чем отличается](#чем-отличается)
* [Как это сделано](#как-это-сделано)
* [Оборудование и соединения](#оборудование-и-соединения)
* [Сборка и запуск упражнений](#сборка-и-запуск-упражнений)
* [Состояние](#состояние)
* [Файлы](#файлы)
* [Приложение: промпты](#приложение-промпты)

## Чем отличается

| | [cmod_a7_35_no_pll_vga_320_claude](../cmod_a7_35_no_pll_vga_320_claude/README_ru.md) | cmod_a7_35_no_pll_vga_320_no_tm1638_claude, эта |
|---|---|---|
| Кнопки упражнений | 8 кнопок TM1638 | BTN0 и BTN1 на Cmod A7: `key[0]` и `key[1]`, они же `sw[0]` и `sw[1]` |
| Светодиоды упражнений | 8 светодиодов TM1638, первые два также на LED1 и LED2 Cmod A7 | LED1 и LED2 на Cmod A7: `led[0]` и `led[1]` |
| Семисегментный индикатор | 8 разрядов TM1638 | Нет |
| Кнопка сброса | Любая кнопка Cmod | Нет: обе кнопки — это кнопки упражнений |
| DIP 26, 27, 28 | TM1638 STB, CLK, DIO | Не подключены |

Нажатая кнопка даёт 1; светодиод горит при 1. Упражнения получают один
разряд семисегментного индикатора, который никуда не идёт, поэтому
упражнение, управляющее индикатором, собирается и работает, а вывод на
индикатор теряется. Так же теряется всё, что упражнение показывает на
светодиодах после первых двух.

После загрузки проект находится в сбросе первые три такта. Ни одна кнопка его не сбрасывает: чтобы начать упражнение
заново, загрузите ПЛИС ещё раз командой `./04_configure_fpga.bash`.

Проект держит выводы DIP 26 и 27, STB и CLK модуля TM1638 в cmod_a7_35_no_pll_vga_320_claude, в
высоком уровне и не управляет выводом DIP 28. Оставьте эти три вывода
неподключёнными.

## Как это сделано

В [board_specific_top.sv](board_specific_top.sv) две строки кода. Он
определяет `FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE` и включает
`board_specific_top.sv` из cmod_a7_35_no_pll_vga_320_claude, который тогда не создаёт TM1638, хотя
`peripherals/lab_specific_board_config.svh` его включает. Другие платы
репозитория без TM1638, например `tang_nano_9k_hdmi_no_tm1638`, сделаны так
же, но некоторые из них рисуют виртуальный TM1638 на экране; эта не рисует.

[board_specific.xdc](board_specific.xdc) — тот же, что у cmod_a7_35_no_pll_vga_320_claude. Строки
выводов DIP 26, 27 и 28 в нём остаются раскомментированными, потому что у
включённого модуля верхнего уровня эти порты есть.

## Оборудование и соединения

Детали, источник 3,3 В, сборка и таблицы соединений — как у
[cmod_a7_35_no_pll_vga_320_claude](../cmod_a7_35_no_pll_vga_320_claude/README_ru.md), но без TM1638: не ставьте модуль и его
пять проводов. Вывод DIP 25 по-прежнему идёт на шину GND. Выводы коротко:

| Cmod A7 | Подключить к |
|---------|--------------|
| Pmod JA | TinyVGA |
| DIP 21, 22, 23 | ЦАП BCK, DIN и LCK у GY-PCM5102 или WS у WeAct |
| DIP 24, VU | Вариант A: ничего. Вариант B: только вход стабилизатора |
| DIP 25 | Шина GND |
| DIP 26, 27, 28 | Ничего |
| DIP 29, 30, 31, 32 | INMP441 SCK, WS, L/R, SD |

На рисунках этого каталога нет TM1638; они есть для обоих модулей ЦАП: WeAct
I2S Earphone Module (PCM5100A) и GY-PCM5102 (PCM5102A). Надписи на рисунках —
на английском.

### Вариант A: 3,3 В от Pmod TPH2

![Соединения с WeAct PCM5100A и Pmod TPH2](wiring_weact_tph2.png)

![Соединения с GY-PCM5102 и Pmod TPH2](wiring_gy_pcm5102_tph2.png)

### Вариант B: 3,3 В от стабилизатора

![Соединения с WeAct PCM5100A и стабилизатором 3,3 В](wiring_weact_regulator.png)

![Соединения с GY-PCM5102 и стабилизатором 3,3 В](wiring_gy_pcm5102_regulator.png)

### Микрофон, ЦАП и стабилизатор, вставленные в макетную плату

[breadboard_weact.png](breadboard_weact.png) с модулем WeAct и
[breadboard_gy_pcm5102.png](breadboard_gy_pcm5102.png) с GY-PCM5102
показывают микрофон, ЦАП и стабилизатор варианта B, вставленные прямо в
макетную плату. Векторные версии всех рисунков — файлы `.svg` с теми же
именами.

## Сборка и запуск упражнений

В каталоге упражнения один раз выберите плату командой
`./06_choose_another_fpga_board.bash` и укажите `cmod_a7_35_no_pll_vga_320_no_tm1638_claude`. Затем собирайте и
загружайте, как для [cmod_a7_35_no_pll_vga_320_claude](../cmod_a7_35_no_pll_vga_320_claude/README_ru.md):

```bash
./03_synthesize_for_fpga.bash
./04_configure_fpga.bash
```

Скрипты используют Vivado для всех плат, имя которых начинается с `cmod_a7`,
поэтому для этой конфигурации скрипты менять не нужно.

## Состояние

Собрано в Vivado 2026.1 с файлом конфигурации скриптов,
`peripherals/lab_specific_board_config.svh`, который включает TM1638: сборки
показывают, что эта конфигурация всё равно его не создаёт.

| Упражнение | LUT | Регистры | Худший запас по setup |
|------------|----:|---------:|----------------------:|
| `labs/1_basics/1_05_7seven_segment_letter` | 41 | 44 | 79,3 нс |
| `labs/2_graphics/2_3_color_stripes` | 54 | 45 | 79,2 нс |
| `labs/3_music/3_10_spectrum_analyzer` | 2340 | 1471 | 68,1 нс |

Во всех сборках нет ошибок и критических предупреждений, и все временные
ограничения выполнены на 12 МГц, при периоде такта 83,3 нс, без MMCM и PLL.
Ни в одном нетлисте нет модуля TM1638. Vivado выдаёт предупреждение правил
проектирования CFGBVS-1, как и для cmod_a7_35_claude; оно не мешает созданию
битового потока.

**На реальной плате ещё не проверено.**

## Файлы

| Файл | Что это |
|------|---------|
| [board_specific_top.sv](board_specific_top.sv) | Определяет `FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE` и включает модуль верхнего уровня из cmod_a7_35_no_pll_vga_320_claude |
| [board_specific.xdc](board_specific.xdc) | Тот же, что в cmod_a7_35_no_pll_vga_320_claude |
| [board_specific.tcl](board_specific.tcl) | Микросхема ПЛИС для Vivado |
| `wiring_*.svg`, `wiring_*.png` | Схемы соединений без TM1638 для обоих модулей ЦАП и обоих источников 3,3 В |
| `breadboard_*.svg`, `breadboard_*.png` | Раскладки на макетной плате без TM1638 для обоих модулей ЦАП |
| README.md, README.html | Эта инструкция на английском |
| README_ru.md, README_ru.html | Она же на русском |

Рисунки делают генераторы cmod_a7_35_claude, запущенные с именем этой конфигурации;
для каждого имени, в котором есть `_no_tm1638`, они не рисуют TM1638:

```bash
cd ../cmod_a7_35_claude
python3 generate_wiring_diagram.py cmod_a7_35_no_pll_vga_320_no_tm1638_claude
python3 generate_breadboard_diagram.py cmod_a7_35_no_pll_vga_320_no_tm1638_claude
cd ../cmod_a7_35_no_pll_vga_320_no_tm1638_claude

for f in wiring_*.svg breadboard_*.svg
do
    # ${f%.svg} is the file name without the .svg suffix
    inkscape "$f" --export-type=png --export-dpi=96 \
        --export-background=white --export-filename="${f%.svg}.png"
done
```

## Приложение: промпты

Остальной проект появился из промптов в приложении к
[cmod_a7_35_no_pll_vga_320_claude](../cmod_a7_35_no_pll_vga_320_claude/README_ru.md#приложение-промпты). Эта конфигурация
появилась из следующего промпта, который Юрий Панчул отправил в том же сеансе
Claude Code 16 ноября 2026 года, дословно, с переводом на русский. Время —
тихоокеанское (UTC−8).

**23:17**:

```text
keep README.csv with CR-LF for now; I will fix it later; first commint and push, then create 3 new configurations that do not use tm1638, just have 2 buttons, 2 leds and no 7-segement display: cmod_a7_35_no_tm1638
cmod_a7_35_no_pll_vga_304_no_tm1638
cmod_a7_35_no_pll_vga_320_no_tm1638
```

```text
пока оставь README.csv с CR-LF, я исправлю это позже; сначала сделай коммит и push, затем создай 3 новые конфигурации, которые не используют TM1638, а имеют только 2 кнопки, 2 светодиода и никакого семисегментного индикатора: cmod_a7_35_no_tm1638
cmod_a7_35_no_pll_vga_304_no_tm1638
cmod_a7_35_no_pll_vga_320_no_tm1638
```

**00:43, 17 ноября**:

```text
Add to all your cmod_a7 configurations suffix _claude. Update all the relevant files.
```

```text
Добавь ко всем своим конфигурациям cmod_a7 суффикс _claude. Обнови все связанные файлы.
```
