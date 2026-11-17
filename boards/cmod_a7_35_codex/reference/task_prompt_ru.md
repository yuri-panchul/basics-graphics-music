# Задание

Создайте новую ветку basics_graphics_music с именем claude_cmod_a7, начиная с main.
Ветка должна называться claude_cmod_a7, если вы Claude, и codex_cmod_a7, если вы Codex.

Изучите реализации плат:

* alinx_ax7035b
* arty_a7_100
* arty_a7_100_pmod_mic3
* arty_a7_35
* arty_a7_35_pmod_mic3
* basys3
* nexys4
* nexys4_ddr
* nexys_a7
* nexys_a7_100
* nexys_a7_50
* zybo_z7
* zzz_postponed_and_retired/cmod_a7

В частности, файлы:

* board_specific.tcl
* board_specific_top.sv
* board_specific.xdc

Создайте новую реализацию платы cmod_a7_35 для Digilent Cmod A7-35T.

Существующая реализация zzz_postponed_and_retired/cmod_a7 неправильная.

Скопируйте следующий файл в boards/cmod_a7_35/board_specific.xdc:

https://github.com/Digilent/digilent-xdc/blob/master/Cmod-A7-Master.xdc

Раскомментируйте только необходимые выводы. Не изменяйте имена или определения выводов — только раскомментируйте существующие строки.

Все сопоставления имён должны находиться в board_specific_top.sv.

Используйте разъём Pmod для подключения TinyVGA.

При необходимости напишите собственный модуль интерфейса VGA, если basics-graphics-music/peripherals/vga.sv не подходит.

Либо предложите изменение basics-graphics-music/peripherals/vga.sv с учётом тактовой частоты.

Обновите соответствующие Bash-скрипты в scripts/steps.

Создайте файлы .md и HTML с инструкцией по сборке на макетной плате схемы с этой платой, микрофоном и одним из следующих модулей ЦАП:

* WeAct I2S Earphone Module PCM5100A Stereo HP AMP 32Ω 160mW DAC Decoder Audio Board

* Interface I2S PCM5102A DAC Decoder GY-PCM5102 I2S Player Module For Raspberry Pi PHAT Format Board Digital PCM5102 Audio Board

Планируя использование выводов для TM1638, микрофона и звукового ЦАП, сделайте соединения компактными и удобными для сборки.

Добавьте этот запрос в качестве приложения к файлам .md и HTML.

Кроме английской инструкции создайте русскую инструкцию (также .md и .html). В приложении с запросом приведите и английский оригинал, и его перевод на русский язык.
