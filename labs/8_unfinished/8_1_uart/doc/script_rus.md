# Описания командных файлов

## 01_clean.bash

Очищает каталог run

## 02_simulate_rtl.bash

Вызывается файл steps/02_simulate_rtl.source_bash.
При установленном симуляторе questa - вызывается questa, иначе - icarus verilog и GTKWave

## 03_synthesize_for_fpga.bash

Вызывается сборка проекта для выбранной отладочной платы и загрузка прошивки на плату

## 04_configure_fpga.bash

Вызывается загрузка прошивки на плату.

## 05_run_gui_for_fpga_synthesis.bash

Вызывается система проектирования.
## 06_choose_another_fpga_board.bash

Выбор отладочной платы.

## 07_synthesize_for_asic.bash

Сборка проекта в системе OpenLine

## 08_visualize_asic_synthesis_results_1.bash

Отображение результатов сборки.

## 09_visualize_asic_synthesis_results_2.bash

Отображение результатов сборки.

## 10_simulate_rtl_icarus.bash

Вызывается система моделирования icarus verilog без вызова GTKWave.

## 11_simulate_rtl_gtkwave.bash

Вызывается GTKWave и командый файл gtkwave.tcl

В файле gtkwave.tcl указаны сигналы для отображения на временной диаграмме.

## 12_prepare_step_1.bash

Копируются файлы из каталога support/step_1 в текущий каталог проекта.

Файлы в каталоге support/ находятся под системой контроля версий.
Файлы *.sv в текущем каталоге проекта не находятся под системой контроля версий.

