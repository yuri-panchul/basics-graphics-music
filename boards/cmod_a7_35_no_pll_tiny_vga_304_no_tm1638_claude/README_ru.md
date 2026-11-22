*Создано Claude Opus 5.5 (`claude-opus-5-5`) в Claude Code 2.1.325, уровень усилий xhigh, по промпту Юрия Панчула. Дословные промпты — в [приложении cmod_a7_35_tiny_vga_640_claude](../cmod_a7_35_tiny_vga_640_claude/README_ru.md#приложение-промпты).*

# Cmod A7-35T без TM1638 и без MMCM: TinyVGA 304x480

Конфигурация платы `cmod_a7_35_no_pll_tiny_vga_304_no_tm1638_claude`. English version: [README.md](README.md).

Это cmod_a7_35_no_pll_tiny_vga_304_claude без модуля TM1638: генератор 12 МГц
без MMCM, экран 304x480 со стандартными частотами, две кнопки и два светодиода
Cmod A7 для упражнений, а семисегментного индикатора нет.

Инструкция, рисунки и соединения — у основной конфигурации,
[cmod_a7_35_tiny_vga_640_claude](../cmod_a7_35_tiny_vga_640_claude/README_ru.md);
чем отличается эта, описано в её разделах [Без
MMCM](../cmod_a7_35_tiny_vga_640_claude/README_ru.md#без-mmcm-320x480-и-304x480)
и [Без TM1638](../cmod_a7_35_tiny_vga_640_claude/README_ru.md#без-tm1638).
Чтобы собрать упражнения, выберите
`cmod_a7_35_no_pll_tiny_vga_304_no_tm1638_claude` в
`./06_choose_another_fpga_board.bash` и соберите, как там описано.

| Файл | Что это |
|------|---------|
| [board_specific_top.sv](board_specific_top.sv) | Определяет `CMOD_A7_NO_PLL_SCREEN_WIDTH` равным 304 и `FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE` и включает модуль верхнего уровня из cmod_a7_35_tiny_vga_640_claude |
| [board_specific.xdc](board_specific.xdc) | Тот же, что в cmod_a7_35_tiny_vga_640_claude |
| [board_specific.tcl](board_specific.tcl) | Микросхема ПЛИС для Vivado |
