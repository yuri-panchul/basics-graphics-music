*Создано Claude Opus 5.5 (`claude-opus-5-5`) в Claude Code 2.1.325, уровень усилий xhigh, по промпту Юрия Панчула. Дословные промпты — в [приложении cmod_a7_35_tiny_vga_640_claude](../cmod_a7_35_tiny_vga_640_claude/README_ru.md#приложение-промпты).*

# Cmod A7-35T без MMCM: TinyVGA 320x480 от генератора 12 МГц

Конфигурация платы `cmod_a7_35_no_pll_tiny_vga_320_claude`. English version: [README.md](README.md).

Это cmod_a7_35_tiny_vga_640_claude без MMCM, от кварцевого генератора Cmod A7
на 12 МГц: упражнения рисуют на экране 320x480, каждый пиксель шириной в два
пикселя из 640, с частотой строк 30 кГц, которую некоторые мониторы не
принимают.

Инструкция, рисунки и соединения — у основной конфигурации,
[cmod_a7_35_tiny_vga_640_claude](../cmod_a7_35_tiny_vga_640_claude/README_ru.md);
чем отличается эта, описано в её разделе [Без
MMCM](../cmod_a7_35_tiny_vga_640_claude/README_ru.md#без-mmcm-320x480-и-304x480).
Чтобы собрать упражнения, выберите `cmod_a7_35_no_pll_tiny_vga_320_claude` в
`./06_choose_another_fpga_board.bash` и соберите, как там описано.

| Файл | Что это |
|------|---------|
| [board_specific_top.sv](board_specific_top.sv) | Определяет `CMOD_A7_NO_PLL_SCREEN_WIDTH` равным 320 и включает модуль верхнего уровня из cmod_a7_35_tiny_vga_640_claude, который тогда работает целиком на 12 МГц с этой синхронизацией VGA |
| [board_specific.xdc](board_specific.xdc) | Тот же, что в cmod_a7_35_tiny_vga_640_claude |
| [board_specific.tcl](board_specific.tcl) | Микросхема ПЛИС для Vivado |
