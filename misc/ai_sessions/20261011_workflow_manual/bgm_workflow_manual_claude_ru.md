[![Первое занятие Школы синтеза цифровых схем, 2023 год.](https://www.panchul.com/bgm_workflow_manual/20261011/image_at_the_beginning_synthesis_school_first_lesson_2023.jpg)](https://www.panchul.com/bgm_workflow_manual/20261011/image_at_the_beginning_synthesis_school_first_lesson_2023.jpg)

# Поддержка разработки студентами своих вариантов упражнений BGM в рамках Школы Синтеза Цифровых Схем

**Использование Git, GitHub, VSCode с терминалами и маршрутов синтеза для ПЛИС.**

**Покрывает маршруты: Xilinx Vivado, Altera Quartus, Gowin EDA и OSS CAD Suite.**

**Покрывает платформы: Windows 10 и 11, Linux и ARM macOS.**

Версия от 11 октября 2026 года.

<a id="toc"></a>

## Содержание

- [0. Введение](#s0)
- [1. Создание учётной записи на GitHub](#s1)
- [2. Форк репозитория Школы синтеза](#s2)
- [3. Установка Git под Windows, Linux и macOS](#s3)
- [4. Клонирование своего форка](#s4)
- [5. Открытие репозитория в VSCode](#s5)
- [6. Терминал в VSCode, особенно под Windows: выбор типа терминала и переход в каталог упражнения](#s6)
- [7. Выбор платы](#s7)
- [8. Синтез для платы Saylinx с ПЛИС Altera](#s8)
- [9. Изменение примера](#s9)
- [10. Отправка изменений в свой форк](#s10)
- [11. Хранение учётных данных Git под Linux](#s11)
- [12. Pull request в исходный репозиторий](#s12)
- [13. Синхронизация своего форка с исходным репозиторием](#s13)
- [14. Схема после элаборации в Quartus](#s14)
- [15. Синтез для ALINX AX7035B с ПЛИС Xilinx](#s15)
- [16. Просмотр схем в Xilinx Vivado](#s16)
- [17. Просмотр размещённого проекта в Xilinx Vivado](#s17)
- [18. Синтез для Tang Nano 9K с LCD на ПЛИС Gowin](#s18)
- [19. Схема и отчёты в Gowin EDA](#s19)
- [20. Клонирование форка на Apple Mac с процессором ARM](#s20)
- [21. Открытие репозитория в VSCode на Apple Mac с процессором ARM](#s21)
- [22. Синтез для Tang Nano 9K с HDMI в Gowin EDA под macOS](#s22)
- [23. Синтез для Tang Nano 9K в OSS CAD Suite](#s23)
- [24. Синтез для iCEBreaker с ПЛИС Lattice в OSS CAD Suite](#s24)
- [25. Просмотр размещённого проекта в nextpnr](#s25)
- [Приложение А. Минималистичная шпаргалка по Git](#sa)
- [Приложение Б. Как скрипты BGM находят САПР ПЛИС](#sb)

<a id="s0"></a>

## 0. Введение

Мы решили написать эту инструкцию после того, как преподаватель МЭИ Михаил Графов высказал пожелание, чтобы студенты могли редактировать дома код своих вариантов упражнений из репозитория BGM (Basic-Graphics-Music) и чтобы их редактирование не сбрасывалось при обновлении репозитория. Кроме этого, для развития Школы было бы полезно, чтобы некоторые из разработанных студентами примеров можно было вносить в исходный репозиторий, с минимизацией риска, что эти изменения поломают код для других студентов.

Собственно именно для всего этого были созданы системы управления версиями и их хостинги: GitHub, GitLab, GitVerse, GitFlic и другие. Репозиторий BGM использует GitHub, в котором есть такие удобные инструменты как fork и pull request, но не все студенты их знают.

Кроме этого, мы решили показать использование маршрутов синтеза внутри терминалов VSCode, с удобными шорткатами, например использованием табуляции для автодополнения. А также небольшие различия в использовании платформ. Например под Linux и macOS можно открыть терминал правой кнопкой мыши (bash под Linux и zsh под macOS) прямо в нужной директории примера, а в Windows мы рекомендуем создать Git Bash терминал, после чего набрать команду `cd ` и перетянуть туда директорию примера из проводника VSCode мышью.

Альтернатива такого drag-and-drop в Windows — это открыть Windows PowerShell правой кнопкой мыши, после чего использовать не `./название_скрипта`, а `bash ./название_скрипта`, но если на компьютере установлен WSL (Windows Subsystem for Linux), это может не работать, выдавать ошибки про Windows CR-LF в коде скриптов.

Мы также решили проиллюстрировать, как увидеть синтезированные из кода схемы в маршрутах синтеза от различных производителей, которые поддерживает инфраструктура BGM.

Эта инструкция не содержит информации, как устанавливать маршруты синтеза, ее вы можете найти в другом мануале, [Инструкции по установке ПО](https://panchul.com/bgm_svh_manual/20261006_draft/claude/manual_ru.html). В Инструкции по установке ПО также есть сведения, как установить программы терминалов для связи с платой ПЛИС через UART (не путать с терминалами в VSCode), архитектурного симулятора RARS, а также пакета XPACK, варианта пакетов GCC и LLVM для компиляции программ для архитектуры RISC-V.

При этом мы решили поместить в приложение к этой инструкции информацию о том, как скрипты BGM находят установки пакетов САПР ПЛИС: Xilinx Vivado, Altera Quartus, Gowin EDA и OSS CAD Suite.

[![Рис. 0.1. Занятие Школы синтеза в кластере Московского Энергетического Института.](https://www.panchul.com/bgm_workflow_manual/20261011/00_introduction/00_01.jpg)](https://www.panchul.com/bgm_workflow_manual/20261011/00_introduction/00_01.jpg)

*Рис. 0.1. Занятие Школы синтеза в кластере Московского Энергетического Института.*

<a id="s0_1"></a>

### Как устроена эта инструкция

Главы идут в том порядке, в котором студент проходит весь путь: от регистрации на GitHub до pull request в репозиторий Школы. В середине инструкции тот же цикл «выбрать плату — синтезировать — посмотреть схему» повторяется для каждой САПР.

| Главы | Что делаем | Платформа на снимках |
|---|---|---|
| 1–2 | Учётная запись GitHub и форк репозитория | браузер |
| 3–7 | Git, клонирование, VSCode, терминал, выбор платы | Windows, местами Linux |
| 8–9 | Синтез в Quartus для платы Saylinx, изменение примера | Windows |
| 10–13 | Коммит, push, pull request, синхронизация форка | Windows |
| 14 | Схема в Quartus RTL Viewer | Windows |
| 15–17 | Vivado: синтез для ALINX AX7035B, схемы, размещённый проект | Windows, Linux |
| 18–19 | Gowin EDA: Tang Nano 9K с LCD, схема и отчёты | Windows, Linux |
| 20–22 | Клонирование, VSCode и Gowin EDA на Mac с процессором Apple | macOS |
| 23–25 | OSS CAD Suite: Tang Nano 9K, iCEBreaker, nextpnr | macOS |
| Прил. А | Шпаргалка по Git | — |
| Прил. Б | Как скрипты BGM находят САПР ПЛИС | — |

На снимках используется учебная учётная запись **Dmitri-Mendeleev**. Везде, где в командах и адресах встречается это имя, подставляйте имя своей учётной записи GitHub.

Каждое упражнение BGM — это каталог в `labs` с одинаковым набором скриптов. Все скрипты запускаются из каталога упражнения:

| Скрипт | Что делает |
|---|---|
| `01_clean.bash` | удаляет результаты предыдущих запусков (каталог `run` и `log.txt`) |
| `02_simulate_rtl.bash` | моделирует упражнение (Icarus Verilog) и показывает временные диаграммы |
| `03_synthesize_for_fpga.bash` | синтезирует проект для выбранной платы и в конце сам вызывает `04`, чтобы загрузить его в ПЛИС |
| `04_configure_fpga.bash` | загружает уже синтезированный проект в ПЛИС |
| `05_run_gui_for_fpga_synthesis.bash` | открывает проект в графической оболочке САПР |
| `06_choose_another_fpga_board.bash` | выбирает другую плату |
| `07_synthesize_for_asic.bash` – `09_…` | синтез в заказную микросхему (в этой инструкции не рассматривается) |

<a id="s1"></a>

## 1. Создание учётной записи на GitHub

Откройте [github.com](https://github.com), введите адрес электронной почты и нажмите **Sign up for GitHub**.

[![Рис. 1.1. Главная страница GitHub.](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_01.png)

*Рис. 1.1. Главная страница GitHub.*

Заполните форму: адрес почты, пароль и имя пользователя (username). Пароль должен содержать не меньше 15 символов или не меньше 8 символов, среди которых есть цифра и строчная буква. Имя пользователя войдёт в адрес вашего форка, поэтому выберите короткое и понятное. Нажмите **Create account**.

[![Рис. 1.2. Форма регистрации.](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_02.png)

*Рис. 1.2. Форма регистрации.*

GitHub пришлёт на почту код из 8 цифр. Введите его и нажмите **Continue**.

[![Рис. 1.3. Подтверждение адреса почты.](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_03.png)

*Рис. 1.3. Подтверждение адреса почты.*

После подтверждения войдите в созданную учётную запись.

[![Рис. 1.4. Учётная запись создана, осталось войти.](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_04.png)

*Рис. 1.4. Учётная запись создана, осталось войти.*

[![Рис. 1.5. Страница нового пользователя: репозиториев пока нет.](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_05.png)

*Рис. 1.5. Страница нового пользователя: репозиториев пока нет.*

<a id="s2"></a>

## 2. Форк репозитория Школы синтеза

**Форк** (fork) — это ваша собственная копия чужого репозитория на GitHub. В неё можно отправлять свои изменения, не имея прав на исходный репозиторий, а исходный репозиторий при этом не меняется. Обновления исходного репозитория потом можно забирать в свой форк (глава 13), а свои изменения — предлагать авторам через pull request (глава 12).

Найдите организацию Школы синтеза на GitHub, например поиском «школа синтеза цифровых схем github». Её адрес — [github.com/chipdesignschool](https://github.com/chipdesignschool).

[![Рис. 2.1. Поиск организации Школы синтеза.](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_01.png)

*Рис. 2.1. Поиск организации Школы синтеза.*

Среди закреплённых репозиториев есть **basics-graphics-music**. Обратите внимание на подпись: он сам является форком репозитория `yuri-panchul/basics-graphics-music`. Студенты Школы делают форк именно `chipdesignschool/basics-graphics-music`.

[![Рис. 2.2. Организация chipdesignschool.](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_02.png)

*Рис. 2.2. Организация chipdesignschool.*

Откройте репозиторий и нажмите кнопку **Fork**.

[![Рис. 2.3. Кнопка Fork на странице репозитория.](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_03.png)

*Рис. 2.3. Кнопка Fork на странице репозитория.*

В окне **Create a new fork** владельцем (Owner) будет ваша учётная запись. Имя репозитория оставьте прежним, флажок **Copy the main branch only** оставьте включённым и нажмите **Create fork**.

[![Рис. 2.4. Создание форка.](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_04.png)

*Рис. 2.4. Создание форка.*

Через несколько секунд откроется ваш форк: `github.com/<ваше_имя>/basics-graphics-music`. Под названием написано, от какого репозитория он создан, а строка *This branch is up to date with …* показывает, что форк совпадает с исходным репозиторием. Здесь же находятся кнопки **Contribute** (глава 12) и **Sync fork** (глава 13).

[![Рис. 2.5. Только что созданный форк.](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_05.png)

*Рис. 2.5. Только что созданный форк.*

Чтобы скачать форк на компьютер, нужен его адрес. Нажмите зелёную кнопку **Code**, на вкладке **Local** выберите **HTTPS** и скопируйте адрес кнопкой справа от него. Для учебной учётной записи это `https://github.com/Dmitri-Mendeleev/basics-graphics-music.git`.

[![Рис. 2.6. Адрес форка для клонирования.](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_06.png)

*Рис. 2.6. Адрес форка для клонирования.*

<a id="s3"></a>

## 3. Установка Git под Windows, Linux и macOS

Подробная установка Git описана в [Инструкции по установке ПО](https://panchul.com/bgm_svh_manual/20261006_draft/claude/manual_ru.html#s4_1_8). Здесь — коротко для каждой платформы.

<a id="s3_1"></a>

### Windows

Найдите в поисковике «git for windows» и откройте страницу загрузки на [git-scm.com](https://git-scm.com/install/windows). Скачайте 64-битный установщик (**Git for Windows/x64 Setup**; для компьютеров с процессором ARM есть ARM64 Setup).

[![Рис. 3.1. Поиск Git для Windows.](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_01.png)

*Рис. 3.1. Поиск Git для Windows.*

[![Рис. 3.2. Страница загрузки Git для Windows.](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_02.png)

*Рис. 3.2. Страница загрузки Git для Windows.*

В установщике можно оставить все варианты по умолчанию — так рекомендует Инструкция по установке ПО. На снимке на странице *Adjusting your PATH environment* выбран третий вариант, *Use Git and optional Unix tools from the Command Prompt*: он делает Unix-утилиты доступными также из `cmd` и PowerShell, но подменяет стандартные команды Windows `find` и `sort`. Скрипты BGM работают при любом из этих вариантов, потому что запускаются из Git Bash.

[![Рис. 3.3. Страница установщика Adjusting your PATH environment.](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_03.png)

*Рис. 3.3. Страница установщика Adjusting your PATH environment.*

Вместе с Git устанавливается **Git Bash** — оболочка bash, в которой под Windows запускаются все скрипты BGM.

<a id="s3_2"></a>

### Linux

В Debian, Ubuntu и производных:

```bash
sudo apt-get install git
```

[![Рис. 3.4. Установка Git в Linux.](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_04.png)

*Рис. 3.4. Установка Git в Linux.*

В Fedora, RED OS и подобных используйте `sudo dnf install git`.

<a id="s3_3"></a>

### macOS

Удобнее всего установить Git через менеджер пакетов [Homebrew](https://brew.sh/ru/). Если Homebrew ещё не установлен, выполните в программе Terminal команду с его сайта:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

[![Рис. 3.5. Установка Homebrew.](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_05.png)

*Рис. 3.5. Установка Homebrew.*

Затем установите Git:

```bash
brew install git
```

[![Рис. 3.6. Установка Git через Homebrew.](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_06.png)

*Рис. 3.6. Установка Git через Homebrew.*

Ещё один вариант: при первом вызове команды `git` macOS сама предлагает установить Command Line Tools for Xcode, в составе которых есть Git.

<a id="s4"></a>

## 4. Клонирование своего форка

**Клонировать** — значит скачать репозиторий на компьютер вместе со всей историей изменений. Клонируйте **свой форк**, а не исходный репозиторий: тогда вы сможете отправлять в него свои изменения.

Откройте терминал (под Windows — Git Bash), перейдите в каталог, где будут лежать проекты, и выполните `git clone` с адресом, скопированным в главе 2:

```bash
git clone https://github.com/Dmitri-Mendeleev/basics-graphics-music.git
```

[![Рис. 4.1. Команда клонирования.](https://www.panchul.com/bgm_workflow_manual/20261011/04_cloning_your_forked_repo/04_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/04_cloning_your_forked_repo/04_01.png)

*Рис. 4.1. Команда клонирования.*

Git создаст каталог `basics-graphics-music` и скачает в него около 83 МБ.

[![Рис. 4.2. Клонирование завершено.](https://www.panchul.com/bgm_workflow_manual/20261011/04_cloning_your_forked_repo/04_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/04_cloning_your_forked_repo/04_02.png)

*Рис. 4.2. Клонирование завершено.*

> **Важно.** Путь к каталогу репозитория не должен содержать пробелов и русских букв. На снимках под Windows репозиторий лежит в `C:\projects\basics-graphics-music`. Quartus и некоторые другие САПР не работают с путями, в которых есть пробелы или нелатинские символы.

<a id="s5"></a>

## 5. Открытие репозитория в VSCode

Запустите VSCode. На странице **Welcome** есть пункт **Open Folder…**; то же самое делает меню **File → Open Folder…** (`Ctrl+K Ctrl+O`).

[![Рис. 5.1. Страница Welcome в VSCode.](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_01.png)

*Рис. 5.1. Страница Welcome в VSCode.*

[![Рис. 5.2. Меню File → Open Folder…](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_02.png)

*Рис. 5.2. Меню File → Open Folder…*

Выберите каталог `basics-graphics-music` и нажмите **Open**. Если VSCode спросит, доверяете ли вы авторам файлов в этом каталоге, ответьте утвердительно, иначе часть возможностей редактора будет отключена.

[![Рис. 5.3. Выбор каталога репозитория (Linux).](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_03.png)

*Рис. 5.3. Выбор каталога репозитория (Linux).*

Слева, в панели **Explorer**, появится дерево репозитория. Внизу, в строке состояния, VSCode показывает текущую ветку Git — `main`.

[![Рис. 5.4. Репозиторий открыт.](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_04.png)

*Рис. 5.4. Репозиторий открыт.*

Упражнения лежат в каталоге `labs`. Например, первое графическое упражнение — `labs/2_graphics/2_1_rectangle_ellipse_parabola`. Щёлкните по файлу `lab_top.sv`, чтобы открыть его в редакторе.

[![Рис. 5.5. Каталог упражнения и файл lab_top.sv.](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_05.png)

*Рис. 5.5. Каталог упражнения и файл lab_top.sv.*

Для работы с SystemVerilog полезно установить два расширения. Откройте **View → Extensions** (`Ctrl+Shift+X`), найдите и установите:

- **SystemVerilog - Language Support** (автор Eirik Prestegårdshus) — подсветка синтаксиса и переход к определениям;
- **surfer** — просмотрщик временных диаграмм прямо в VSCode.

[![Рис. 5.6. Меню View → Extensions.](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_06.png)

*Рис. 5.6. Меню View → Extensions.*

[![Рис. 5.7. Установленные расширения surfer и SystemVerilog - Language Support.](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_07.png)](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_07.png)

*Рис. 5.7. Установленные расширения surfer и SystemVerilog - Language Support.*

Терминал внутри VSCode открывается через **Terminal → New Terminal** (Ctrl+Shift и клавиша с обратным апострофом слева от 1, на русской раскладке это Ё). О том, какой терминал выбрать, — следующая глава.

[![Рис. 5.8. Меню Terminal → New Terminal.](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_08.png)](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_08.png)

*Рис. 5.8. Меню Terminal → New Terminal.*

<a id="s6"></a>

## 6. Терминал в VSCode, особенно под Windows: выбор типа терминала и переход в каталог упражнения

Скрипты BGM написаны на bash. Под Linux терминал VSCode по умолчанию и так bash, под macOS — zsh, который запускает скрипты bash без дополнительных действий. Под Windows по умолчанию открывается PowerShell, поэтому сначала нужно открыть терминал **Git Bash**.

<a id="s6_1"></a>

### Открываем Git Bash под Windows

Откройте новый терминал: **Terminal → New Terminal**. Если меню скрыто за кнопкой `...`, оно находится там.

[![Рис. 6.1. Новый терминал в VSCode под Windows.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_01.png)

*Рис. 6.1. Новый терминал в VSCode под Windows.*

Открылся PowerShell: приглашение начинается с `PS`.

[![Рис. 6.2. Терминал PowerShell.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_02.png)

*Рис. 6.2. Терминал PowerShell.*

Нажмите на стрелку рядом с кнопкой **+** в панели терминала и выберите **Git Bash**.

[![Рис. 6.3. Выбор Git Bash в списке терминалов.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_03.png)

*Рис. 6.3. Выбор Git Bash в списке терминалов.*

Приглашение Git Bash выглядит иначе: в нём есть имя компьютера, слово `MINGW64`, текущий каталог в формате Unix (`/c/projects/…` вместо `C:\projects\…`) и текущая ветка Git в скобках.

<a id="s6_2"></a>

### Переходим в каталог упражнения перетаскиванием

Наберите `cd` и пробел, но не нажимайте Enter.

[![Рис. 6.4. Набрана команда cd с пробелом.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_04.png)

*Рис. 6.4. Набрана команда cd с пробелом.*

Перетащите мышью каталог упражнения из панели Explorer в окно терминала.

[![Рис. 6.5. Перетаскивание каталога в терминал.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_05.png)

*Рис. 6.5. Перетаскивание каталога в терминал.*

[![Рис. 6.6. Подсказка с полным путём к каталогу.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_06.png)

*Рис. 6.6. Подсказка с полным путём к каталогу.*

[![Рис. 6.7. Каталог над окном терминала.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_07.png)](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_07.png)

*Рис. 6.7. Каталог над окном терминала.*

VSCode вставит полный путь к каталогу в кавычках.

[![Рис. 6.8. Путь вставлен в команду cd.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_08.png)](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_08.png)

*Рис. 6.8. Путь вставлен в команду cd.*

Нажмите Enter. Приглашение показывает, что вы в каталоге упражнения.

[![Рис. 6.9. Терминал в каталоге упражнения.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_09.png)](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_09.png)

*Рис. 6.9. Терминал в каталоге упражнения.*

> **Совет.** Чтобы не выбирать Git Bash каждый раз, сделайте его терминалом по умолчанию: в том же меню рядом с кнопкой **+** выберите **Select Default Profile** и затем **Git Bash**. После этого под Windows тоже работает способ, описанный ниже для Linux и macOS: щелчок правой кнопкой мыши по каталогу в Explorer и пункт **Open in Integrated Terminal** открывают Git Bash сразу в этом каталоге.

<a id="s6_3"></a>

### Linux и macOS: правая кнопка мыши

Под Linux и macOS щёлкните правой кнопкой мыши по каталогу упражнения в панели Explorer и выберите **Open in Integrated Terminal** (снимки — в главе 22). Терминал откроется сразу в этом каталоге: под Linux это bash, под macOS — zsh.

<a id="s6_4"></a>

### PowerShell и WSL

Скрипты можно запустить и из PowerShell, если писать `bash ./название_скрипта`. Но если на компьютере установлен WSL, команда `bash` в PowerShell может запустить bash из Linux внутри WSL, а не bash из Git. Тот не понимает окончания строк Windows (CR-LF), с которыми Git для Windows по умолчанию извлекает файлы, и выдаёт ошибки вроде `$'\r': command not found`. Кроме того, внутри WSL скрипты не найдут САПР, установленные в Windows. Поэтому под Windows мы рекомендуем Git Bash.

Если всё же нужен PowerShell, можно явно вызвать bash из Git (при установке Git в каталог по умолчанию):

```powershell
& "C:\Program Files\Git\bin\bash.exe" ./03_synthesize_for_fpga.bash
```

<a id="s6_5"></a>

### Полезные клавиши в терминале

- **Tab** — автодополнение. Наберите `./06` и нажмите Tab: bash допишет `./06_choose_another_fpga_board.bash`. Так не нужно помнить длинные имена скриптов.
- **Стрелка вверх** — предыдущая команда. Чтобы повторить синтез после исправления кода, достаточно нажать стрелку вверх и Enter.
- **Ctrl+C** — прервать выполняющуюся команду.
- **q** — выйти из просмотра длинного вывода, например `git diff` или `git log`.

<a id="s7"></a>

## 7. Выбор платы

Перед синтезом нужно один раз выбрать плату. Наберите в терминале `./06` и нажмите Tab.

[![Рис. 7.1. Набрано начало имени скрипта.](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_01.png)

*Рис. 7.1. Набрано начало имени скрипта.*

[![Рис. 7.2. Tab дописал имя скрипта.](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_02.png)

*Рис. 7.2. Tab дописал имя скрипта.*

Скрипт покажет нумерованный список плат. Звёздочка `*` после имени означает, что у этой платы несколько конфигураций, например с модулем TM1638 и без него или с разными дисплеями. Наберите номер платы и нажмите Enter. На снимке выбрана плата `saylinx` с ПЛИС Altera Cyclone IV E. Номера в вашем списке могут отличаться: они зависят от версии репозитория.

[![Рис. 7.3. Первый уровень меню: список плат.](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_03.png)

*Рис. 7.3. Первый уровень меню: список плат.*

Для платы со звёздочкой появится второй уровень меню — список её конфигураций. Здесь `b` возвращает к списку плат, а `e` выходит без выбора.

[![Рис. 7.4. Второй уровень меню: конфигурации платы saylinx.](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_04.png)

*Рис. 7.4. Второй уровень меню: конфигурации платы saylinx.*

Выбор сохраняется в файле `fpga_board_selection` в корне репозитория и действует для всех упражнений, пока вы не выберете другую плату. Этот файл указан в `.gitignore`, поэтому `git` его не отслеживает и в коммиты он не попадает. Сразу после выбора скрипт находит подходящую САПР и сообщает, какую версию будет использовать; для `saylinx` это Quartus Prime Lite 23.1. Как скрипты ищут САПР, описано в [приложении Б](#sb).

[![Рис. 7.5. Плата выбрана, найден Quartus.](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_05.png)

*Рис. 7.5. Плата выбрана, найден Quartus.*

<a id="s8"></a>

## 8. Синтез для платы Saylinx с ПЛИС Altera

Запустите синтез: `./03` и Tab.

[![Рис. 8.1. Набрано начало имени скрипта синтеза.](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_01.png)

*Рис. 8.1. Набрано начало имени скрипта синтеза.*

[![Рис. 8.2. Скрипт синтеза.](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_02.png)

*Рис. 8.2. Скрипт синтеза.*

Скрипт создаёт в каталоге упражнения подкаталог `run`, собирает в нём проект Quartus из файлов упражнения, общих модулей и файлов платы и запускает полную компиляцию.

[![Рис. 8.3. Начало синтеза.](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_03.png)

*Рис. 8.3. Начало синтеза.*

Компиляция занимает от нескольких десятков секунд до нескольких минут. Сотня предупреждений (warnings) — это нормально, важно, чтобы было 0 ошибок. После компиляции скрипт сам пытается загрузить проект в ПЛИС. Если плата не подключена или не найден кабель USB-Blaster, он сообщает об ошибке и просит нажать любую клавишу. Результаты синтеза при этом сохраняются.

[![Рис. 8.4. Компиляция успешна, но плата не подключена.](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_06.png)

*Рис. 8.4. Компиляция успешна, но плата не подключена.*

Подключите плату и загрузите в неё уже готовый проект скриптом `04`, без повторного синтеза: `./04` и Tab.

[![Рис. 8.5. Набрано начало имени скрипта загрузки.](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_07.png)](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_07.png)

*Рис. 8.5. Набрано начало имени скрипта загрузки.*

[![Рис. 8.6. Скрипт загрузки проекта в ПЛИС.](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_08.png)](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_08.png)

*Рис. 8.6. Скрипт загрузки проекта в ПЛИС.*

[![Рис. 8.7. Проект загружен в ПЛИС.](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_09.png)](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_09.png)

*Рис. 8.7. Проект загружен в ПЛИС.*

Плата выводит изображение на монитор через разъём VGA.

[![Рис. 8.8. Плата Saylinx и монитор с изображением упражнения 2_1.](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_05.jpg)](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_05.jpg)

*Рис. 8.8. Плата Saylinx и монитор с изображением упражнения 2_1.*

> **Примечание.** Скрипт загружает конфигурацию в ПЛИС через JTAG. Такая конфигурация хранится только до выключения питания платы; после включения проект нужно загрузить снова скриптом `04`. Так же работают загрузка в Vivado и Gowin в этой инструкции; исключение — iCEBreaker (глава 24).

<a id="s9"></a>

## 9. Изменение примера

Теперь внесём в упражнение своё изменение. Откройте `lab_top.sv` и в конце блока `always_comb`, после строк для параболы, добавьте закраску областей вокруг гиперболы `x * y = 20000`:

```systemverilog
        if (x * y < 20000)
            green = '1;
        else if (y > x)
            red = '1;
        else
            blue = '1;
```

[![Рис. 9.1. Изменённый файл lab_top.sv.](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_01.png)

*Рис. 9.1. Изменённый файл lab_top.sv.*

Пока файл не сохранён, на его вкладке вместо крестика стоит белая точка. Буква **M** (modified) означает, что файл отличается от версии в Git.

[![Рис. 9.2. Файл изменён, но не сохранён.](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_02.png)

*Рис. 9.2. Файл изменён, но не сохранён.*

Сохраните файл (`Ctrl+S`). Точка сменится крестиком, а буква **M** останется: изменение сохранено на диске, но ещё не зафиксировано в Git.

[![Рис. 9.3. Файл сохранён.](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_03.png)

*Рис. 9.3. Файл сохранён.*

Снова запустите синтез. Стрелка вверх в терминале вернёт предыдущие команды.

[![Рис. 9.4. Повторный синтез.](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_04.jpg)](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_04.jpg)

*Рис. 9.4. Повторный синтез.*

[![Рис. 9.5. Результат изменённого упражнения на мониторе.](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_05.jpg)](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_05.jpg)

*Рис. 9.5. Результат изменённого упражнения на мониторе.*

Изменение работает, и его стоит сохранить в своём форке на GitHub.

<a id="s10"></a>

## 10. Отправка изменений в свой форк

Ваш форк на GitHub пока совпадает с исходным репозиторием: изменение существует только на вашем компьютере.

[![Рис. 10.1. Профиль на GitHub, форк basics-graphics-music.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_01.png)

*Рис. 10.1. Профиль на GitHub, форк basics-graphics-music.*

Самые нужные команды Git собраны в шпаргалке `git_cheat_sheet.md` в корне репозитория. Её перевод с дополнениями — в [приложении А](#sa).

[![Рис. 10.2. Файл git_cheat_sheet.md в репозитории.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_02.png)

*Рис. 10.2. Файл git_cheat_sheet.md в репозитории.*

[![Рис. 10.3. Начало шпаргалки по Git.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_03.png)

*Рис. 10.3. Начало шпаргалки по Git.*

<a id="s10_1"></a>

### Имя и адрес почты (один раз)

Git записывает в каждый коммит имя автора и адрес его почты. Задайте их один раз на каждом компьютере:

```bash
git config --global user.name  "Dmitri-Mendeleev"
git config --global user.email "Dmitri.Mendeleev@silicon-russia.com"
```

[![Рис. 10.4. Настройка имени и почты.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_04.png)

*Рис. 10.4. Настройка имени и почты.*

Чтобы GitHub связал коммиты с вашей учётной записью и показал их в профиле, укажите тот же адрес почты, что и при регистрации, или адрес вида `<номер>+<имя>@users.noreply.github.com` из настроек GitHub (**Settings → Emails**), если не хотите показывать свой адрес.

<a id="s10_2"></a>

### Проверяем изменения

Перейдите в каталог упражнения, если вы ещё не там.

[![Рис. 10.5. Переход в каталог упражнения перетаскиванием.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_05.png)

*Рис. 10.5. Переход в каталог упражнения перетаскиванием.*

[![Рис. 10.6. Терминал в каталоге упражнения.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_06.png)

*Рис. 10.6. Терминал в каталоге упражнения.*

Команда `git status` показывает, какие файлы изменены. Каталог `run`, файл `log.txt` и выбор платы `fpga_board_selection` в списке не появляются: они перечислены в `.gitignore`.

```bash
git status
```

[![Рис. 10.7. git status: изменён один файл, lab_top.sv.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_07.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_07.png)

*Рис. 10.7. git status: изменён один файл, lab_top.sv.*

Команда `git diff` показывает сами изменения: добавленные строки отмечены `+`, удалённые — `-`. Длинный вывод листается пробелом, выход — клавиша `q`.

```bash
git diff
```

[![Рис. 10.8. git diff: добавлено семь строк.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_08.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_08.png)

*Рис. 10.8. git diff: добавлено семь строк.*

<a id="s10_3"></a>

### Фиксируем изменение: коммит

**Коммит** (commit) — сохранённый в истории Git снимок изменений с комментарием. Ключ `-a` включает в коммит все изменённые отслеживаемые файлы, `-m` задаёт комментарий. Пишите в комментарии, что и зачем изменено.

```bash
git commit -am "Added hyperbola to graphics lab"
```

[![Рис. 10.9. Команда коммита.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_09.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_09.png)

*Рис. 10.9. Команда коммита.*

[![Рис. 10.10. Коммит создан.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_10.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_10.png)

*Рис. 10.10. Коммит создан.*

> **Важно.** Ключ `-a` не добавляет **новые** файлы. Если вы создали новый файл, сначала выполните `git add имя_файла`, а потом `git commit`.

<a id="s10_4"></a>

### Отправляем коммит на GitHub: push

Команда `git push` отправляет ваши коммиты в форк на GitHub.

```bash
git push
```

При первом `git push` под Windows открывается окно **Git Credential Manager** — программы, которая входит в Git для Windows и хранит ваши учётные данные. Выберите **Sign in with your browser**.

[![Рис. 10.11. Окно Connect to GitHub.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_11.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_11.png)

*Рис. 10.11. Окно Connect to GitHub.*

В браузере войдите в свою учётную запись GitHub.

[![Рис. 10.12. Вход в GitHub для Git Credential Manager.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_12.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_12.png)

*Рис. 10.12. Вход в GitHub для Git Credential Manager.*

Разрешите Git Credential Manager доступ к учётной записи: **Authorize git-ecosystem**.

[![Рис. 10.13. Авторизация Git Credential Manager.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_13.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_13.png)

*Рис. 10.13. Авторизация Git Credential Manager.*

[![Рис. 10.14. Авторизация завершена, вкладку можно закрыть.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_14.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_14.png)

*Рис. 10.14. Авторизация завершена, вкладку можно закрыть.*

После этого `git push` завершается. Последние строки вывода показывают, куда и какой коммит отправлен: `main -> main`. Повторно вводить пароль не придётся: Git Credential Manager запомнил вход в хранилище учётных данных Windows.

[![Рис. 10.15. Вывод git push.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_15.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_15.png)

*Рис. 10.15. Вывод git push.*

> **Примечание.** Первые строки на снимке, `usage: git credential-cache` и `credential-cache is disabled in this build of Git`, появились потому, что перед этим в репозитории была выполнена команда из шпаргалки `git config credential.helper 'cache --timeout=3600'`. Под Windows этот способ не работает и не нужен, вместо него работает Git Credential Manager. Чтобы убрать сообщение, выполните в каталоге репозитория `git config --unset credential.helper` (если команду выполняли с ключом `--global`, добавьте `--global` и сюда).

<a id="s10_5"></a>

### Проверяем результат на GitHub

Обновите страницу форка. Теперь GitHub пишет *This branch is 1 commit ahead of chipdesignschool/basics-graphics-music:main*: в вашем форке есть один коммит, которого нет в исходном репозитории.

[![Рис. 10.16. Форк опережает исходный репозиторий на один коммит.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_16.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_16.png)

*Рис. 10.16. Форк опережает исходный репозиторий на один коммит.*

Ссылка *1 commit ahead* открывает сравнение форка с исходным репозиторием. С этой страницы начинается pull request (глава 12).

[![Рис. 10.17. Сравнение форка с исходным репозиторием.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_17.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_17.png)

*Рис. 10.17. Сравнение форка с исходным репозиторием.*

[![Рис. 10.18. Изменения коммита на GitHub.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_18.png)](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_18.png)

*Рис. 10.18. Изменения коммита на GitHub.*

Теперь изменение хранится на GitHub. Его можно скачать на другом компьютере командой `git clone` или `git pull`, и оно не пропадёт при обновлении репозитория Школы (глава 13).

<a id="s11"></a>

## 11. Хранение учётных данных Git под Linux

Под Linux нет окна Git Credential Manager, и при первом `git push` по адресу `https://` Git спрашивает в терминале имя пользователя (Username) и пароль (Password). Здесь есть два подвоха.

**Первый: пароль от GitHub не подходит.** С 2021 года GitHub не принимает пароль учётной записи для команд Git. Вместо пароля вводится **personal access token** (токен доступа). Создайте его так:

1. На GitHub откройте **Settings → Developer settings → Personal access tokens → Fine-grained tokens** и нажмите **Generate new token**.
2. Задайте имя токена и срок действия (Expiration).
3. В **Repository access** выберите **Only select repositories** и отметьте свой форк `basics-graphics-music`.
4. В **Permissions** для **Contents** установите **Read and write**.
5. Нажмите **Generate token** и сразу скопируйте токен: GitHub показывает его только один раз.

При `git push` введите своё имя пользователя GitHub, а в ответ на запрос пароля вставьте токен. В терминале вставка выполняется сочетанием `Ctrl+Shift+V`; вводимые символы пароля не отображаются, так и должно быть.

**Второй: Git каждый раз спрашивает снова.** Чтобы не вводить токен при каждом `git push`, включите вспомогательную программу хранения учётных данных (credential helper). Варианты:

| Команда | Где хранится токен | Замечание |
|---|---|---|
| `git config --global credential.helper 'cache --timeout=36000'` | в памяти, 36000 секунд (10 часов) | после перезагрузки или по истечении времени Git спросит снова |
| `git config --global credential.helper store` | в файле `~/.git-credentials` открытым текстом | удобно на личном компьютере, но не делайте так на общем |

Без ключа `--global` настройка действует только для текущего репозитория. Время в `--timeout` задаётся в секундах: `3600` — это один час.

Другой способ — утилита GitHub CLI: после `gh auth login` и `gh auth setup-git` Git получает учётные данные от неё, и токен создавать вручную не нужно. Под macOS Git обычно хранит токен в связке ключей (Keychain), поэтому достаточно ввести его один раз.

<a id="s12"></a>

## 12. Pull request в исходный репозиторий

**Pull request** (PR) — предложение авторам исходного репозитория забрать ваши коммиты. Авторы видят изменения, могут их обсудить, попросить доработать и принять (merge). Исходный репозиторий меняется только после того, как они примут PR, поэтому риск сломать код другим студентам сводится к минимуму.

Откройте страницу своего форка. Строка *This branch is 1 commit ahead of …* показывает, что вам есть что предложить.

[![Рис. 12.1. Форк с коммитом, которого нет в исходном репозитории.](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_01.png)

*Рис. 12.1. Форк с коммитом, которого нет в исходном репозитории.*

Щёлкните по ссылке *1 commit ahead of* (или нажмите **Contribute → Open pull request**).

[![Рис. 12.2. Ссылка на сравнение.](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_02.png)

*Рис. 12.2. Ссылка на сравнение.*

Откроется страница **Comparing changes**. Проверьте направление: слева (base repository) — `chipdesignschool/basics-graphics-music`, ветка `main`; справа (head repository) — ваш форк и ваша ветка. Надпись *Able to merge* означает, что изменения не конфликтуют с исходным репозиторием.

[![Рис. 12.3. Сравнение изменений перед pull request.](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_03.png)

*Рис. 12.3. Сравнение изменений перед pull request.*

Ниже страница показывает все изменения. Просмотрите их ещё раз: всё, что здесь видно, попадёт в pull request.

[![Рис. 12.4. Изменения, которые войдут в pull request.](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_04.png)

*Рис. 12.4. Изменения, которые войдут в pull request.*

Нажмите **Create pull request**.

[![Рис. 12.5. Кнопка Create pull request.](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_05.png)

*Рис. 12.5. Кнопка Create pull request.*

Заголовок PR GitHub берёт из комментария коммита. Добавьте описание: что изменено, зачем и как вы это проверили (например, на какой плате).

[![Рис. 12.6. Форма нового pull request.](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_06.png)

*Рис. 12.6. Форма нового pull request.*

Флажок **Allow edits by maintainers** разрешает авторам исходного репозитория самим поправить мелочи в вашем PR. Нажмите **Create pull request**.

[![Рис. 12.7. Описание pull request.](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_07.png)](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_07.png)

*Рис. 12.7. Описание pull request.*

Pull request создан, у него есть номер и статус **Open**. Дальнейшее обсуждение идёт на этой странице; уведомления о комментариях приходят на почту. Если вас попросят что-то исправить, просто сделайте новый коммит и `git push` в ту же ветку: он автоматически появится в этом PR.

[![Рис. 12.8. Открытый pull request в репозитории chipdesignschool.](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_08.png)](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_08.png)

*Рис. 12.8. Открытый pull request в репозитории chipdesignschool.*

> **Совет.** Для каждого предложения удобно заводить отдельную ветку, а не коммитить прямо в `main`:
>
> `git switch -c hyperbola` — создать ветку и перейти в неё; затем коммиты как обычно; `git push -u origin hyperbola` — отправить ветку в форк. На GitHub появится предложение открыть PR из этой ветки.
>
> Тогда `main` вашего форка остаётся точной копией исходного репозитория, его легко синхронизировать, а несколько PR не смешиваются друг с другом.

<a id="s13"></a>

## 13. Синхронизация своего форка с исходным репозиторием

Пока вы работаете, в репозиторий Школы добавляются новые упражнения и исправления. Форк сам по себе не обновляется: GitHub покажет на его странице *This branch is N commits behind …*. Ваши изменения при синхронизации не теряются — Git объединяет их с новыми коммитами.

> **Важно.** Перед синхронизацией зафиксируйте свои изменения коммитом (глава 10) или временно отложите их командой `git stash`; после синхронизации верните их командой `git stash pop`.

<a id="s13_1"></a>

### Способ 1: кнопка Sync fork на GitHub

1. Откройте страницу своего форка на GitHub.
2. Нажмите **Sync fork**, затем **Update branch**. GitHub перенесёт в форк новые коммиты исходного репозитория.
3. В терминале, в каталоге репозитория, заберите их на компьютер:

```bash
git pull
```

Если в вашей ветке есть коммиты, которых нет в исходном репозитории, и они затрагивают те же строки, что и новые коммиты, GitHub не сможет объединить их сам. Тогда используйте способ 2.

<a id="s13_2"></a>

### Способ 2: из командной строки

Добавьте исходный репозиторий как второй удалённый репозиторий с именем `upstream`. Это делается один раз:

```bash
git remote add upstream https://github.com/chipdesignschool/basics-graphics-music.git
```

Каждый раз для синхронизации:

```bash
git fetch upstream
git merge upstream/main
git push
```

`git fetch upstream` скачивает новые коммиты репозитория Школы, `git merge upstream/main` объединяет их с вашей текущей веткой, `git push` отправляет результат в ваш форк. Проверить список удалённых репозиториев можно командой `git remote -v`: `origin` — ваш форк, `upstream` — репозиторий Школы.

Если `git merge` сообщает о конфликте (CONFLICT), Git помечает в файлах спорные места. VSCode подсвечивает их и предлагает кнопки *Accept Current Change*, *Accept Incoming Change* и *Accept Both Changes*. Выберите нужный вариант в каждом месте, сохраните файлы и завершите объединение:

```bash
git add имя_файла
git commit -m "Merge upstream changes"
git push
```

<a id="s14"></a>

## 14. Схема после элаборации в Quartus

Скрипты синтезируют проект в пакетном режиме, без окон. Чтобы увидеть, какую схему Quartus построил из кода, откройте проект в графической оболочке скриптом `05`: `./05` и Tab.

[![Рис. 14.1. Набрано начало имени скрипта.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_01.png)

*Рис. 14.1. Набрано начало имени скрипта.*

[![Рис. 14.2. Скрипт запуска графической оболочки.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_02.png)

*Рис. 14.2. Скрипт запуска графической оболочки.*

Откроется Quartus Prime с проектом `fpga_project` из каталога `run`. Слева вверху — иерархия проекта (верхний модуль `board_specific_top`), под ней — список задач **Tasks**.

[![Рис. 14.3. Проект упражнения в Quartus Prime Lite.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_03.png)

*Рис. 14.3. Проект упражнения в Quartus Prime Lite.*

Запустите компиляцию двойным щелчком по **Compile Design**. Для просмотра схемы достаточно и первого шага, **Analysis & Synthesis**.

[![Рис. 14.4. Задача Compile Design.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_04.png)

*Рис. 14.4. Задача Compile Design.*

[![Рис. 14.5. Компиляция идёт.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_05.png)

*Рис. 14.5. Компиляция идёт.*

[![Рис. 14.6. Компиляция завершена: 0 ошибок.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_06.png)

*Рис. 14.6. Компиляция завершена: 0 ошибок.*

Отчёт **Flow Summary** показывает, сколько ресурсов ПЛИС занял проект: логических элементов, регистров, выводов и встроенных умножителей.

[![Рис. 14.7. Flow Summary.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_07.png)](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_07.png)

*Рис. 14.7. Flow Summary.*

Откройте схему: в списке задач раскройте **Analysis & Synthesis → Netlist Viewers** и дважды щёлкните **RTL Viewer**.

[![Рис. 14.8. Задача RTL Viewer.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_08.png)](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_08.png)

*Рис. 14.8. Задача RTL Viewer.*

RTL Viewer показывает схему всего проекта: модуль упражнения `lab_top`, генератор развёртки VGA `vga`, генератор медленного тактового сигнала, приёмник микрофона и выход звука.

[![Рис. 14.9. Схема верхнего модуля в RTL Viewer.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_09.png)](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_09.png)

*Рис. 14.9. Схема верхнего модуля в RTL Viewer.*

Чтобы рассмотреть детали, выберите на панели инструментов **Zoom Tool** (лупа) и щёлкайте по нужному месту; колесо мыши тоже меняет масштаб.

[![Рис. 14.10. Инструмент Zoom Tool.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_10.png)](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_10.png)

*Рис. 14.10. Инструмент Zoom Tool.*

[![Рис. 14.11. Увеличенная схема верхнего модуля.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_11.png)](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_11.png)

*Рис. 14.11. Увеличенная схема верхнего модуля.*

[![Рис. 14.12. Блок lab_top:i_lab_top.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_12.png)](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_12.png)

*Рис. 14.12. Блок lab_top:i_lab_top.*

Вернитесь к инструменту выделения (стрелка) и дважды щёлкните по блоку `lab_top:i_lab_top`, чтобы открыть его содержимое. То же самое делает значок **+** в углу блока. Слева, в **Netlist Navigator**, можно выбирать экземпляры модулей по иерархии.

[![Рис. 14.13. Инструмент выделения.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_13.png)](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_13.png)

*Рис. 14.13. Инструмент выделения.*

Внутри видна схема, построенная из кода упражнения: умножители (`Mult`), сумматоры (`Add`), компараторы (`LessThan`) и мультиплексоры, выбирающие цвет точки. Гипербола из главы 9 добавила умножитель `x * y` и компаратор с константой 20000, которая на схеме записана как `19'h4e20`.

[![Рис. 14.14. Схема модуля lab_top.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_14.png)](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_14.png)

*Рис. 14.14. Схема модуля lab_top.*

<a id="s15"></a>

## 15. Синтез для ALINX AX7035B с ПЛИС Xilinx

Теперь тот же пример для другой платы — ALINX AX7035B с ПЛИС Xilinx Artix-7. Выберите плату скриптом `06`.

[![Рис. 15.1. Скрипт выбора платы.](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_01.png)

*Рис. 15.1. Скрипт выбора платы.*

У платы `alinx_ax7035b` три конфигурации: базовая и две с выводом изображения через HDMI, `alinx_ax7035b_hdmi_by_claude` и `alinx_ax7035b_hdmi_by_codex`. Это две реализации HDMI, написанные с помощью ИИ-агентов Claude Code и Codex. На снимке выбрана третья.

[![Рис. 15.2. Конфигурации платы alinx_ax7035b.](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_02.png)

*Рис. 15.2. Конфигурации платы alinx_ax7035b.*

[![Рис. 15.3. Плата выбрана, запускаем синтез.](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_03.png)

*Рис. 15.3. Плата выбрана, запускаем синтез.*

[![Рис. 15.4. Скрипт синтеза.](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_04.png)

*Рис. 15.4. Скрипт синтеза.*

Скрипт запускает Vivado в пакетном режиме: синтез, размещение, трассировку, генерацию файла конфигурации и, если плата подключена, загрузку в ПЛИС через hw_server. Последние строки показывают, что загрузка прошла и Vivado завершил работу.

[![Рис. 15.5. Конец вывода Vivado.](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_05.png)

*Рис. 15.5. Конец вывода Vivado.*

[![Рис. 15.6. Плата ALINX AX7035B выводит изображение через HDMI.](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_06.jpg)](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_06.jpg)

*Рис. 15.6. Плата ALINX AX7035B выводит изображение через HDMI.*

<a id="s16"></a>

## 16. Просмотр схем в Xilinx Vivado

Откройте проект в графической оболочке Vivado: `./05` и Tab.

[![Рис. 16.1. Набрано начало имени скрипта.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_01.png)

*Рис. 16.1. Набрано начало имени скрипта.*

[![Рис. 16.2. Скрипт запуска графической оболочки.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_02.png)

*Рис. 16.2. Скрипт запуска графической оболочки.*

[![Рис. 16.3. Заставка Vivado.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_03.png)

*Рис. 16.3. Заставка Vivado.*

Скрипт синтеза создаёт в каталоге `run` проект Vivado `gui_prj/board_specific_top.xpr`, и скрипт `05` открывает именно его. В правой части окна видны параметры проекта, например ПЛИС `xc7a35tfgg484-2`.

[![Рис. 16.4. Проект в Vivado.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_04.png)

*Рис. 16.4. Проект в Vivado.*

В панели **Flow Navigator** слева, в разделе **RTL ANALYSIS**, нажмите **Open Elaborated Design**.

[![Рис. 16.5. Open Elaborated Design.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_05.png)

*Рис. 16.5. Open Elaborated Design.*

Vivado предупредит, что настройки элаборации замедляют её. Нажмите **OK**.

[![Рис. 16.6. Окно Elaborate Design.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_07.png)](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_07.png)

*Рис. 16.6. Окно Elaborate Design.*

Когда элаборация закончится, под **Open Elaborated Design** появится пункт **Schematic**.

[![Рис. 16.7. Пункт Schematic.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_06.png)

*Рис. 16.7. Пункт Schematic.*

Откроется схема верхнего модуля. Снимок сделан под Linux; под Windows окно выглядит так же.

[![Рис. 16.8. Схема после элаборации в Vivado (Linux).](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_08.png)](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_08.png)

*Рис. 16.8. Схема после элаборации в Vivado (Linux).*

Наведите курсор на блок `i_lab_top`: подсказка покажет имя экземпляра и модуля. Двойной щелчок или значок **+** раскрывает блок.

[![Рис. 16.9. Блок i_lab_top.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_09.png)](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_09.png)

*Рис. 16.9. Блок i_lab_top.*

Внутри — та же логика, что в RTL Viewer Quartus, но в обозначениях Vivado: `RTL_MULT` (умножитель), `RTL_ADD` (сумматор), `RTL_LT` и `RTL_GEQ` (сравнения «меньше» и «больше или равно»), `RTL_AND`, `RTL_MUX` (мультиплексор). Это схема после элаборации, ещё без привязки к ресурсам конкретной ПЛИС. Схему из таблиц LUT, триггеров и цепей переноса показывает **Open Synthesized Design → Schematic**, но для этого в проекте сначала должен быть выполнен синтез (глава 17).

[![Рис. 16.10. Схема модуля lab_top в Vivado.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_10.png)](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_10.png)

*Рис. 16.10. Схема модуля lab_top в Vivado.*

<a id="s17"></a>

## 17. Просмотр размещённого проекта в Xilinx Vivado

Чтобы увидеть, как проект разместился внутри ПЛИС, нужны результаты реализации (implementation). Нажмите на панели инструментов **Generate Bitstream**.

[![Рис. 17.1. Кнопка Generate Bitstream.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_01.png)

*Рис. 17.1. Кнопка Generate Bitstream.*

Скрипт синтеза уже выполнил всю цепочку, но в пакетном режиме, и сохранил результаты в файлы контрольных точек (`post_synth.dcp`, `post_place.dcp`, `post_route.dcp`). Прогоны внутри проекта `gui_prj` (`synth_1` и `impl_1`) при этом не запускались, поэтому Vivado предлагает выполнить синтез и реализацию. Нажмите **Yes**.

[![Рис. 17.2. Нет результатов реализации, запустить синтез и реализацию.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_02.png)

*Рис. 17.2. Нет результатов реализации, запустить синтез и реализацию.*

В окне **Launch Runs** можно указать число параллельных заданий; нажмите **OK**.

[![Рис. 17.3. Окно Launch Runs.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_03.png)

*Рис. 17.3. Окно Launch Runs.*

Когда генерация файла конфигурации закончится, выберите **Open Implemented Design** и нажмите **OK**.

[![Рис. 17.4. Генерация завершена, открываем реализованный проект.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_04.png)

*Рис. 17.4. Генерация завершена, открываем реализованный проект.*

[![Рис. 17.5. Загрузка реализованного проекта.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_05.png)

*Рис. 17.5. Загрузка реализованного проекта.*

Справа вверху открывается вид **Device** — кристалл ПЛИС с размещённой логикой. Внизу, на вкладке **Timing**, — сводка временного анализа. Положительный запас WNS (Worst Negative Slack) и надпись *All user specified timing constraints are met* означают, что схема успевает работать на заданной тактовой частоте.

[![Рис. 17.6. Реализованный проект: вид Device и сводка Timing.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_06.png)

*Рис. 17.6. Реализованный проект: вид Device и сводка Timing.*

Увеличивайте вид Device кнопкой **Zoom In** (`Ctrl+=`) или колесом мыши. Занятые ячейки выделены цветом.

[![Рис. 17.7. Занятые ресурсы на кристалле.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_07.png)](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_07.png)

*Рис. 17.7. Занятые ресурсы на кристалле.*

[![Рис. 17.8. Плитки CLB, DSP и блочной памяти.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_08.png)](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_08.png)

*Рис. 17.8. Плитки CLB, DSP и блочной памяти.*

При сильном увеличении видны отдельные слайсы (SLICE) с таблицами LUT, триггерами и цепью переноса. Подпись над ячейкой показывает, какой части проекта она принадлежит: здесь `i_lab_top/red4__0_carry` — элемент цепи переноса (carry) из модуля упражнения.

[![Рис. 17.9. Слайс с цепью переноса из модуля lab_top.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_09.png)](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_09.png)

*Рис. 17.9. Слайс с цепью переноса из модуля lab_top.*

> **Совет.** Размещённый проект можно открыть и без повторного запуска: **File → Checkpoint → Open** и файл `run/post_route.dcp`, который сохранил скрипт синтеза.

<a id="s18"></a>

## 18. Синтез для Tang Nano 9K с LCD на ПЛИС Gowin

Третья САПР — Gowin EDA. Выберите скриптом `06` плату `tang_nano_9k`, а затем конфигурацию `tang_nano_9k_lcd_480_272_tm1638`: Tang Nano 9K с LCD-экраном 480×272 и модулем TM1638 (8 семисегментных индикаторов, 8 светодиодов и 8 кнопок).

[![Рис. 18.1. Конфигурации платы tang_nano_9k.](https://www.panchul.com/bgm_workflow_manual/20261011/18_running_synthesis_for_tang_nano_9k_lcd_with_gowin_fpga/18_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/18_running_synthesis_for_tang_nano_9k_lcd_with_gowin_fpga/18_01.png)

*Рис. 18.1. Конфигурации платы tang_nano_9k.*

Скрипт находит Gowin EDA и печатает пути к его программам: `gw_ide` (графическая оболочка), `gw_sh` (пакетный режим) и `programmer_cli` (загрузка в ПЛИС).

[![Рис. 18.2. Найден Gowin EDA.](https://www.panchul.com/bgm_workflow_manual/20261011/18_running_synthesis_for_tang_nano_9k_lcd_with_gowin_fpga/18_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/18_running_synthesis_for_tang_nano_9k_lcd_with_gowin_fpga/18_02.png)

*Рис. 18.2. Найден Gowin EDA.*

Запустите `./03_synthesize_for_fpga.bash`. В конце вывода — загрузка проекта в SRAM ПЛИС GW1NR-9C. Отдельный кабель не нужен: адаптер JTAG встроен в плату и подключается через её разъём USB-C.

[![Рис. 18.3. Синтез и загрузка в Tang Nano 9K.](https://www.panchul.com/bgm_workflow_manual/20261011/18_running_synthesis_for_tang_nano_9k_lcd_with_gowin_fpga/18_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/18_running_synthesis_for_tang_nano_9k_lcd_with_gowin_fpga/18_03.png)

*Рис. 18.3. Синтез и загрузка в Tang Nano 9K.*

[![Рис. 18.4. Tang Nano 9K с LCD-экраном и модулем TM1638.](https://www.panchul.com/bgm_workflow_manual/20261011/18_running_synthesis_for_tang_nano_9k_lcd_with_gowin_fpga/18_04.jpg)](https://www.panchul.com/bgm_workflow_manual/20261011/18_running_synthesis_for_tang_nano_9k_lcd_with_gowin_fpga/18_04.jpg)

*Рис. 18.4. Tang Nano 9K с LCD-экраном и модулем TM1638.*

<a id="s19"></a>

## 19. Схема и отчёты в Gowin EDA

Скрипт `05` открывает проект в Gowin FPGA Designer. Схему показывает **Tools → Schematic Viewer → RTL Design Viewer**.

[![Рис. 19.1. Меню RTL Design Viewer (Linux).](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_01.png)

*Рис. 19.1. Меню RTL Design Viewer (Linux).*

Справа от списка файлов — иерархия проекта: цепи (Nets), примитивы (Primitives), порты (Ports) и модули (Modules).

[![Рис. 19.2. RTL Design Viewer.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_02.png)

*Рис. 19.2. RTL Design Viewer.*

Масштаб меняется кнопками **Zoom In** и **Zoom Out** на панели инструментов.

[![Рис. 19.3. Кнопка Zoom In.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_03.png)

*Рис. 19.3. Кнопка Zoom In.*

В списке **Modules** видны все модули проекта: упражнение `i_lab_top`, контроллер TM1638, ФАПЧ `i_Gowin_rPLL`, контроллер экрана `i_lcd`, приёмник микрофона и выход звука. Двойной щелчок по модулю открывает его схему.

[![Рис. 19.4. Схема и список модулей.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_04.png)

*Рис. 19.4. Схема и список модулей.*

<a id="s19_1"></a>

### Отчёты Gowin в VSCode

Отчёты Gowin — это файлы HTML в каталоге `run/impl`. Их удобно смотреть прямо в VSCode: щёлкните по файлу правой кнопкой мыши и выберите **Open in Integrated Browser**.

| Файл | Содержание |
|---|---|
| `run/impl/gwsynthesis/fpga_project_syn.rpt.html` | отчёт синтеза: ресурсы и оценка частоты |
| `run/impl/pnr/fpga_project.rpt.html` | отчёт размещения и трассировки: занятые ресурсы |
| `run/impl/pnr/fpga_project.tr.html` | временной анализ после размещения |
| `run/impl/pnr/fpga_project.pin.html` | назначение выводов |
| `run/impl/pnr/fpga_project.power.html` | оценка потребляемой мощности |

[![Рис. 19.5. Открытие отчёта во встроенном браузере VSCode.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_05.png)

*Рис. 19.5. Открытие отчёта во встроенном браузере VSCode.*

[![Рис. 19.6. Контекстное меню для отчёта синтеза.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_06.png)

*Рис. 19.6. Контекстное меню для отчёта синтеза.*

Отчёт синтеза показывает, сколько таблиц LUT, сумматоров (ALU) и регистров занял проект, и список тактовых сигналов.

[![Рис. 19.7. Отчёт синтеза: ресурсы и тактовые сигналы.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_07.png)](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_07.png)

*Рис. 19.7. Отчёт синтеза: ресурсы и тактовые сигналы.*

Раздел **Max Frequency Summary** — оценка максимальной частоты по результатам синтеза.

[![Рис. 19.8. Отчёт синтеза: максимальная частота.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_08.png)](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_08.png)

*Рис. 19.8. Отчёт синтеза: максимальная частота.*

Точная оценка — в отчёте временного анализа `fpga_project.tr.html`, после размещения и трассировки.

[![Рис. 19.9. Открытие отчёта временного анализа.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_09.png)](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_09.png)

*Рис. 19.9. Открытие отчёта временного анализа.*

В **Max Frequency Summary** для каждого тактового сигнала указаны заданная частота (Constraint) и достижимая (Actual Fmax). Нули в **Total Negative Slack Summary** означают, что временные ограничения выполнены.

[![Рис. 19.10. Отчёт временного анализа.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_10.png)](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_10.png)

*Рис. 19.10. Отчёт временного анализа.*

<a id="s20"></a>

## 20. Клонирование форка на Apple Mac с процессором ARM

Те же шаги на компьютере Mac с процессором Apple (M1 и новее). Откройте в браузере свою страницу на GitHub и свой форк. На снимках форк уже содержит коммит с гиперболой, отправленный с компьютера под Windows в главе 10.

[![Рис. 20.1. Профиль GitHub на Mac.](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_01.png)

*Рис. 20.1. Профиль GitHub на Mac.*

[![Рис. 20.2. Форк с коммитом из главы 10.](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_02.png)

*Рис. 20.2. Форк с коммитом из главы 10.*

Скопируйте адрес для клонирования: **Code → Local → HTTPS**.

[![Рис. 20.3. Адрес форка для клонирования.](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_03.png)

*Рис. 20.3. Адрес форка для клонирования.*

Откройте программу **Terminal**: значок **Apps** (Launchpad) в Dock, затем **Terminal**. Её можно найти и через Spotlight (`Cmd+Space`).

[![Рис. 20.4. Значок Apps в Dock.](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_04.png)

*Рис. 20.4. Значок Apps в Dock.*

[![Рис. 20.5. Программы Terminal и Visual Studio Code.](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_05.png)

*Рис. 20.5. Программы Terminal и Visual Studio Code.*

Перейдите в домашний каталог и клонируйте форк:

```bash
cd
pwd
git clone https://github.com/Dmitri-Mendeleev/basics-graphics-music.git
```

[![Рис. 20.6. Команда клонирования в Terminal.](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_06.png)

*Рис. 20.6. Команда клонирования в Terminal.*

[![Рис. 20.7. Клонирование завершено.](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_07.png)](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_07.png)

*Рис. 20.7. Клонирование завершено.*

<a id="s21"></a>

## 21. Открытие репозитория в VSCode на Apple Mac с процессором ARM

Запустите VSCode и откройте каталог репозитория: **File → Open Folder…**.

[![Рис. 21.1. VSCode на Mac.](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_01.png)

*Рис. 21.1. VSCode на Mac.*

[![Рис. 21.2. Меню File → Open Folder…](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_02.png)

*Рис. 21.2. Меню File → Open Folder…*

[![Рис. 21.3. Выбор каталога basics-graphics-music.](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_03.png)

*Рис. 21.3. Выбор каталога basics-graphics-music.*

[![Рис. 21.4. Репозиторий открыт.](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_04.png)

*Рис. 21.4. Репозиторий открыт.*

Установите расширения, как в главе 5. Откройте панель **Extensions** значком слева.

[![Рис. 21.5. Значок Extensions.](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_05.png)

*Рис. 21.5. Значок Extensions.*

Найдите **surfer** и нажмите **Install**.

[![Рис. 21.6. Расширение surfer в Marketplace.](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_06.png)

*Рис. 21.6. Расширение surfer в Marketplace.*

VSCode спрашивает, доверяете ли вы издателю расширения. Для surfer нажмите **Trust Publisher & Install**.

[![Рис. 21.7. Подтверждение доверия издателю.](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_07.png)](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_07.png)

*Рис. 21.7. Подтверждение доверия издателю.*

Так же установите **SystemVerilog - Language Support**.

[![Рис. 21.8. Установленные расширения.](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_08.png)](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_08.png)

*Рис. 21.8. Установленные расширения.*

<a id="s22"></a>

## 22. Синтез для Tang Nano 9K с HDMI в Gowin EDA под macOS

Под macOS терминал открывается прямо в каталоге упражнения: щёлкните по каталогу правой кнопкой мыши и выберите **Open in Integrated Terminal**.

[![Рис. 22.1. Пункт Open in Integrated Terminal.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_01.png)

*Рис. 22.1. Пункт Open in Integrated Terminal.*

Откроется терминал zsh, приглашение которого заканчивается на `%`. В строке состояния VSCode видно, что окончания строк здесь Unix (LF), а не Windows (CRLF), как на снимках главы 9.

[![Рис. 22.2. Терминал zsh в каталоге упражнения.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_02.png)

*Рис. 22.2. Терминал zsh в каталоге упражнения.*

Выберите плату: `./06` и Tab.

[![Рис. 22.3. Набрано начало имени скрипта.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_03.png)

*Рис. 22.3. Набрано начало имени скрипта.*

[![Рис. 22.4. Скрипт выбора платы.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_04.png)

*Рис. 22.4. Скрипт выбора платы.*

[![Рис. 22.5. Выбрана плата tang_nano_9k.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_05.png)

*Рис. 22.5. Выбрана плата tang_nano_9k.*

Конфигурация `tang_nano_9k_hdmi_tm1638`: изображение выводится через разъём HDMI самой платы, без LCD-экрана.

[![Рис. 22.6. Выбрана конфигурация tang_nano_9k_hdmi_tm1638.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_06.png)

*Рис. 22.6. Выбрана конфигурация tang_nano_9k_hdmi_tm1638.*

Скрипт нашёл Gowin EDA внутри `/Applications/GowinIDE.app`. Gowin EDA под macOS работает только на компьютерах с процессором Apple.

[![Рис. 22.7. Gowin EDA найден в каталоге /Applications.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_07.png)](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_07.png)

*Рис. 22.7. Gowin EDA найден в каталоге /Applications.*

Запустите синтез.

[![Рис. 22.8. Скрипт синтеза.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_08.png)](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_08.png)

*Рис. 22.8. Скрипт синтеза.*

[![Рис. 22.9. Проект загружен в Tang Nano 9K.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_09.png)](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_09.png)

*Рис. 22.9. Проект загружен в Tang Nano 9K.*

[![Рис. 22.10. Tang Nano 9K выводит изображение на монитор через HDMI.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_10.jpg)](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_10.jpg)

*Рис. 22.10. Tang Nano 9K выводит изображение на монитор через HDMI.*

<a id="s23"></a>

## 23. Синтез для Tang Nano 9K в OSS CAD Suite

OSS CAD Suite — сборка открытых программ для синтеза: Yosys (логический синтез), nextpnr (размещение и трассировка), проект Apicula для ПЛИС Gowin, IceStorm для Lattice iCE40 и openFPGALoader (загрузка в ПЛИС). Скрипты BGM используют этот маршрут для конфигураций, имена которых оканчиваются на `_yosys`.

У Tang Nano 9K такие конфигурации есть для LCD-экранов. Выберите `tang_nano_9k_lcd_480_272_tm1638_yosys`.

[![Рис. 23.1. Скрипт выбора платы.](https://www.panchul.com/bgm_workflow_manual/20261011/23_running_synthesis_for_tang_nano_9k_hdmi_with_giwin_fpga_using_oss_cad_suite/23_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/23_running_synthesis_for_tang_nano_9k_hdmi_with_giwin_fpga_using_oss_cad_suite/23_01.png)

*Рис. 23.1. Скрипт выбора платы.*

[![Рис. 23.2. Конфигурации tang_nano_9k, выбрана 9-я.](https://www.panchul.com/bgm_workflow_manual/20261011/23_running_synthesis_for_tang_nano_9k_hdmi_with_giwin_fpga_using_oss_cad_suite/23_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/23_running_synthesis_for_tang_nano_9k_hdmi_with_giwin_fpga_using_oss_cad_suite/23_02.png)

*Рис. 23.2. Конфигурации tang_nano_9k, выбрана 9-я.*

Скрипт проверяет, что программы OSS CAD Suite для ПЛИС Gowin найдены: `Configuring for Gowin chips... OK`.

[![Рис. 23.3. Найдены программы OSS CAD Suite для Gowin.](https://www.panchul.com/bgm_workflow_manual/20261011/23_running_synthesis_for_tang_nano_9k_hdmi_with_giwin_fpga_using_oss_cad_suite/23_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/23_running_synthesis_for_tang_nano_9k_hdmi_with_giwin_fpga_using_oss_cad_suite/23_03.png)

*Рис. 23.3. Найдены программы OSS CAD Suite для Gowin.*

[![Рис. 23.4. Скрипт синтеза.](https://www.panchul.com/bgm_workflow_manual/20261011/23_running_synthesis_for_tang_nano_9k_hdmi_with_giwin_fpga_using_oss_cad_suite/23_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/23_running_synthesis_for_tang_nano_9k_hdmi_with_giwin_fpga_using_oss_cad_suite/23_04.png)

*Рис. 23.4. Скрипт синтеза.*

В конце вывода nextpnr сообщает об отсутствии ошибок, а openFPGALoader загружает проект в SRAM ПЛИС и проверяет контрольную сумму (*CRC check: Success*). Предупреждения вида *Numpy is not available, performance will be degraded* относятся к упаковщику Apicula и на результат не влияют.

[![Рис. 23.5. Синтез в OSS CAD Suite и загрузка в Tang Nano 9K.](https://www.panchul.com/bgm_workflow_manual/20261011/23_running_synthesis_for_tang_nano_9k_hdmi_with_giwin_fpga_using_oss_cad_suite/23_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/23_running_synthesis_for_tang_nano_9k_hdmi_with_giwin_fpga_using_oss_cad_suite/23_05.png)

*Рис. 23.5. Синтез в OSS CAD Suite и загрузка в Tang Nano 9K.*

<a id="s24"></a>

## 24. Синтез для iCEBreaker с ПЛИС Lattice в OSS CAD Suite

Плата iCEBreaker с ПЛИС Lattice iCE40UP5K синтезируется только открытым маршрутом. Выберите плату `icebreaker`.

[![Рис. 24.1. Скрипт выбора платы.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_01.png)

*Рис. 24.1. Скрипт выбора платы.*

[![Рис. 24.2. Список плат, выбрана icebreaker.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_02.png)

*Рис. 24.2. Список плат, выбрана icebreaker.*

Конфигурации отличаются модулем вывода изображения (DVI с 12-битным или 24-битным цветом либо без него) и наличием TM1638. На снимке выбрана `icebreaker_dvi_24b_tm1638_yosys`.

[![Рис. 24.3. Конфигурации платы icebreaker.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_03.png)

*Рис. 24.3. Конфигурации платы icebreaker.*

[![Рис. 24.4. Найдены программы OSS CAD Suite для Lattice iCE40.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_04.png)](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_04.png)

*Рис. 24.4. Найдены программы OSS CAD Suite для Lattice iCE40.*

[![Рис. 24.5. Набрано начало имени скрипта синтеза.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_05.png)](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_05.png)

*Рис. 24.5. Набрано начало имени скрипта синтеза.*

[![Рис. 24.6. Скрипт синтеза.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_06.png)](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_06.png)

*Рис. 24.6. Скрипт синтеза.*

В отличие от остальных плат в этой инструкции, openFPGALoader записывает проект для iCEBreaker во флеш-память на плате (*Erasing… Writing…*), поэтому он сохраняется и после выключения питания.

[![Рис. 24.7. Запись во флеш-память iCEBreaker.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_07.png)](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_07.png)

*Рис. 24.7. Запись во флеш-память iCEBreaker.*

[![Рис. 24.8. Рабочее место с iCEBreaker.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_08.jpg)](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_08.jpg)

*Рис. 24.8. Рабочее место с iCEBreaker.*

[![Рис. 24.9. iCEBreaker с модулями DVI и TM1638.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_09.jpg)](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_09.jpg)

*Рис. 24.9. iCEBreaker с модулями DVI и TM1638.*

<a id="s25"></a>

## 25. Просмотр размещённого проекта в nextpnr

В маршруте OSS CAD Suite скрипт `05` снова запускает синтез Yosys, а затем nextpnr с графическим интерфейсом.

[![Рис. 25.1. Набрано начало имени скрипта.](https://www.panchul.com/bgm_workflow_manual/20261011/25_view_implemented_design_in_oss_cad_suite_nextpnr/25_01.png)](https://www.panchul.com/bgm_workflow_manual/20261011/25_view_implemented_design_in_oss_cad_suite_nextpnr/25_01.png)

*Рис. 25.1. Набрано начало имени скрипта.*

[![Рис. 25.2. Скрипт запуска графического интерфейса.](https://www.panchul.com/bgm_workflow_manual/20261011/25_view_implemented_design_in_oss_cad_suite_nextpnr/25_02.png)](https://www.panchul.com/bgm_workflow_manual/20261011/25_view_implemented_design_in_oss_cad_suite_nextpnr/25_02.png)

*Рис. 25.2. Скрипт запуска графического интерфейса.*

Окно nextpnr показывает кристалл ПЛИС (здесь Lattice iCE40UP5K в корпусе sg48). Справа — списки элементов кристалла и проекта на вкладках: **Bels** (базовые элементы), **Wires** (провода), **Pips** (программируемые соединения), **Cells** (ячейки проекта), **Nets** (цепи) и **Groups**. Выбранный в списке элемент подсвечивается на кристалле, а его свойства появляются ниже. Внизу слева — консоль Python для команд nextpnr.

Если на кристалле не видно размещённых ячеек, выполните этапы упаковки, размещения и трассировки кнопками на панели инструментов. Масштаб меняется колесом мыши.

[![Рис. 25.3. nextpnr-ice40 для Lattice iCE40UP5K.](https://www.panchul.com/bgm_workflow_manual/20261011/25_view_implemented_design_in_oss_cad_suite_nextpnr/25_03.png)](https://www.panchul.com/bgm_workflow_manual/20261011/25_view_implemented_design_in_oss_cad_suite_nextpnr/25_03.png)

*Рис. 25.3. nextpnr-ice40 для Lattice iCE40UP5K.*

<a id="sa"></a>

## Приложение А. Минималистичная шпаргалка по Git

Перевод файла [git_cheat_sheet.md](https://github.com/yuri-panchul/basics-graphics-music/blob/main/git_cheat_sheet.md) из репозитория BGM (автор — Юрий Панчул, обновлён 28.08.2026). Наши примечания и дополнения отмечены словами **Примечание** и **Дополнение**.

<a id="sa_1"></a>

### 1. В начале работы

#### 1.1. Укажите своё имя и адрес почты

```bash
git config --global user.name  "Your Name"
git config --global user.email your@email.com
```

#### 1.2. Включите кэширование пароля

```bash
git config credential.helper 'cache --timeout=3600'
```

Без этого придётся вводить имя пользователя и пароль при каждом `git push`. Время хранения задаётся в секундах; по его истечении Git снова спросит имя и пароль.

> **Примечание.** В оригинале сказано, что эта команда задаёт время в 10 часов. На самом деле `3600` секунд — это один час; для 10 часов укажите `36000`. Без ключа `--global` настройка действует только в текущем репозитории. Вместо пароля GitHub принимает только токен доступа (глава 11). Под Windows эту команду выполнять не нужно: там работает Git Credential Manager, а `cache` в Git для Windows недоступен (глава 10).

#### 1.3. Клонируйте репозиторий с GitHub

```bash
git clone https://github.com/yuri-panchul/basics-graphics-music
```

> **Дополнение.** Студентам Школы нужно клонировать не этот репозиторий, а свой форк репозитория chipdesignschool (главы 2 и 4): `git clone https://github.com/<ваше_имя>/basics-graphics-music.git`.

<a id="sa_2"></a>

### 2. Цикл разработки

#### 2.1. Получите изменения, сделанные другими

```bash
git pull
```

#### 2.2. Добавьте новые файлы или каталоги (рекурсивно)

```bash
git add file_or_directory_name
```

#### 2.3. Отредактируйте файлы

#### 2.4. Перед фиксацией проверьте состояние

Обратите внимание на изменённые, добавленные и удалённые файлы, а также на файлы, которые вы собирались добавить, но забыли.

```bash
git status
```

#### 2.5. Сравните свои изменения с репозиторием

```bash
git diff
```

#### 2.6. Не добавляйте в репозиторий текст с табуляциями

Разные редакторы показывают табуляции по-разному, и многим это неудобно. Разработчикам не должно быть нужно настраивать ширину табуляции, чтобы читать исходный код. Есть исключения, прежде всего Makefile. Найти табуляции в текстовых файлах можно так:

```bash
grep -rlI --exclude-dir=.git --exclude=*.mk $'\t' .
```

Ключи `grep`:

- `-r` — рекурсивный поиск;
- `-l` — вывести только список файлов;
- `-I` — пропускать двоичные файлы.

Исправить табуляции можно так, но обязательно проверьте результат:

```bash
grep -rlI --exclude-dir=.git --exclude=*.mk $'\t' . | xargs sed -i 's/\t/    /g'
```

> **Дополнение.** В VSCode табуляции заменяются пробелами при вводе, если в строке состояния выбрано *Spaces: 4*. Табуляции в отступах уже открытого файла заменяет команда палитры (`Ctrl+Shift+P`) *Convert Indentation to Spaces*.

#### 2.7. Отменить незафиксированные изменения файла или каталога

```bash
git checkout file_or_directory_name
```

#### 2.8. Отменить все незафиксированные изменения в текущем каталоге, включая удаления

```bash
git checkout .
```

> **Дополнение.** В новых версиях Git для этого есть более понятная команда `git restore`: `git restore имя_файла` или `git restore .`. Отменённые так изменения восстановить нельзя.

#### 2.9. Отмена зафиксированных или уже отправленных изменений

Если нужно отменить зафиксированные или даже отправленные изменения, обратитесь к опытному пользователю Git или внимательно прочитайте документацию, убедившись, что понимаете каждый шаг.

#### 2.10. Закончив редактирование, зафиксируйте изменения

Ключ `-a` автоматически включает в коммит все изменения и удаления файлов, но не новые файлы. Новые файлы и каталоги нужно добавить явно командой `git add`.

**Важное замечание 1: перед каждым коммитом выполняйте `git status` и `git diff`.** Отменить зафиксированные и особенно отправленные изменения труднее, чем незафиксированные.

**Важное замечание 2: пишите осмысленный комментарий к каждому коммиту.**

```bash
git commit -am "A meaningful comment"
```

#### 2.11. Опубликуйте все зафиксированные изменения в репозитории (например, на GitHub)

После этого ваши изменения видны всем.

```bash
git push
```

<a id="sa_3"></a>

### 3. Другие приёмы

#### 3.1. Историю репозитория можно смотреть прямо на github.com в браузере

#### 3.2. Файлы, которые Git должен игнорировать, перечислите в .gitignore

Это могут быть автоматически созданные двоичные и временные файлы или посторонние файлы, которые вы не хотите фиксировать и видеть в выводе `git status`. Прежде чем менять `.gitignore`, прочитайте о нём в документации Git.

> **Дополнение.** В репозитории BGM `.gitignore` уже содержит каталоги `run` и `work`, файлы `log.txt` и `fpga_board_selection` и некоторые другие. Поэтому результаты синтеза и выбор платы не попадают в коммиты.

#### 3.3. Файлы, не отслеживаемые Git

```bash
git clean -dn
```

Команда работает от текущего каталога вниз. Проверив список (будьте осторожны!), удалить эти файлы можно так:

```bash
git clean -df
```

#### 3.4. Файлы, игнорируемые Git

Чтобы поддерживать порядок, периодически удаляйте файлы, которые Git игнорирует по списку `.gitignore`. Перед подготовкой выпуска это нужно делать обязательно.

```bash
git clean -dxn
```

Проверив список (будьте осторожны!), удалить эти файлы можно так:

```bash
git clean -dxf
```

#### 3.5. Для нетривиальных операций (слияние, отмена зафиксированных или отправленных изменений) внимательно изучите документацию Git

Иначе можно внести путаницу и ошибки или зафиксировать большие двоичные файлы, засоряющие репозиторий.

<a id="sa_4"></a>

### Дополнение: команды для работы с форком

| Команда | Что делает |
|---|---|
| `git log --oneline -10` | последние 10 коммитов, по одному на строку |
| `git diff --staged` | изменения, уже добавленные командой `git add` |
| `git restore --staged имя_файла` | убрать файл из следующего коммита, сохранив изменения |
| `git commit --amend` | исправить последний коммит, пока он не отправлен командой `git push` |
| `git switch -c имя_ветки` | создать ветку и перейти в неё (глава 12) |
| `git switch main` | вернуться в ветку `main` |
| `git push -u origin имя_ветки` | первый раз отправить новую ветку в свой форк |
| `git stash` / `git stash pop` | временно отложить незафиксированные изменения и вернуть их |
| `git remote add upstream https://github.com/chipdesignschool/basics-graphics-music.git` | один раз: подключить репозиторий Школы (глава 13) |
| `git fetch upstream` и `git merge upstream/main` | забрать обновления репозитория Школы |
| `git remote -v` | список удалённых репозиториев |

<a id="sb"></a>

## Приложение Б. Как скрипты BGM находят САПР ПЛИС

Скрипты упражнений начинаются с общего файла [`scripts/steps/00_setup.source_bash`](https://github.com/yuri-panchul/basics-graphics-music/blob/main/scripts/steps/00_setup.source_bash). Он читает выбранную плату из `fpga_board_selection` и по её имени определяет маршрут синтеза:

| Имя конфигурации | Маршрут |
|---|---|
| оканчивается на `_yosys` | OSS CAD Suite (проверяется первым) |
| `tang_*`, `runber`, `marsohod3gw2*`, `orangepi*` | Gowin EDA |
| `de*`, `c5gx*`, `omdazz*`, `rzrd*`, `saylinx*`, `zeowaa*` и другие платы с ПЛИС Altera | Quartus |
| `alinx_ax7035b*`, `arty_a7*`, `basys3`, `nexys*`, `zybo_z7` и другие платы с ПЛИС Xilinx | Vivado |

Если в каталоге упражнения есть файл `hackathon_top.sv` со строкой `// Board configuration: <имя>`, плата берётся из неё, а не из `fpga_board_selection`.

Затем вызывается функция поиска выбранной САПР. Все четыре функции устроены похоже: сначала они проверяют переменную окружения, указывающую точный каталог, затем программы, уже доступные через `PATH`, затем переменную с родительским каталогом установки и, наконец, стандартные места установки. В Git Bash под Windows диски `C:`, `D:` и `E:` называются `/c`, `/d` и `/e`.

| САПР | Точный каталог | Родительский каталог | Платформы |
|---|---|---|---|
| Vivado | `XILINX_VIVADO` | `XILINX_HOME` | Windows, Linux |
| Quartus | `QUARTUS_ROOTDIR` | `INTEL_FPGA_HOME`, `ALTERA_HOME`, `QUARTUS_HOME` | Windows, Linux |
| Gowin EDA | `GOWIN_VERSION_DIR` | `GOWIN_HOME` | Windows, Linux, macOS (только Apple silicon) |
| OSS CAD Suite | — | — | Windows, Linux, macOS |

Переменные задаются командой `export`, например в `~/.bashrc` (Linux и Git Bash) или в `~/.zshrc` (macOS):

```bash
export XILINX_VIVADO=/c/Xilinx/Vivado/2023.2
```

<a id="sb_1"></a>

### Б.1. Xilinx Vivado

Код: функция `xilinx_setup_vivado` в [`00_setup_xilinx.source_bash`](https://github.com/yuri-panchul/basics-graphics-music/blob/main/scripts/steps/00_setup_xilinx.source_bash). Vivado не работает под macOS, поэтому поиск выполняется только под Linux и Windows.

1. Если задана `XILINX_VIVADO` и в ней есть каталог `bin`, используется он.
2. Если команда `vivado` уже доступна через `PATH`, используется она.
3. Иначе Vivado ищется в родительских каталогах: сначала `XILINX_HOME`, если она задана, затем стандартные — `$HOME`, `/opt`, `/tools` под Linux и `/c`, `/d`, `/e` под Windows.

В каждом родительском каталоге проверяются подкаталоги производителя `Xilinx`, `AMD` и `AMDDesignTools` и два варианта расположения:

```text
<родитель>/<производитель>/Vivado/<версия>/bin      например /c/Xilinx/Vivado/2023.2/bin
<родитель>/<производитель>/<версия>/Vivado/bin      например /opt/AMDDesignTools/2025.2/Vivado/bin
```

Версией считается имя каталога, начинающееся с цифры. Выбирается первый родительский каталог, в котором нашлась хотя бы одна установка, а в нём — самая новая версия. Если версий несколько, скрипт перечисляет их в предупреждении и сообщает, какую выбрал. Найденный каталог записывается в `XILINX_VIVADO`, а его `bin` добавляется в `PATH`.

Если Vivado не найден, скрипт сообщает, в каких каталогах искал, и предлагает задать `XILINX_HOME` или `XILINX_VIVADO`.

<a id="sb_2"></a>

### Б.2. Altera Quartus

Код: функция `quartus_setup` в [`00_setup_altera.source_bash`](https://github.com/yuri-panchul/basics-graphics-music/blob/main/scripts/steps/00_setup_altera.source_bash). Подробнее с примерами — в Инструкции по установке ПО, [раздел 4.1.1.4](https://panchul.com/bgm_svh_manual/20261006_draft/claude/manual_ru.html#s4_1_1_4) (Windows) и [раздел 4.2.1.4](https://panchul.com/bgm_svh_manual/20261006_draft/claude/manual_ru.html#s4_2_1_4) (Linux).

Quartus ищется с учётом конкретной ПЛИС: скрипт читает её обозначение из строки `DEVICE` в файле `board_specific.qsf` платы, например `EP4CE6F17C8` для Saylinx, и выбирает версию Quartus, которая умеет с ней работать. Это важно для старых плат: Cyclone II и Cyclone III не поддерживаются новыми версиями Quartus.

Порядок поиска:

1. `QUARTUS_ROOTDIR` — каталог `quartus` конкретной установки. Под Windows эту переменную задаёт установщик Quartus, поэтому на снимке главы 7 написано *using QUARTUS_ROOTDIR*.
2. Команда `quartus`, уже доступная через `PATH`.
3. Родительские каталоги из `INTEL_FPGA_HOME`, `ALTERA_HOME` и `QUARTUS_HOME`.
4. Стандартные родительские каталоги: `$HOME`, `/opt`, `/tools` под Linux и `/c`, `/d`, `/e` под Windows.

Если найденный на каком-то шаге Quartus не подходит для ПЛИС платы, скрипт пишет предупреждение и продолжает поиск на следующих шагах.

В родительском каталоге проверяются подкаталоги `altera`, `altera_lite`, `altera_std`, `altera_pro`, `intelFPGA`, `intelFPGA_lite`, `intelFPGA_pro` и `intelFPGA_std`, а в них — `<версия>/quartus`, например `C:\intelFPGA_lite\23.1std\quartus`.

Каждый кандидат проверяется так:

- есть исполняемые файлы `quartus`, `quartus_sh` и `quartus_pgm` (в `bin`, а под Windows — в `bin64` или `bin`);
- по заставке `quartus_sh` определяются версия и редакция (Lite, Web, Standard или Pro);
- версия и редакция подходят для семейства ПЛИС (таблица ниже);
- база данных устройств этой установки действительно содержит нужную ПЛИС; это проверяет Tcl-скрипт `scripts/fpga/quartus_has_device.tcl`;
- путь не содержит пробелов, нелатинских букв и спецсимволов, иначе выдаётся предупреждение.

| Семейство ПЛИС | Ограничение |
|---|---|
| Cyclone (EP1C) | Lite/Web до 11.0 SP1, Standard до 13.0 SP1 |
| Cyclone II (EP2C) | до 13.0 SP1 |
| Cyclone III (EP3C) | до 13.1 |
| MAX 10 (10M) | начиная с 14.0 |
| Agilex 3 (A3) | только Pro, начиная с 25.1 |
| Cyclone, Cyclone II–IV, Cyclone V, MAX II, MAX 10 | не поддерживаются редакцией Pro |

Среди подходящих установок предпочитаются бесплатные (Lite и Web), затем более новая версия, а при равных версиях — Standard, а не Pro. Выбранный каталог записывается в `QUARTUS_ROOTDIR`, его `bin` ставится в начало `PATH`, и скрипт сообщает, например: *Selected Quartus Lite 23.1.0.991 for 'saylinx' (EP4CE6F17C8), using QUARTUS_ROOTDIR*.

<a id="sb_3"></a>

### Б.3. Gowin EDA

Код: функции `gowin_setup_ide` и `gowin_try_install_dir` в [`00_setup_gowin.source_bash`](https://github.com/yuri-panchul/basics-graphics-music/blob/main/scripts/steps/00_setup_gowin.source_bash). Gowin EDA работает под Windows, Linux и macOS на процессорах Apple; на Mac с процессором Intel скрипт сообщает об ошибке.

1. `GOWIN_VERSION_DIR` — каталог конкретной версии, в котором лежат `IDE` и `Programmer`.
2. Программа `gw_sh` в `PATH`, если там же есть программа загрузки: `openFPGALoader` под Linux или `programmer_cli` под Windows.
3. Родительский каталог из `GOWIN_HOME`.
4. Стандартные родительские каталоги: под macOS — `/Applications` и `~/Applications`, затем под Linux и macOS — `$HOME`, `/opt`, `/tools`, `~/Downloads`; под Windows — `/c`, `/d`, `/e`.

В родительском каталоге ищется подкаталог `Gowin` (под Linux также `gowin`, под macOS также `GowinIDE.app`), а в нём — подкаталоги, в имени которых есть `Gowin_`, например `Gowin_V1.9.9Beta-4_Education`. Подходит и каталог, в котором сразу лежит `IDE/bin/gw_sh`. Под macOS добавляется путь внутри приложения `Contents/Resources/Gowin_EDA`. Примеры с наших снимков:

```text
C:\Gowin\Gowin_V1.9.9Beta-4_Education                         (Windows, глава 18)
/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA         (macOS, глава 22)
```

> **Важно.** Если установлено несколько версий, выбирается последняя по алфавиту, а не по номеру версии: `Gowin_V1.9.9…` окажется «новее», чем `Gowin_V1.9.10…`, потому что символ `9` идёт после `1`. Скрипт предупреждает о нескольких версиях; чтобы выбрать нужную, задайте `GOWIN_VERSION_DIR`.

Найденная установка проверяется на наличие каталогов `IDE`, `IDE/bin` и `Programmer` и программ `gw_ide` и `gw_sh`, а под Windows и macOS также `programmer_cli`; скрипт печатает пути к ним (глава 18). Кроме того:

- под Linux скрипт подгружает через `LD_PRELOAD` системные библиотеки `libfreetype` и `libz` и задаёт `QT_XCB_GL_INTEGRATION=none`, чтобы графическая оболочка Gowin запускалась в современных дистрибутивах;
- под macOS скрипт добавляет библиотеки Gowin в `DYLD_LIBRARY_PATH` и `DYLD_FRAMEWORK_PATH` и снимает с каталогов Gowin атрибут карантина macOS, из-за которого система блокирует скачанные программы.

Проект загружается в ПЛИС программой `programmer_cli` под Windows и macOS. Под Linux используется `openFPGALoader`, если он установлен, а иначе тоже `programmer_cli`. Под Linux нужно правило udev для адаптера на плате: скопируйте `scripts/fpga/91-sipeed.rules` в `/etc/udev/rules.d` и перезагрузите компьютер, иначе скрипт выдаст ошибку с этой подсказкой.

<a id="sb_4"></a>

### Б.4. OSS CAD Suite

Код: функция `setup_yosys` в [`00_setup_yosys.source_bash`](https://github.com/yuri-panchul/basics-graphics-music/blob/main/scripts/steps/00_setup_yosys.source_bash). Этот маршрут выбирается для конфигураций, имена которых оканчиваются на `_yosys`.

1. Если есть каталог `~/oss-cad-suite`, скрипт подключает его файл `environment`, который добавляет программы сборки в `PATH`.
2. Если есть каталог `~/Downloads/oss-cad-suite`, скрипт подключает и его (на снимках главы 23 OSS CAD Suite лежит именно там). Держите только одну из двух копий, чтобы было ясно, какая используется.
3. Если ни одного каталога нет, используются программы, уже доступные через `PATH`, например установленные менеджером пакетов.

Под macOS скрипт снимает с каталога OSS CAD Suite атрибут карантина. Затем он проверяет, что нужные программы есть, и сообщает об этом строкой *Configuring for … OK*:

| Плата (часть имени) | Нужные программы | Сообщение |
|---|---|---|
| любая | `yosys` | — |
| `ice` (Lattice iCE40) | `nextpnr-ice40`, `icepack` | Configuring for Lattice iCE40... |
| `ecp5` (Lattice ECP5) | `nextpnr-ecp5`, `ecppack` | Configuring for Lattice ECP5... |
| `tang` (Gowin) | `nextpnr-himbaechel`, `gowin_pack` | Configuring for Gowin chips... |

Параметры конкретной ПЛИС (тип, корпус, имя платы для `openFPGALoader`) берутся из файла `board_info.source_bash` в каталоге платы. Загрузка в ПЛИС выполняется командой `openFPGALoader -b <плата>`; для Tang Nano под Linux нужно то же правило udev, что и в разделе Б.3. Скрипт `05` в этом маршруте повторяет синтез и запускает nextpnr с ключом `--gui` (глава 25).

[![Выпуск Школы синтеза цифровых схем, 2025 год.](https://www.panchul.com/bgm_workflow_manual/20261011/image_at_the_end_synthesis_school_graduation_2025.jpg)](https://www.panchul.com/bgm_workflow_manual/20261011/image_at_the_end_synthesis_school_graduation_2025.jpg)
