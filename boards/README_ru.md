# Платы ПЛИС в basics-graphics-music

54 плат, по одной строке на каждую. Диапазоны версий Quartus **измерены**: у каждой установленной версии спрашивали, может ли она собрать проект под конкретную микросхему платы. Диапазон, отмеченный крестиком, выходит за пределы доступных здесь версий, то есть одна из его границ не измерена.

Проверялись версии: 13.0sp1, 13.1 и 25.1std в домашнем каталоге, 21.1 в /opt и 26.1.1 Pro. Для Vivado, Gowin EDA и потока на Yosys репозиторий не указывает никаких требований к версии, поэтому такие строки опираются на знания автора таблицы.

| Изготовитель ПЛИС | Изготовитель платы | Плата | Семейство ПЛИС | Инструментарий и подходящие версии | TM1638 | Подключённая графика |
| --- | --- | --- | --- | --- | --- | --- |
| Altera | ALINX | alinx_ax301 | Cyclone IV E | Quartus с 13.0sp1 по 25.1std | нет | VGA |
| Altera | ALINX | alinx_ax4010 | Cyclone IV E | Quartus с 13.0sp1 по 25.1std | нет | VGA |
| Altera | Altera | dk_dev_3c120n | Cyclone III | Quartus 13.1 и старше | нет | нет |
| Altera | Марсоход | marsohod_mcy112 | Cyclone (первый) | Quartus 9.1 SP2; начиная с 13.0sp1 нужна лицензия † | нет | нет |
| Altera | Марсоход | marsohod_mcy316 | Cyclone III | Quartus 13.1 и старше | нет | нет |
| Altera | OMDAZZ | omdazz | Cyclone IV E | Quartus с 13.0sp1 по 25.1std | нет | VGA + LCD |
| Altera | OMDAZZ | omdazz_epm570 | MAX II | Quartus с 13.0sp1 по 25.1std | нет | VGA + LCD |
| Altera | Piswords | piswords6 | Cyclone IV E | Quartus с 13.0sp1 по 25.1std | нет | VGA |
| Altera | Terasic | c5gx | Cyclone V | Quartus с 13.0sp1 по 25.1std | нет | HDMI/DVI |
| Altera | Terasic | de0 | Cyclone III | Quartus 13.1 и старше | нет | VGA |
| Altera | Terasic | de0_cv | Cyclone V | Quartus с 13.0sp1 по 25.1std | нет | VGA |
| Altera | Terasic | de0_nano | Cyclone IV E | Quartus с 13.0sp1 по 25.1std | всегда | VGA |
| Altera | Terasic | de0_nano_soc | Cyclone V | Quartus с 13.0sp1 по 25.1std | всегда | VGA |
| Altera | Terasic | de1 | Cyclone II | Quartus 13.0sp1 и старше | нет | VGA |
| Altera | Terasic | de10_lite | MAX 10 | Quartus 14.0.2 и новее † | на выбор | VGA |
| Altera | Terasic | de10_nano | Cyclone V | Quartus с 13.0sp1 по 25.1std | всегда | HDMI/DVI |
| Altera | Terasic | de1_soc | Cyclone V | Quartus с 13.0sp1 по 25.1std | нет | VGA |
| Altera | Terasic | de2 | Cyclone II | Quartus 13.0sp1 и старше | нет | VGA |
| Altera | Terasic | de23_lite | Agilex 3 | Quartus Pro 26.1.1 | нет | HDMI/DVI |
| Altera | Terasic | de2_115 | Cyclone IV E | Quartus с 13.0sp1 по 25.1std | нет | VGA |
| Altera | Terasic | terasic_sockit | Cyclone V | Quartus с 13.0sp1 по 25.1std | нет | VGA |
| Altera | ZEOWAA | zeowaa | Cyclone IV E | Quartus с 13.0sp1 по 25.1std | нет | VGA |
| Altera | неизвестно | emooc_cc | Cyclone IV E | Quartus с 13.0sp1 по 25.1std | нет | нет |
| Altera | неизвестно | rzrd | Cyclone IV E | Quartus с 13.0sp1 по 25.1std | нет | VGA + LCD |
| Altera | неизвестно | saylinx | Cyclone IV E | Quartus с 13.0sp1 по 25.1std | нет | VGA |
| Gowin | Марсоход | marsohod3gw2 | GW1NR-9 | Gowin EDA, любая версия † | нет | HDMI/DVI |
| Gowin | Sipeed | tang_mega_138k | GW5AST | Gowin EDA, 1.9.9 и новее † | всегда | HDMI/DVI + LCD |
| Gowin | Sipeed | tang_mega_138k_pro | GW5AST-138 | Gowin EDA, любая версия † | всегда | HDMI/DVI + LCD |
| Gowin | Sipeed | tang_nano_20k | GW2AR-18 | Gowin EDA, любая версия † | всегда | HDMI/DVI + LCD |
| Gowin | Sipeed | tang_nano_4k | GW1NSR-4 | Gowin EDA, любая версия † | всегда | HDMI/DVI |
| Gowin | Sipeed | tang_nano_9k | GW1NR-9 | Gowin EDA, любая версия; Yosys/OSS † | всегда | HDMI/DVI + LCD |
| Gowin | Sipeed | tang_primer_20k_dock | GW2A-18C | Gowin EDA, любая версия; Yosys/OSS † | всегда | HDMI/DVI + LCD |
| Gowin | Sipeed | tang_primer_20k_lite | GW2A-18 | Gowin EDA, любая версия † | всегда | нет |
| Gowin | Sipeed | tang_primer_25k | GW5A | Gowin EDA, 1.9.9 и новее † | всегда | HDMI/DVI + VGA |
| Gowin | Xunlong | orangepi_msoc | GW5AT-138B | Gowin EDA, любая версия † | всегда | нет |
| Lattice | 1BitSquared | icebreaker | iCE40 | инструментарий не назначен; Yosys/OSS † | на выбор | HDMI/DVI |
| Lattice | Colorlight | colorlight75b | ECP5 | Yosys/OSS † | всегда | нет |
| Lattice | Colorlight | colorlightI5 | ECP5 | Yosys/OSS † | всегда | нет |
| Lattice | Fabmicro | karnix | ECP5 | Yosys/OSS † | всегда | нет |
| Lattice | Greg Davill | orangecrab | ECP5 | Yosys/OSS † | всегда | нет |
| Lattice | Olimex | ice40hx8k_evb | iCE40 | Yosys/OSS † | всегда | VGA |
| Xilinx | ALINX | alinx_ax7035b | Artix-7 | Vivado, любая версия † | нет | нет |
| Xilinx | Digilent | arty_a7_100 | Artix-7 | Vivado, любая версия † | нет | нет |
| Xilinx | Digilent | arty_a7_35 | Artix-7 | Vivado, любая версия † | нет | нет |
| Xilinx | Digilent | basys3 | Artix-7 | Vivado, любая версия † | нет | VGA |
| Xilinx | Digilent | cmod_s7 | Spartan-7 | Vivado, любая версия † | нет | нет |
| Xilinx | Digilent | eclypse_z7 | Zynq-7000 | Vivado, любая версия † | всегда | нет |
| Xilinx | Digilent | nexys4 | Artix-7 | Vivado, любая версия † | нет | VGA |
| Xilinx | Digilent | nexys4_ddr | Artix-7 | Vivado, любая версия † | нет | нет |
| Xilinx | Digilent | nexys_a7_100 | Artix-7 | Vivado, любая версия † | нет | нет |
| Xilinx | Digilent | nexys_a7_50 | Artix-7 | Vivado, любая версия † | нет | нет |
| Xilinx | Digilent | zybo_z7 | Zynq-7000 | Vivado, любая версия † | нет | нет |
| Xilinx | QMTech | qmtech_kintex_7 | Kintex-7 | Vivado, любая версия † | нет | нет |
| Xilinx | неизвестно | a7_lite_35t | Artix-7 | Vivado, любая версия † | всегда | HDMI/DVI |

† Одна из границ этого диапазона здесь не измерена.

## Откуда взялся каждый диапазон

* **Agilex 3** — строит только редакция Pro; более старой Pro здесь не установлено
* **Cyclone** — все установленные версии отказываются с ошибкой 20005 — требуется лицензия; файл проекта самой платы написан редакцией 9.1 SP2 Web
* **Cyclone II** — 13.0sp1 строит, 13.1 уже нет
* **Cyclone III** — 13.1 строит, 21.1 уже нет
* **Cyclone IV E** — строят все четыре бесплатные редакции
* **Cyclone V** — строят все четыре бесплатные редакции
* **MAX 10** — 21.1 и 25.1std строят, 13.x — нет; граница 14.0.2 здесь не измерена
* **MAX II** — строят все четыре бесплатные редакции

Диапазон полностью измерен для 23 плат из 54.
