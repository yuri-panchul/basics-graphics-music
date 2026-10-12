# Поддержка разработки студентами своих вариантов упражнений BGM в рамках Школы Синтеза Цифровых Схем

**Использование Git, GitHub, VS Code с терминалами и маршрутов синтеза для ПЛИС.**

Покрывает маршруты: Xilinx Vivado, Altera Quartus, Gowin EDA и OSS CAD Suite. Покрывает платформы: Windows 10 и 11, Linux и ARM macOS.

Редакция от 11 октября 2026 года. Названия пунктов меню приведены на английском, как на снимках экрана. Нажмите на иллюстрацию, чтобы открыть оригинал.

## Содержание

- [00. Введение](#chapter-00)
- [01. Создание учётной записи GitHub](#chapter-01)
- [02. Создание fork репозитория Школы](#chapter-02)
- [03. Установка Git в Windows, Linux и macOS](#chapter-03)
- [04. Клонирование своего fork](#chapter-04)
- [05. Открытие репозитория в VS Code](#chapter-05)
- [06. Терминал VS Code: профиль оболочки и каталог упражнения](#chapter-06)
- [07. Выбор платы](#chapter-07)
- [08. Синтез для Saylinx с ПЛИС Altera](#chapter-08)
- [09. Изменение упражнения в своей ветке](#chapter-09)
- [10. Сохранение изменений и отправка в свой fork](#chapter-10)
- [11. Credential helper под Linux](#chapter-11)
- [12. Pull request в репозиторий Школы](#chapter-12)
- [13. Получение обновлений без потери своего варианта](#chapter-13)
- [14. Просмотр схемы в Quartus](#chapter-14)
- [15. Синтез для ALINX AX7035B с ПЛИС Xilinx](#chapter-15)
- [16. Просмотр схемы в Xilinx Vivado](#chapter-16)
- [17. Просмотр размещённого проекта в Vivado](#chapter-17)
- [18. Tang Nano 9K с LCD: маршрут Gowin EDA](#chapter-18)
- [19. Схема и отчёты Gowin EDA](#chapter-19)
- [20. Клонирование своего fork на ARM Mac](#chapter-20)
- [21. Открытие проекта в VS Code на ARM Mac](#chapter-21)
- [22. Tang Nano 9K с HDMI на ARM Mac: Gowin EDA](#chapter-22)
- [23. Tang Nano 9K с LCD на ARM Mac: OSS CAD Suite](#chapter-23)
- [24. iCEBreaker с ПЛИС Lattice: OSS CAD Suite](#chapter-24)
- [25. Просмотр размещения в nextpnr](#chapter-25)
- [Приложение А. Минималистичная памятка по Git](#appendix-a)
- [Приложение Б. Как BGM находит маршруты синтеза](#appendix-b)

<a id="chapter-00"></a>

## 00. Введение

Мы решили написать эту инструкцию после того, как преподаватель МЭИ Михаил Графов высказал пожелание, чтобы студенты могли редактировать дома код своих вариантов упражнений из репозитория BGM (Basics, Graphics and Music) и чтобы их редактирование не сбрасывалось при обновлении репозитория. Кроме этого, для развития Школы было бы полезно, чтобы некоторые из разработанных студентами примеров можно было вносить в исходный репозиторий, с минимизацией риска, что эти изменения поломают код для других студентов.

Собственно, именно для этого созданы системы управления версиями и их хостинги: GitHub, GitLab, GitVerse, GitFlic и другие. Репозиторий BGM использует GitHub, в котором есть такие удобные инструменты, как fork и pull request, но не все студенты их знают.

Кроме этого, мы решили показать использование маршрутов синтеза внутри терминалов VS Code, с удобными сочетаниями клавиш, например с использованием Tab для автодополнения. Есть и небольшие различия между платформами. Под Linux и macOS можно открыть терминал правой кнопкой мыши прямо в нужной директории примера: обычно Bash под Linux и Zsh под macOS. В Windows мы рекомендуем создать терминал Git Bash, набрать команду `cd ` с пробелом и перетащить туда директорию примера из проводника VS Code.

Альтернатива такому перетаскиванию в Windows — открыть PowerShell через контекстное меню и использовать `bash ./название_скрипта.bash`. Однако при установленном WSL команда `bash` может запустить другую среду. Тогда Windows-пути, драйверы и окончания строк CRLF могут стать источником ошибок. Ниже показано, как явно выбрать Git Bash.

Мы также решили проиллюстрировать, как увидеть схемы, полученные из кода, в маршрутах синтеза разных производителей, поддерживаемых инфраструктурой BGM.

Эта инструкция не описывает установку САПР ПЛИС. Она рассмотрена в [Инструкции по установке ПО](https://panchul.com/bgm_svh_manual/20261006_draft/claude/manual_ru.html). Там же описаны терминальные программы для связи с платой через UART — их не следует путать с терминалами VS Code, — архитектурный симулятор RARS и инструменты xPack для разработки программ, в том числе для RISC-V. В данном маршруте BGM используется xPack RISC-V GCC; выбор GCC или LLVM относится к конкретному пакету, а не к названию xPack в целом.

В приложение Б мы поместили объяснение того, как скрипты BGM находят установки Vivado, Quartus, Gowin EDA и OSS CAD Suite.

![Занятие с ПЛИС: результат работы студенческого проекта виден на мониторе.](https://www.panchul.com/bgm_workflow_manual/20261011/00_introduction/00_01.jpg)

*Рис. 00.01. Занятие с ПЛИС: результат работы студенческого проекта виден на мониторе.*

### Как устроена работа

**BGM** — набор упражнений на SystemVerilog: от комбинационной логики и последовательностных схем до графики, звука и процессорных примеров. Код упражнения находится в `labs`, интерфейсы конкретных плат — в `boards`, общие периферийные блоки — в `peripherals`, а маршруты запуска — в `scripts`. Благодаря этому один пример можно собирать для разных плат, выбирая соответствующую конфигурацию.

| Понятие | Что это означает в нашей работе |
| --- | --- |
| Репозиторий Школы, upstream | Общая версия, из которой преподаватели раздают упражнения. |
| Fork, origin | Ваша копия репозитория на GitHub, куда вы можете отправлять изменения. |
| Clone | Копия репозитория вместе с историей Git на вашем компьютере. |
| Ветка | Отдельная линия разработки внутри репозитория; для своего варианта создаём `student/hyperbola`. |
| Commit | Сохранённый в Git набор изменений с автором и пояснением. |
| Push | Отправка локальных коммитов на GitHub. |
| Pull request, PR | Предложение включить изменения из вашей ветки в общий репозиторий после проверки. |

Последовательность работы: **fork → clone → своя ветка → правка и проверка → commit → push → pull request**. Обновления преподавателя приходят отдельным действием: **fetch upstream → merge upstream/main в свою ветку**. Сам по себе fork не сохраняет несохранённый текст в редакторе и не отправляет локальные коммиты в интернет.

### Какие главы нужны для вашей платформы

| Маршрут | Windows 10/11 | Linux | ARM macOS | Главы |
| --- | --- | --- | --- | --- |
| Altera Quartus | Git Bash и Windows-установка | Linux-установка | Прямой маршрут здесь не рассматривается | 08, 14 |
| Xilinx Vivado | Git Bash и Windows-установка | Linux-установка | Прямой маршрут здесь не рассматривается | 15–17 |
| Gowin EDA | Windows-установка | Linux-установка | Приложение GowinIDE для ARM Mac, показанное в материалах | 18–19, 22 |
| OSS CAD Suite | Сборка для Windows | Сборка для Linux | Сборка для Darwin ARM64 | 23–25 |

«Покрывает платформы» не означает, что каждый маршрут работает на каждой ОС. В частности, описанный поиск Quartus работает только под Linux и Windows; поиск Vivado на macOS пропускается. Git и редактирование исходников доступны на всех перечисленных платформах. Поддержку конкретной версии САПР и ОС уточняйте в руководстве по установке.

В примерах используем упражнение `labs/2_graphics/2_1_rectangle_ellipse_parabola`. На снимках автор работает в `main`; в тексте добавлена отдельная учебная ветка, чтобы проще сохранять свои варианты и готовить независимые PR. Номера плат в меню со временем меняются: выбирайте **по названию**, а не по номеру на картинке.

<a id="chapter-01"></a>

## 01. Создание учётной записи GitHub

1. Откройте [GitHub](https://github.com/) и нажмите **Sign up**. Если учётная запись уже есть, войдите через **Sign in**.
2. Укажите свою почту, придумайте имя пользователя и пароль. Имя пользователя входит в адрес вашего будущего fork.
3. Подтвердите почту кодом из письма и завершите регистрацию.
4. Войдите и откройте свой профиль. На демонстрационных снимках используется имя `Dmitri-Mendeleev`; в командах ниже `YOUR_LOGIN` нужно заменить своим именем.

![GitHub: начало регистрации через Sign up.](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_01.png)

*Рис. 01.01. GitHub: начало регистрации через Sign up.*
![Форма новой учётной записи. Укажите собственные данные.](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_02.png)

*Рис. 01.02. Форма новой учётной записи. Укажите собственные данные.*
![Подтверждение адреса электронной почты.](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_03.png)

*Рис. 01.03. Подтверждение адреса электронной почты.*
![Вход после завершения регистрации.](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_04.png)

*Рис. 01.04. Вход после завершения регистрации.*
![Профиль пользователя, в котором появится fork.](https://www.panchul.com/bgm_workflow_manual/20261011/01_creating_a_github_account/01_05.png)

*Рис. 01.05. Профиль пользователя, в котором появится fork.*

Пароль для входа в браузере и настройка автора коммитов — разные вещи. Команды `git config user.name` и `user.email` не выполняют вход в GitHub. При отправке через HTTPS удобно использовать вход через браузер с Git Credential Manager; это показано в главе 10.

<a id="chapter-02"></a>

## 02. Создание fork репозитория Школы

1. Откройте [организацию Школы](https://github.com/chipdesignschool), затем [chipdesignschool/basics-graphics-music](https://github.com/chipdesignschool/basics-graphics-music).
2. Нажмите **Fork**. В поле **Owner** выберите себя; имя `basics-graphics-music` можно оставить.
3. Для начала достаточно **Copy the main branch only**. Нажмите **Create fork**.
4. Убедитесь, что в адресе нового репозитория стоит ваше имя: `github.com/YOUR_LOGIN/basics-graphics-music`.
5. Нажмите **Code → HTTPS** и скопируйте адрес клонирования.

![Страница Школы и закреплённый репозиторий BGM.](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_02.png)

*Рис. 02.02. Страница Школы и закреплённый репозиторий BGM.*
![Кнопка Fork в репозитории Школы.](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_03.png)

*Рис. 02.03. Кнопка Fork в репозитории Школы.*
![Создание fork в своей учётной записи.](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_04.png)

*Рис. 02.04. Создание fork в своей учётной записи.*
![Созданный fork: владельцем является пользователь.](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_05.png)

*Рис. 02.05. Созданный fork: владельцем является пользователь.*
![Копирование HTTPS-адреса своего fork.](https://www.panchul.com/bgm_workflow_manual/20261011/02_forking_the_synthesis_school_repo/02_06.png)

*Рис. 02.06. Копирование HTTPS-адреса своего fork.*

Репозиторий Школы сам происходит от [yuri-panchul/basics-graphics-music](https://github.com/yuri-panchul/basics-graphics-music). В этом учебном маршруте **upstream — репозиторий Школы**, и PR адресован ему. Если преподаватель дал другой исходный репозиторий, используйте его согласованно и при создании fork, и при настройке `upstream`, и в поле **base repository** своего PR.

<a id="chapter-03"></a>

## 03. Установка Git в Windows, Linux и macOS

Сначала проверьте наличие Git:

```bash
git --version
```

### Windows 10 и 11

Скачайте [Git for Windows](https://git-scm.com/downloads/win), установите Git Bash и Git Credential Manager. Чтобы Git был виден VS Code, в настройке PATH обычно достаточно **Git from the command line and also from 3rd-party software**. На снимке выбран более широкий вариант **Use Git and optional Unix tools from the Command Prompt**: он добавляет Unix-утилиты в общий PATH и может менять то, какие `find` и `sort` запускаются из Windows-программ. Для работы внутри Git Bash этот широкий вариант не обязателен.

![Официальная страница загрузки Git для Windows. Номер версии на снимке не является требованием.](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_02.png)

*Рис. 03.02. Официальная страница загрузки Git для Windows. Номер версии на снимке не является требованием.*
![Выбор способа добавления Git в PATH; на снимке отмечен вариант с дополнительными Unix-утилитами.](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_03.png)

*Рис. 03.03. Выбор способа добавления Git в PATH; на снимке отмечен вариант с дополнительными Unix-утилитами.*

После установки закройте и заново откройте VS Code, чтобы он получил обновлённое окружение. Для нового клона, с которым вы планируете работать также под Linux/WSL, полезно сохранить в рабочей копии окончания строк LF:

```bash
git clone -c core.autocrlf=false https://github.com/YOUR_LOGIN/basics-graphics-music.git
```

Это вариант команды клонирования из следующей главы: выполняйте одну из них, а не обе. Настройка при клонировании не переписывает уже существующий рабочий каталог. Ошибки с CRLF и выбором Bash разобраны в главе 06.

### Linux

Устанавливайте Git менеджером пакетов своего дистрибутива. Например, в Debian/Ubuntu:

```bash
sudo apt update
sudo apt install git
```

В Fedora и системах с DNF:

```bash
sudo dnf install git
```

![Пример установки Git через apt-get. Команда зависит от дистрибутива.](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_04.png)

*Рис. 03.04. Пример установки Git через apt-get. Команда зависит от дистрибутива.*

### ARM macOS

Если Git уже установлен, повторная установка не нужна. Один из вариантов — [Homebrew](https://brew.sh/), после его установки:

```bash
brew install git
git --version
```

Другие варианты перечислены на [странице Git для macOS](https://git-scm.com/downloads/mac). Сборку FPGA-инструментов выбирайте отдельно для Apple Silicon; установка Git сама по себе их не устанавливает.

![Homebrew — менеджер пакетов, используемый в примере для macOS.](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_05.png)

*Рис. 03.05. Homebrew — менеджер пакетов, используемый в примере для macOS.*
![Страница вариантов установки Git под macOS.](https://www.panchul.com/bgm_workflow_manual/20261011/03_install_git_on_windows_linux_macos/03_06.png)

*Рис. 03.06. Страница вариантов установки Git под macOS.*

<a id="chapter-04"></a>

## 04. Клонирование своего fork

Выберите простой путь без пробелов и специальных символов, например `C:\projects` в Windows или `~/projects` в Linux/macOS. Это помогает избежать ограничений FPGA-инструментов и старых скриптов. Клонирование создаст внутри выбранного каталога директорию `basics-graphics-music`.

В Linux/macOS, а также в Git Bash с рабочим каталогом `~/projects`:

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/YOUR_LOGIN/basics-graphics-music.git
cd basics-graphics-music
git remote -v
```

Если используете Windows-каталог `C:\projects`, первые две команды замените на:

```bash
mkdir -p /c/projects
cd /c/projects
```

В Git Bash `/c` соответствует диску `C:\`. На вашем компьютере имя пользователя и путь могут отличаться от снимка. **Не используйте Download ZIP для этого маршрута:** архив не содержит локальную историю и настройки Git, необходимые для commit, push и merge.

![Команда git clone с адресом пользовательского fork.](https://www.panchul.com/bgm_workflow_manual/20261011/04_cloning_your_forked_repo/04_01.png)

*Рис. 04.01. Команда git clone с адресом пользовательского fork.*
![Клонирование завершилось; приглашение терминала снова доступно.](https://www.panchul.com/bgm_workflow_manual/20261011/04_cloning_your_forked_repo/04_02.png)

*Рис. 04.02. Клонирование завершилось; приглашение терминала снова доступно.*

Внутри клона один раз настройте адрес общего репозитория и автора коммитов:

```bash
git remote add upstream https://github.com/chipdesignschool/basics-graphics-music.git
git config --global user.name "Ваше имя"
git config --global user.email "your-email@example.com"
git remote -v
```

`origin` должен указывать на ваш fork, `upstream` — на Школу. `--global` сохраняет имя автора для всех ваших репозиториев на этом компьютере; без него настройка относится только к текущему клону. Для приватности можно взять адрес `noreply` из настроек электронной почты GitHub. Если `upstream` уже существует, сначала проверьте `git remote -v`; добавлять его второй раз не нужно.

<a id="chapter-05"></a>

## 05. Открытие репозитория в VS Code

1. Запустите VS Code и выберите **File → Open Folder**.
2. Откройте корневую папку `basics-graphics-music`, созданную Git.
3. В проводнике **Explorer** раскройте `labs → 2_graphics → 2_1_rectangle_ellipse_parabola` и откройте `lab_top.sv`.
4. При желании установите расширение **SystemVerilog – Language Support** для подсветки и навигации. **surfer** нужен для просмотра временных диаграмм симуляции; сам синтез выполняют внешние инструменты, а не эти расширения.

![File → Open Folder.](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_02.png)

*Рис. 05.02. File → Open Folder.*
![Выбор корневого каталога клона.](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_03.png)

*Рис. 05.03. Выбор корневого каталога клона.*
![Структура BGM в Explorer.](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_04.png)

*Рис. 05.04. Структура BGM в Explorer.*
![Файл lab_top.sv графического упражнения.](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_05.png)

*Рис. 05.05. Файл lab_top.sv графического упражнения.*
![Открытие панели Extensions.](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_06.png)

*Рис. 05.06. Открытие панели Extensions.*
![Расширения SystemVerilog и surfer, используемые на снимках.](https://www.panchul.com/bgm_workflow_manual/20261011/05_opening_repo_in_vscode/05_07.png)

*Рис. 05.07. Расширения SystemVerilog и surfer, используемые на снимках.*

Редактируйте исходники в каталоге упражнения. Папка `run` предназначена для сгенерированных проектов, отчётов и битовых потоков; скрипты могут очищать и создавать её заново. Свой единственный экземпляр кода и ручные настройки проекта в ней хранить нельзя. Перед повторной генерацией перенесите нужные изменения в исходники или шаблоны вне `run`.

<a id="chapter-06"></a>

## 06. Терминал VS Code: профиль оболочки и каталог упражнения

### Windows: рекомендуемый путь через Git Bash

1. Выберите **Terminal → New Terminal**. Если появилось приглашение `PS C:\...>`, открыт PowerShell.
2. В панели терминала откройте стрелку рядом с **+** и выберите **Git Bash**.
3. Через **Select Default Profile → Git Bash** можно назначить его профилем для новых терминалов. Уже открытый PowerShell от этого не меняется: создайте новый терминал.
4. В Git Bash напечатайте `cd `, включая пробел. Перетащите папку упражнения из Explorer VS Code в терминал и нажмите Enter.
5. Проверьте `pwd` и `ls`: рядом должны быть `lab_top.sv`, `03_synthesize_for_fpga.bash` и другие скрипты упражнения.

![Создание терминала в VS Code.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_01.png)

*Рис. 06.01. Создание терминала в VS Code.*
![Приглашение PowerShell: это ещё не Git Bash.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_02.png)

*Рис. 06.02. Приглашение PowerShell: это ещё не Git Bash.*
![Выбор Git Bash из списка профилей.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_03.png)

*Рис. 06.03. Выбор Git Bash из списка профилей.*
![Введите cd и пробел.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_04.png)

*Рис. 06.04. Введите cd и пробел.*
![Перетащите каталог упражнения в терминал.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_07.png)

*Рис. 06.07. Перетащите каталог упражнения в терминал.*
![VS Code вставил путь как аргумент команды cd.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_08.png)

*Рис. 06.08. VS Code вставил путь как аргумент команды cd.*
![После Enter текущим стал каталог упражнения.](https://www.panchul.com/bgm_workflow_manual/20261011/06_open_terminal_in_vscode_particularly_under_windows__set_term_type__cd_lab/06_09.png)

*Рис. 06.09. После Enter текущим стал каталог упражнения.*

Если терминал находится в корне репозитория, тот же переход можно выполнить без мыши:

```bash
cd labs/2_graphics/2_1_rectangle_ellipse_parabola
pwd
ls
```

Напечатайте `./06`, нажмите **Tab** для дополнения имени, затем **Enter** для запуска. Если совпадений несколько, допишите ещё символы; повторное нажатие Tab может показать варианты. Стрелка вверх возвращает предыдущую команду. Автодополнение не запускает скрипт само по себе.

### Linux и macOS

Нажмите правой кнопкой на каталог упражнения и выберите **Open in Integrated Terminal**. В Linux обычно открывается Bash, в macOS — Zsh. Скрипты BGM начинаются с `#!/usr/bin/env bash`, поэтому команда `./03_synthesize_for_fpga.bash` запускает Bash независимо от того, какая интерактивная оболочка открыта. Не выполняйте внутренние `.source_bash` вручную и не загружайте их командой `source` в Zsh.

### Если всё же используете PowerShell

В PowerShell команда `bash ./03_synthesize_for_fpga.bash` корректна только тогда, когда `bash` — подходящая оболочка. Узнать, какие программы найдены, можно так:

```powershell
Get-Command bash -All
```

Для стандартной установки Git for Windows можно явно указать:

```powershell
& "C:\Program Files\Git\bin\bash.exe" ./03_synthesize_for_fpga.bash
```

Если Git установлен в другом месте, скорректируйте путь. При работе через WSL нужны Linux-инструменты и отдельная настройка доступа к USB; переход в WSL сам по себе не делает Windows-установку САПР Linux-установкой.

Сообщения `bash\r`, `$'\r': command not found` или ошибки около `then` часто указывают на CRLF. В VS Code у проблемного Bash-файла выберите **CRLF → LF** в строке состояния и сохраните его; проверьте также подключаемый файл, названный в ошибке. Не преобразовывайте весь репозиторий вслепую. Для нового клона можно заранее выбрать LF способом из главы 03. О профилях терминала: [документация VS Code](https://code.visualstudio.com/docs/terminal/profiles).

<a id="chapter-07"></a>

## 07. Выбор платы

Из каталога упражнения запустите:

```bash
./06_choose_another_fpga_board.bash
```

1. В первом меню выберите семейство платы. Знак `*` означает, что есть несколько конфигураций.
2. Если появилось второе меню, выберите полное имя нужной конфигурации: тип дисплея, его разрешение, наличие TM1638 и маршрут синтеза должны соответствовать оборудованию.
3. Проверьте строку **FPGA board selected** и сообщение о выбранном инструменте.

![Короткий префикс ./06 перед нажатием Tab.](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_01.png)

*Рис. 07.01. Короткий префикс ./06 перед нажатием Tab.*
![Полное имя скрипта выбора платы.](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_02.png)

*Рис. 07.02. Полное имя скрипта выбора платы.*
![Первый уровень меню: платы сгруппированы по имени.](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_03.png)

*Рис. 07.03. Первый уровень меню: платы сгруппированы по имени.*
![Второй уровень: конфигурации saylinx.](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_04.png)

*Рис. 07.04. Второй уровень: конфигурации saylinx.*
![Выбрана saylinx, создан файл fpga_board_selection и найден Quartus.](https://www.panchul.com/bgm_workflow_manual/20261011/07_selecting_board/07_05.png)

*Рис. 07.05. Выбрана saylinx, создан файл fpga_board_selection и найден Quartus.*

Введите номер и нажмите Enter. `e` или `E` завершает выбор; на втором уровне `b` или `B` возвращает назад. При отмене новая плата не выбирается. Результат сохраняется в `fpga_board_selection` **в корне данного клона**, поэтому выбор действует и при переходе к другим упражнениям в нём.

Суффикс `_yosys` в рассматриваемых конфигурациях означает маршрут OSS CAD Suite; без него Tang Nano обычно собирается Gowin EDA. `_no_tm1638` выбирайте при отсутствии модуля TM1638. LCD 480×272, LCD 800×480 и HDMI — разные конфигурации. После смены платы выполните синтез заново: старый битовый поток относится к прежней конфигурации.

Запускайте `06` из каталога упражнения, как показано выше; результаты в `run` в любом случае будут созданы заново при следующем синтезе. Для хакатонных обёрток возможен отдельный выбор через `hackathon_top.sv`; это специальный маршрут, а не пункт обычного меню.

<a id="chapter-08"></a>

## 08. Синтез для Saylinx с ПЛИС Altera

Подключите питание платы, USB-Blaster/JTAG и монитор к видеовыходу, предусмотренному конфигурацией `saylinx`. Выберите эту конфигурацию и запустите:

```bash
./03_synthesize_for_fpga.bash
```

Скрипт создаёт проект в `run`, запускает Quartus для выбранной микросхемы и **после успешного синтеза автоматически переходит к конфигурированию платы**. На снимках найдена Quartus Lite 23.1 для Cyclone IV E `EP4CE6F17C8`; это пример выбранной совместимой установки, а не обязательная версия для всех плат.

![Запуск маршрута из каталога упражнения.](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_02.png)

*Рис. 08.02. Запуск маршрута из каталога упражнения.*
![Сообщение о выбранных редакции Quartus, версии и микросхеме.](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_03.png)

*Рис. 08.03. Сообщение о выбранных редакции Quartus, версии и микросхеме.*
![Изображение на мониторе после сборки и загрузки исходного примера.](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_05.jpg)

*Рис. 08.05. Изображение на мониторе после сборки и загрузки исходного примера.*

### Если синтез прошёл, но USB-Blaster не обнаружен

На следующем снимке есть **Full Compilation was successful**, затем **cannot detect a USB-Blaster cable**. Это сбой стадии загрузки, а не компиляции SystemVerilog. Проверьте питание, USB-кабель с передачей данных, драйвер/правила доступа и JTAG-подключение. Затем повторите только конфигурирование:

```bash
./04_configure_fpga.bash
```

![Сборка успешна, но кабель программатора не найден.](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_06.png)

*Рис. 08.06. Сборка успешна, но кабель программатора не найден.*
![Повторный запуск только загрузки готового результата.](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_08.png)

*Рис. 08.08. Повторный запуск только загрузки готового результата.*
![Quartus Programmer завершил работу успешно.](https://www.panchul.com/bgm_workflow_manual/20261011/08_running_synthesis_for_saylinx_board_with_altera_fpga/08_09.png)

*Рис. 08.09. Quartus Programmer завершил работу успешно.*

Команда `04` использует существующий результат. После изменения исходника или выбора другой платы сначала нужен `03`. Предупреждения и временные ограничения проверяйте в отчётах; фраза «0 errors» сама по себе не доказывает корректность схемы.

<a id="chapter-09"></a>

## 09. Изменение упражнения в своей ветке

До правки создайте отдельную ветку. Из любого места внутри клона:

```bash
git status
git switch -c student/hyperbola
```

Создание ветки не удаляет существующие незакоммиченные правки. Если вы уже редактировали файл в `main`, сначала сохраните его в редакторе, выполните эти команды и далее фиксируйте изменения в новой ветке. Если ветка уже создана, используйте `git switch student/hyperbola`, не создавайте её повторно.

Откройте `lab_top.sv`. В конце существующего комбинационного блока, после рисования параболы и **перед его `end`**, добавьте фрагмент со снимка:

```systemverilog
if (x * y < 20000)
    green = '1;
else if (y > x)
    red = '1;
else
    blue = '1;
```

Произведение координат задаёт область, ограниченную гиперболой; сравнение `y > x` делит оставшуюся часть по диагонали. Присваивание `'1` заполняет единицами всю ширину соответствующего цветового канала. Фрагмент меняет только один из каналов в каждой ветви, оставляя остальные значения, вычисленные ранее. Поэтому он накладывается на исходную картинку, а не заменяет весь алгоритм тремя одноцветными областями. При других разрядностях координат и разрешениях отдельно проверьте ширину произведения и масштаб константы.

![Добавление фрагмента внутрь существующего комбинационного блока.](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_01.png)

*Рис. 09.01. Добавление фрагмента внутрь существующего комбинационного блока.*
![Белый кружок на вкладке означает несохранённые изменения редактора.](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_02.png)

*Рис. 09.02. Белый кружок на вкладке означает несохранённые изменения редактора.*
![После сохранения кружок исчез; M означает изменение относительно Git.](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_03.png)

*Рис. 09.03. После сохранения кружок исчез; M означает изменение относительно Git.*

Сохраните файл: **Ctrl+S** в Windows/Linux или **Cmd+S** в macOS. Затем повторите `./03_synthesize_for_fpga.bash` и сравните изображение. Если для своей задачи вы меняете последовательностную логику, используйте и предусмотренную упражнением симуляцию `./02_simulate_rtl.bash`; наличие этой команды не заменяет содержательный тест именно вашего изменения.

![Повторная сборка изменённого упражнения.](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_04.jpg)

*Рис. 09.04. Повторная сборка изменённого упражнения.*
![Изменённое изображение на мониторе.](https://www.panchul.com/bgm_workflow_manual/20261011/09_modifying_example/09_05.jpg)

*Рис. 09.05. Изменённое изображение на мониторе.*

Для личного эксперимента допустимо редактировать существующее упражнение в своей ветке. Для включения в общий курс преподаватель может попросить выделить новый вариант в отдельное упражнение с описанием, чтобы сохранить исходную постановку задачи для остальных студентов.

<a id="chapter-10"></a>

## 10. Сохранение изменений и отправка в свой fork

Сначала перейдите в корень репозитория: приведённые ниже пути отсчитываются от него. Проверка из каталога упражнения тоже возможна, но тогда используйте короткое имя `lab_top.sv`.

```bash
cd "$(git rev-parse --show-toplevel)"
git status
git diff
```

`git rev-parse --show-toplevel` печатает корень текущего клона; `$(...)` подставляет его в команду `cd`, кавычки сохраняют путь одним аргументом. В `git diff` зелёным показаны добавленные строки, красным — удалённые. Если открылся постраничный просмотр с `(END)`, нажмите **q**, чтобы вернуться в терминал.

![git status показывает изменённый lab_top.sv. На снимке работа ведётся в main; в нашей последовательности — в student/hyperbola.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_07.png)

*Рис. 10.07. git status показывает изменённый lab_top.sv. На снимке работа ведётся в main; в нашей последовательности — в student/hyperbola.*
![Проверка содержимого изменения через git diff.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_08.png)

*Рис. 10.08. Проверка содержимого изменения через git diff.*

Подготовьте к коммиту только нужный файл, затем проверьте именно подготовленные изменения:

```bash
git add labs/2_graphics/2_1_rectangle_ellipse_parabola/lab_top.sv
git diff --cached
git diff --cached --check
git commit -m "Add hyperbola overlay to graphics lab"
git push -u origin student/hyperbola
```

`git add` выбирает текущую версию файла для коммита. Если после этого вы ещё редактировали его, повторите `git add` перед коммитом. `commit` сохраняет изменения локально; `push` публикует уже созданные коммиты. `-u` задаёт отслеживание удалённой ветки, поэтому следующие отправки этой ветки можно выполнять командой `git push`.

На снимке использовано сокращение `git commit -am ...`: оно включает изменения и удаления **всех уже отслеживаемых файлов**, но не новые файлы. Для учебного PR явный `git add` помогает не отправить посторонние изменения.

![Пример сокращённой команды commit -am из демонстрации.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_09.png)

*Рис. 10.09. Пример сокращённой команды commit -am из демонстрации.*
![Коммит создан локально.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_10.png)

*Рис. 10.10. Коммит создан локально.*
![При первом push Git Credential Manager предлагает вход через браузер.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_11.png)

*Рис. 10.11. При первом push Git Credential Manager предлагает вход через браузер.*
![Вход в GitHub в браузере для подтверждения авторизации.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_12.png)

*Рис. 10.12. Вход в GitHub в браузере для подтверждения авторизации.*
![Страница разрешений Git Credential Manager.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_13.png)

*Рис. 10.13. Страница разрешений Git Credential Manager.*
![Авторизация завершилась; вернитесь в терминал.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_14.png)

*Рис. 10.14. Авторизация завершилась; вернитесь в терминал.*
![Push завершился. Сообщение о недоступном credential-cache относится к ошибочной настройке helper, а не к отправке коммита.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_15.png)

*Рис. 10.15. Push завершился. Сообщение о недоступном credential-cache относится к ошибочной настройке helper, а не к отправке коммита.*
![Изменения появились в fork на GitHub. В нашем маршруте откройте ветку student/hyperbola.](https://www.panchul.com/bgm_workflow_manual/20261011/10_submitting_to_your_forked_repo/10_16.png)

*Рис. 10.16. Изменения появились в fork на GitHub. В нашем маршруте откройте ветку student/hyperbola.*

GitHub не принимает обычный пароль учётной записи вместо токена при HTTPS-аутентификации командного Git. Используйте браузерный вход GCM либо настроенный токен/SSH. Не вставляйте токен в URL клонирования и не записывайте его в исходники. Имя и email автора коммита не являются такими токенами. См. [аутентификацию и хранение учётных данных GitHub](https://docs.github.com/en/get-started/git-basics/caching-your-github-credentials-in-git).

Если push отклонён из-за новых коммитов на сервере, сначала проверьте `git status`, получите изменения `git fetch origin` и объедините их с текущей веткой через `git merge origin/student/hyperbola`. Разрешите возможные конфликты, проверьте код и повторите обычный push. Для этой процедуры принудительный push не нужен.

<a id="chapter-11"></a>

## 11. Credential helper под Linux

Credential helper позволяет не вводить данные доступа при каждом push. Сначала посмотрите действующие настройки и файлы, откуда они взяты:

```bash
git config --show-origin --get-all credential.helper
```

### Постоянное защищённое хранение

Один из вариантов — [Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/install.md). Установите его по инструкции для своей системы. После установки в Linux с графическим хранилищем Secret Service, например GNOME Keyring:

```bash
git-credential-manager configure
git config --global credential.credentialStore secretservice
```

При следующем HTTPS push пройдите предложенный вход. Это требует работающего хранилища Secret Service; для консольной системы выберите другой вариант по [документации хранилищ GCM](https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/credstores.md), например настроенный GPG/pass. Не выбирайте `secretservice` вслепую на сервере без графической сессии.

### Временный кэш в памяти

Если постоянное хранение не нужно, встроенный helper Git под Linux может держать введённый токен в памяти один час:

```bash
git config --local credential.helper 'cache --timeout=3600'
```

Команда выполняется внутри клона. Это не создаёт токен и не открывает браузер: она только кэширует данные, полученные при аутентификации. **3600 секунд — один час**, а не десять; для десяти часов нужно 36000. После истечения тайм-аута или остановки процесса кэша данные придётся ввести снова. Постоянное хранение токенов лучше поручить GCM. См. [git-credential-cache](https://git-scm.com/docs/git-credential-cache).

В Windows на снимке 10_15 этот helper отключён в данной сборке Git. Сначала найдите настройку через `--show-origin`; если именно в локальном `.git/config` осталась показанная выше строка, удалите только её:

```bash
git config --local --unset-all credential.helper '^cache --timeout=3600$'
```

Если строка задана глобально, используйте `--global` вместо `--local`. Не удаляйте все helper без разбора: рабочая настройка GCM должна остаться. Отсутствие соответствующей строки может дать ненулевой код завершения, не означающий порчу репозитория.

<a id="chapter-12"></a>

## 12. Pull request в репозиторий Школы

1. Откройте свой fork на GitHub и выберите ветку `student/hyperbola`.
2. Нажмите **Contribute → Open pull request** либо **Compare & pull request**. При необходимости используйте **compare across forks**.
3. Проверьте направление: **base repository** — `chipdesignschool/basics-graphics-music`, **base** — `main`; **head repository** — ваш fork, **compare** — `student/hyperbola`.
4. В **Files changed** должны быть только нужные исходники и описание. Результаты синтеза, временные файлы, локальные пути и настройки платы другого студента сюда не относятся.
5. Напишите понятный заголовок и описание: что изменилось, зачем, какая плата и версия инструмента использовались, что проверено и что ещё не проверено. Прикрепите фотографию результата, если она помогает проверке.
6. Нажмите **Create pull request**. Если работа пока не готова к включению, выберите **Draft pull request**.

![Fork содержит новый коммит по сравнению с репозиторием Школы.](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_01.png)

*Рис. 12.01. Fork содержит новый коммит по сравнению с репозиторием Школы.*
![Выбор исходной и целевой веток. На снимке compare — main, в нашей последовательности — student/hyperbola.](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_03.png)

*Рис. 12.03. Выбор исходной и целевой веток. На снимке compare — main, в нашей последовательности — student/hyperbola.*
![Проверка конкретного diff перед созданием PR.](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_04.png)

*Рис. 12.04. Проверка конкретного diff перед созданием PR.*
![Заголовок и описание pull request.](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_06.png)

*Рис. 12.06. Заголовок и описание pull request.*
![Кнопка Create pull request. Описание стоит дополнить результатами проверки.](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_07.png)

*Рис. 12.07. Кнопка Create pull request. Описание стоит дополнить результатами проверки.*
![Открытый PR — предложение изменений, которое ещё не включено в общий репозиторий.](https://www.panchul.com/bgm_workflow_manual/20261011/12_opening_pull_request_to_the_parent_repo/12_08.png)

*Рис. 12.08. Открытый PR — предложение изменений, которое ещё не включено в общий репозиторий.*

Сообщение **Able to merge** говорит лишь об отсутствии текстового конфликта. Оно не проверяет правильность SystemVerilog, временные ограничения и работу других плат. Преподаватель может попросить исправления или отдельный вариант упражнения. Дополнительные коммиты и обычный push в ту же ветку автоматически дополняют уже открытый PR. Об устройстве этого процесса: [GitHub — PR из fork](https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/creating-a-pull-request-from-a-fork).

<a id="chapter-13"></a>

## 13. Получение обновлений без потери своего варианта

Главное правило: **перед объединением сохраните файлы и зафиксируйте нужные правки в своей ветке**. Обычный merge объединяет истории; если одни и те же строки изменены с двух сторон, Git просит разрешить конфликт. Удалять свой клон или заменять его свежим ZIP для обновления не нужно.

### Обновление своей учебной ветки через терминал

После commit и push из главы 10 убедитесь, что рабочий каталог чист, затем:

```bash
git status
git switch student/hyperbola
git fetch upstream
git merge upstream/main
```

`fetch` скачивает историю Школы и обновляет локальную ссылку `upstream/main`, не редактируя ваши рабочие файлы. `merge` объединяет эту историю с **текущей** веткой `student/hyperbola`. После успешного объединения выполните проверки упражнения, затем:

```bash
git push origin student/hyperbola
```

Свою `main` можно поддерживать как чистую копию основной ветки Школы. Если в неё не добавлялись собственные коммиты, выполните отдельно:

```bash
git switch main
git fetch origin
git merge --ff-only origin/main
git merge --ff-only upstream/main
git push origin main
git switch student/hyperbola
```

`--ff-only` разрешает только перемещение указателя вперёд без создания слияния. Если команда остановилась из-за расхождения веток, не продолжайте последовательность вслепую и не заменяйте её `reset --hard`: сначала выясните, какие коммиты находятся с каждой стороны. Новую работу удобно начинать отдельной веткой от обновлённой `main`.

### Если вы уже работали в main, как на снимках

Сначала создайте ветку `git switch -c student/hyperbola` от текущего состояния и сохраните в ней изменения. Далее объединяйте `upstream/main` с ней по первой последовательности. Наличие собственных коммитов в прежней `main` не требует их немедленного удаления. Если вам нужно продолжать именно в `main`, обычный `git merge upstream/main` в этой ветке также сохраняет обе истории, но отдельные PR становится сложнее разделять по задачам.

### Если возник конфликт

1. Выполните `git status`: Git перечислит конфликтующие файлы.
2. Откройте их в VS Code. Сравните обе стороны. В этом merge **Current** — ваша учебная ветка, **Incoming** — обновление Школы.
3. Составьте правильный итоговый код, уберите маркеры `<<<<<<<`, `=======`, `>>>>>>>` и сохраните файлы. «Accept Both» не гарантирует правильный SystemVerilog.
4. Проверьте результат, выполните `git add` для разрешённых файлов и `git commit`, чтобы завершить слияние.
5. Повторите симуляцию/синтез для своей платы, затем `git push`.

Пока merge ещё не завершён, команда `git merge --abort` отменяет начатое объединение. Поэтому мы начинали с чистого рабочего каталога: так вернуться к исходному состоянию проще.

### Если правка ещё не готова к коммиту

Временно сохранить отслеживаемые и новые неигнорируемые файлы можно в stash:

```bash
git stash push -u -m "Before upstream update"
git fetch upstream
git merge upstream/main
git stash apply
```

Выполняйте это в своей учебной ветке. После `apply` проверьте результат: здесь тоже возможны конфликты. Команда `apply`, в отличие от `pop`, оставляет запись stash. Удаляйте её через `git stash drop` только после проверки и сохранения правок. Игнорируемые файлы из `run` флаг `-u` не сохраняет; stash остаётся только на этом компьютере и не заменяет push или резервную копию.

### Кнопка Sync fork на GitHub

На странице fork выберите нужную ветку и **Sync fork → Update branch**. Это обновляет **удалённый fork**, а не файлы вашего компьютера. Например, после обновления чистой `main` на сайте получите её локально:

```bash
git switch main
git pull --ff-only origin main
git switch student/hyperbola
git merge main
```

При конфликтах используйте разбор через терминал. **Discard commits** удаляет отличающиеся коммиты выбранной ветки: это не способ сохранить свои варианты. Подробности: [GitHub — синхронизация fork](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/syncing-a-fork).

Если работа на двух компьютерах ведётся в одной учебной ветке, перед началом сохраните местные правки и выполните `git pull --ff-only` в этой ветке. Обновление от `origin` получает вашу работу с другого компьютера, обновление от `upstream` — работу преподавателя. Эти действия решают разные задачи.

<a id="chapter-14"></a>

## 14. Просмотр схемы в Quartus

Вернитесь к конфигурации `saylinx`, если уже переключали плату. Из каталога упражнения запустите:

```bash
./05_run_gui_for_fpga_synthesis.bash
```

В проверенной версии скрипта для Quartus эта команда **заново создаёт проект в `run`**, затем открывает `fpga_project.qpf`. Поэтому результаты прежней командной сборки могут потребовать повторного получения в GUI; предварительно сохраните нужные отчёты вне `run`.

1. Проверьте в **Project Navigator**, что верхний модуль — `board_specific_top` и выбрана правильная микросхема.
2. Запустите **Analysis & Elaboration** либо **Analysis & Synthesis**. На снимках выполнен весь **Compile Design** — для знакомства с RTL Viewer это больше минимально необходимого.
3. В панели **Tasks** раскройте **Analysis & Synthesis → Netlist Viewers → RTL Viewer**. В другой раскладке интерфейса тот же инструмент находится через **Tools → Netlist Viewers → RTL Viewer**.
4. Увеличьте изображение через **Zoom Tool**, найдите блок `lab_top` внутри `board_specific_top` и раскройте его знаком **+**.

![Открытие GUI Quartus через общий скрипт BGM.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_02.png)

*Рис. 14.02. Открытие GUI Quartus через общий скрипт BGM.*
![Сгенерированный проект fpga_project в Quartus.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_03.png)

*Рис. 14.03. Сгенерированный проект fpga_project в Quartus.*
![Панель этапов компиляции.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_04.png)

*Рис. 14.04. Панель этапов компиляции.*
![Завершённая компиляция и Flow Summary.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_06.png)

*Рис. 14.06. Завершённая компиляция и Flow Summary.*
![Сводка использования ресурсов и выбранной микросхемы.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_07.png)

*Рис. 14.07. Сводка использования ресурсов и выбранной микросхемы.*
![Пункт RTL Viewer в дереве задач.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_08.png)

*Рис. 14.08. Пункт RTL Viewer в дереве задач.*
![Общий вид схемы обёртки платы.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_09.png)

*Рис. 14.09. Общий вид схемы обёртки платы.*
![Инструмент увеличения схемы.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_10.png)

*Рис. 14.10. Инструмент увеличения схемы.*
![Блок lab_top, который нужно раскрыть.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_12.png)

*Рис. 14.12. Блок lab_top, который нужно раскрыть.*
![Арифметика, сравнения и мультиплексоры внутри lab_top.](https://www.panchul.com/bgm_workflow_manual/20261011/14_view_elaborated_schematics_in_quartus/14_14.png)

*Рис. 14.14. Арифметика, сравнения и мультиплексоры внутри lab_top.*

Здесь **RTL-схема** — логическое представление кода после раскрытия модулей и параметров. Это ещё не план размещения элементов в кристалле. Найдите умножители и компараторы, соответствующие `x * y < 20000` и `y > x`. Сравните схему с исходником: оператор в программе описывает аппаратную структуру, а не последовательность команд процессора.

### На что смотреть в отчёте

Сравните число логических элементов, регистров и аппаратных умножителей до и после правки. Значения на снимке относятся к конкретной сборке. Сообщения о незаданных временных ограничениях, неподключённых сигналах и несоответствии выводов требуют анализа, даже если компиляция завершилась успешно.

<a id="chapter-15"></a>

## 15. Синтез для ALINX AX7035B с ПЛИС Xilinx

На демонстрационных снимках используется HDMI-вариант `alinx_ax7035b_hdmi_by_codex`, а не базовая конфигурация `alinx_ax7035b`. Подключите плату и монитор согласно README выбранной конфигурации, затем из каталога того же упражнения:

```bash
./06_choose_another_fpga_board.bash
```

В первом меню выберите `alinx_ax7035b`, во втором — `alinx_ax7035b_hdmi_by_codex`. Убедитесь в этом имени в строке **FPGA board selected**, затем:

```bash
./03_synthesize_for_fpga.bash
```

![Первый и второй уровни выбора ALINX AX7035B.](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_02.png)

*Рис. 15.02. Первый и второй уровни выбора ALINX AX7035B.*
![Подтверждение HDMI-конфигурации и запуск синтеза.](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_03.png)

*Рис. 15.03. Подтверждение HDMI-конфигурации и запуск синтеза.*
![Vivado выполнила обращение к аппаратной плате и завершила работу.](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_05.png)

*Рис. 15.05. Vivado выполнила обращение к аппаратной плате и завершила работу.*
![Графическое упражнение на мониторе, подключённом к AX7035B.](https://www.panchul.com/bgm_workflow_manual/20261011/15_running_synthesis_for_alinx_ax7035b_with_xilinx_fpga/15_06.jpg)

*Рис. 15.06. Графическое упражнение на мониторе, подключённом к AX7035B.*

Vivado выполняет синтез, оптимизацию, размещение, трассировку, формирование `.bit`, затем скрипт переходит к загрузке. Если сборка готова, а загрузка не удалась из-за подключения JTAG, после исправления подключения используйте `./04_configure_fpga.bash`.

В `run` сохраняются `post_synth.dcp`, `post_place.dcp`, `post_route.dcp` и отчёты соответствующих стадий. На снимках есть Vivado 2023.2; приложение Б объясняет, почему при нескольких установках может быть выбрана другая версия. Этот маршрут выполняется на Windows/Linux; наличие ARM Mac не превращает его в маршрут для macOS.

<a id="chapter-16"></a>

## 16. Просмотр схемы в Xilinx Vivado

После сборки упражнения выполните:

```bash
./05_run_gui_for_fpga_synthesis.bash
```

Скрипт сначала пытается открыть `run/gui_prj/board_specific_top.xpr`. Если проекта нет, но есть checkpoints, он выбирает первый существующий в порядке `post_route.dcp`, `post_place.dcp`, `post_synth.dcp`. Поэтому интерфейс может сразу показать реализацию, а не окно проекта со всеми пунктами **Flow Navigator**.

1. Если открыт проект, в **Flow Navigator** выберите **RTL Analysis → Open Elaborated Design**.
2. Подтвердите диалог раскрытия проекта, затем откройте **Schematic**.
3. Найдите экземпляр `lab_top` в обёртке платы; у экземпляра может быть префикс, например `i_lab_top`.
4. Раскройте блок знаком **+**, увеличьте интересующий фрагмент и сопоставьте арифметические блоки с кодом упражнения.

![Запуск GUI Vivado.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_02.png)

*Рис. 16.02. Запуск GUI Vivado.*
![Открытый проект board_specific_top.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_04.png)

*Рис. 16.04. Открытый проект board_specific_top.*
![Open Elaborated Design в разделе RTL Analysis.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_05.png)

*Рис. 16.05. Open Elaborated Design в разделе RTL Analysis.*
![Диалог раскрытия RTL-проекта.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_07.png)

*Рис. 16.07. Диалог раскрытия RTL-проекта.*
![Пункт Schematic.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_06.png)

*Рис. 16.06. Пункт Schematic.*
![Схема верхнего уровня.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_08.png)

*Рис. 16.08. Схема верхнего уровня.*
![Выбор экземпляра lab_top.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_09.png)

*Рис. 16.09. Выбор экземпляра lab_top.*
![Раскрытая RTL-схема графического упражнения.](https://www.panchul.com/bgm_workflow_manual/20261011/16_view_schematics_in_xilinx_vivado/16_10.png)

*Рис. 16.10. Раскрытая RTL-схема графического упражнения.*

**Elaborated Design** показывает структуру RTL до технологической оптимизации. **Synthesized Design** показывает результат синтеза; некоторые блоки могут исчезнуть или объединиться. **Implemented Design** содержит размещение и трассировку. Эти представления отвечают на разные вопросы и не обязаны выглядеть одинаково.

Если нужен именно RTL-просмотр, а открыт `.dcp`, откройте существующий `.xpr` через **File → Open Project**. Если его нет, сначала создайте проект обычным `03` для выбранной платы. Не выбирайте пустой проект и не пытайтесь вручную угадывать список общих файлов BGM.

<a id="chapter-17"></a>

## 17. Просмотр размещённого проекта в Vivado

### Из окна проекта

1. Выберите **Generate Bitstream** либо сначала **Run Implementation**.
2. Если Vivado сообщает, что результаты реализации отсутствуют, подтвердите запуск необходимых стадий.
3. В **Launch Runs** выберите разумное число параллельных задач с учётом памяти компьютера. Число 4 на снимке — пример, а не требование.
4. После завершения выберите **Open Implemented Design**.
5. Откройте вкладку **Device**, увеличьте область с занятыми ресурсами, выберите интересующую ячейку или цепь.

![Кнопка Generate Bitstream.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_01.png)

*Рис. 17.01. Кнопка Generate Bitstream.*
![Vivado предлагает сначала выполнить синтез и реализацию.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_02.png)

*Рис. 17.02. Vivado предлагает сначала выполнить синтез и реализацию.*
![Параметры запуска задач.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_03.png)

*Рис. 17.03. Параметры запуска задач.*
![Выбор Open Implemented Design после завершения.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_04.png)

*Рис. 17.04. Выбор Open Implemented Design после завершения.*
![Реализованный проект и сводка временного анализа.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_06.png)

*Рис. 17.06. Реализованный проект и сводка временного анализа.*
![Занятые ресурсы на плане кристалла.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_07.png)

*Рис. 17.07. Занятые ресурсы на плане кристалла.*
![Увеличение области с логическими блоками.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_08.png)

*Рис. 17.08. Увеличение области с логическими блоками.*
![Детальный вид ресурсов внутри выбранных блоков.](https://www.panchul.com/bgm_workflow_manual/20261011/17_view_implemented_design_in_xilinx_vivado/17_09.png)

*Рис. 17.09. Детальный вид ресурсов внутри выбранных блоков.*

### Просмотр уже готового checkpoint

Скриптовая сборка BGM использует прямые Tcl-команды `synth_design`, `place_design`, `route_design`. Обычные GUI-запуски `synth_1` и `impl_1` в сохранённом проекте при этом могут отображаться как **Not started**. Это не означает, что скриптовая сборка не выполнялась.

Чтобы посмотреть именно уже полученный результат без новой сборки, запустите из терминала с доступной командой `vivado`, находясь в каталоге упражнения:

```bash
vivado run/post_route.dcp
```

Это команда оболочки, а не Tcl-консоли Vivado. Если `vivado` был найден только внутри дочернего скрипта BGM, его PATH не переносится обратно в ваш терминал: откройте `post_route.dcp` через **File → Checkpoint → Open** в уже запущенной Vivado либо используйте полный путь к её исполняемому файлу.

Смотрите не только на раскраску кристалла, но и на **Timing Summary**: худший запас setup/hold, число нарушений и наличие unconstrained paths. Положительный запас характеризует только проверенные ограничения, а не автоматически все соединения на плате. Просмотр схемы не требует подключённой платы; подключение нужно для программирования.

<a id="chapter-18"></a>

## 18. Tang Nano 9K с LCD: маршрут Gowin EDA

Для показанной платы подключены LCD 480×272 и TM1638. Выберите `tang_nano_9k`, затем `tang_nano_9k_lcd_480_272_tm1638`:

```bash
./06_choose_another_fpga_board.bash
./03_synthesize_for_fpga.bash
```

Между командами завершите выбор в интерактивном меню. Для панели 800×480 нужен одноимённый вариант с `800_480`; для работы без TM1638 — соответствующий `_no_tm1638`. Плата одна и та же, но её верхний модуль, подключения и временные параметры различаются.

![Выбор LCD 480×272 и TM1638 для Gowin EDA.](https://www.panchul.com/bgm_workflow_manual/20261011/18_running_synthesis_for_tang_nano_9k_lcd_with_gowin_fpga/18_01.png)

*Рис. 18.01. Выбор LCD 480×272 и TM1638 для Gowin EDA.*
![Скрипт сообщает пути к IDE, командному синтезу и программатору Gowin.](https://www.panchul.com/bgm_workflow_manual/20261011/18_running_synthesis_for_tang_nano_9k_lcd_with_gowin_fpga/18_02.png)

*Рис. 18.02. Скрипт сообщает пути к IDE, командному синтезу и программатору Gowin.*
![Сборка и SRAM Program завершились.](https://www.panchul.com/bgm_workflow_manual/20261011/18_running_synthesis_for_tang_nano_9k_lcd_with_gowin_fpga/18_03.png)

*Рис. 18.03. Сборка и SRAM Program завершились.*
![LCD и TM1638 с Tang Nano 9K.](https://www.panchul.com/bgm_workflow_manual/20261011/18_running_synthesis_for_tang_nano_9k_lcd_with_gowin_fpga/18_04.jpg)

*Рис. 18.04. LCD и TM1638 с Tang Nano 9K.*

В Windows и macOS скрипт использует фирменный программатор Gowin. Под Linux он предпочитает `openFPGALoader`, если тот доступен, иначе пробует фирменный программатор. В показанном фирменном маршруте выполняется **SRAM Program**: конфигурация загружается в энергозависимую память ПЛИС. После выключения питания может снова запуститься прежняя конфигурация из flash; это не означает, что исходник не был сохранён в Git.

Подключение модулей берите из описания конкретной платы. Фотография помогает узнать оборудование, но не заменяет распиновку. Разъёмы LCD и внешние модули подключайте при снятом питании.

<a id="chapter-19"></a>

## 19. Схема и отчёты Gowin EDA

После сборки выбранной Gowin-конфигурации выполните:

```bash
./05_run_gui_for_fpga_synthesis.bash
```

Скрипт открывает `fpga_project.gprj`, если он был создан для данной конфигурации. В **Tools → Schematic Viewer → RTL Design Viewer** откройте RTL-представление. Если IDE просит сначала выполнить необходимую стадию анализа/синтеза, запустите её в панели **Process**, затем повторите просмотр.

![Путь Tools → Schematic Viewer → RTL Design Viewer.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_01.png)

*Рис. 19.01. Путь Tools → Schematic Viewer → RTL Design Viewer.*
![Окно RTL Design Viewer.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_02.png)

*Рис. 19.02. Окно RTL Design Viewer.*
![Кнопка увеличения Zoom In.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_03.png)

*Рис. 19.03. Кнопка увеличения Zoom In.*
![Развёрнутая иерархия: lab_top и периферийные модули платы.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_04.png)

*Рис. 19.04. Развёрнутая иерархия: lab_top и периферийные модули платы.*

Раскройте **Modules**, найдите `lab_top` и сопоставьте его с исходником. Модули генерации видеосигнала, TM1638 и аудио принадлежат обёртке платы; они показывают, как одно упражнение подключается к реальным выводам.

### Отчёты в браузере

В VS Code раскройте `run/impl`. В показанной версии Gowin полезны следующие файлы:

| Файл относительно каталога упражнения | Назначение |
| --- | --- |
| `run/impl/gwsynthesis/fpga_project_syn.rpt.html` | Сводка синтеза, ресурсы и предварительный временной анализ. |
| `run/impl/pnr/fpga_project.rpt.html` | Отчёт размещения и трассировки. |
| `run/impl/pnr/fpga_project.tr.html` | Временной анализ результата реализации. |
| `run/impl/pnr/fpga_project.fs` | Битовый поток для загрузки. |

Нажмите правой кнопкой на HTML-отчёте и выберите **Open in Integrated Browser**, если этот пункт есть в вашей версии VS Code. Иначе откройте файл обычным браузером через файловый менеджер. Открытие HTML как текста показывает его разметку, а не оформленный отчёт.

![Открытие отчёта размещения и трассировки в браузере.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_05.png)

*Рис. 19.05. Открытие отчёта размещения и трассировки в браузере.*
![Расположение отчёта синтеза.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_06.png)

*Рис. 19.06. Расположение отчёта синтеза.*
![Использование логики и регистров, перечень тактовых сигналов.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_07.png)

*Рис. 19.07. Использование логики и регистров, перечень тактовых сигналов.*
![Предварительная оценка Fmax и детали пути.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_08.png)

*Рис. 19.08. Предварительная оценка Fmax и детали пути.*
![Выбор отчёта временного анализа после реализации.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_09.png)

*Рис. 19.09. Выбор отчёта временного анализа после реализации.*
![Fmax и суммарные отрицательные запасы setup/hold.](https://www.panchul.com/bgm_workflow_manual/20261011/19_view_elaborated_schematics_in_gowin_eda/19_10.png)

*Рис. 19.10. Fmax и суммарные отрицательные запасы setup/hold.*

Частоты и проценты на снимках относятся к конкретному проекту. Окончательный результат оценивают после размещения и трассировки при правильно заданных ограничениях. Fmax из отчёта синтеза и Fmax после трассировки могут различаться.

<a id="chapter-20"></a>

## 20. Клонирование своего fork на ARM Mac

На втором компьютере заново fork создавать не нужно: используйте тот же репозиторий GitHub, куда уже отправлена ваша работа.

1. На первом компьютере завершите нужные коммиты и push. Несохранённые файлы, stash и локальные ветки без push на Mac не появятся.
2. На Mac откройте свой fork в браузере и скопируйте **Code → HTTPS**.
3. Откройте приложение **Terminal**, выберите каталог для клона и выполните клонирование.

```bash
cd ~
git clone https://github.com/YOUR_LOGIN/basics-graphics-music.git
cd basics-graphics-music
git switch --track origin/student/hyperbola
git remote add upstream https://github.com/chipdesignschool/basics-graphics-music.git
```

Команда `--track` предполагает, что ветка `student/hyperbola` уже опубликована, а локальной одноимённой ветки в новом клоне ещё нет. В существующем клоне сначала выполните `git fetch origin`, затем переключитесь на уже созданную ветку. Если вы следовали снимкам и отправляли изменения в `main`, они будут в `main`; не ищите несуществующую учебную ветку.

![Открытие того же профиля GitHub на Mac.](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_01.png)

*Рис. 20.01. Открытие того же профиля GitHub на Mac.*
![В fork уже виден коммит, сделанный на другом компьютере.](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_02.png)

*Рис. 20.02. В fork уже виден коммит, сделанный на другом компьютере.*
![Копирование адреса клонирования.](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_03.png)

*Рис. 20.03. Копирование адреса клонирования.*
![Приложение Terminal в macOS.](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_05.png)

*Рис. 20.05. Приложение Terminal в macOS.*
![Команда клонирования из домашнего каталога.](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_06.png)

*Рис. 20.06. Команда клонирования из домашнего каталога.*
![Завершение клонирования.](https://www.panchul.com/bgm_workflow_manual/20261011/20_cloning_your_forked_repo_on_apple_mac_arm/20_07.png)

*Рис. 20.07. Завершение клонирования.*

На новом компьютере отдельно настройте `user.name`, `user.email` и аутентификацию. Домашний путь macOS обычно начинается с `/Users`, в Linux — с `/home`; сами команды Git от этого не меняются.

<a id="chapter-21"></a>

## 21. Открытие проекта в VS Code на ARM Mac

1. Выберите **File → Open Folder** и откройте свой новый клон.
2. Проверьте имя активной ветки в строке состояния или командой `git branch --show-current`.
3. Откройте `labs/2_graphics/2_1_rectangle_ellipse_parabola/lab_top.sv` и убедитесь, что ваша правка присутствует.
4. Установите нужные расширения через **Extensions**. На снимках — SystemVerilog и surfer.
5. Через **Open in Integrated Terminal** откройте терминал в каталоге упражнения. В приглашении может стоять `%`: это обычный Zsh в macOS.

![File → Open Folder на macOS.](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_02.png)

*Рис. 21.02. File → Open Folder на macOS.*
![Выбор каталога клона.](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_03.png)

*Рис. 21.03. Выбор каталога клона.*
![Открытый репозиторий в Explorer.](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_04.png)

*Рис. 21.04. Открытый репозиторий в Explorer.*
![Поиск расширения surfer.](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_06.png)

*Рис. 21.06. Поиск расширения surfer.*
![Диалог доверия издателю расширения.](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_07.png)

*Рис. 21.07. Диалог доверия издателю расширения.*
![Установленные расширения.](https://www.panchul.com/bgm_workflow_manual/20261011/21_opening_repo_in_vscode_on_apple_mac_arm/21_08.png)

*Рис. 21.08. Установленные расширения.*

Внешние САПР и расширения VS Code устанавливаются отдельно. Для следующих глав требуются GowinIDE для ARM macOS и/или OSS CAD Suite для Darwin ARM64, подготовленные по инструкции установки. Поиск приложений в скриптах разобран в приложении Б.

<a id="chapter-22"></a>

## 22. Tang Nano 9K с HDMI на ARM Mac: Gowin EDA

Материалы этой главы показывают фирменный Gowin EDA, найденный внутри `/Applications/GowinIDE.app`, и загрузку через фирменный программатор. Это конкретный рабочий маршрут ARM macOS; переносить сюда предположения о старых версиях Gowin только для Windows/Linux не нужно.

1. В Explorer откройте терминал в каталоге упражнения.
2. Запустите `./06_choose_another_fpga_board.bash`.
3. Выберите `tang_nano_9k`, затем **`tang_nano_9k_hdmi_tm1638`**. В демонстрации подключён TM1638; для другой комплектации выбирайте соответствующий вариант.
4. Проверьте найденные пути `GOWIN_VERSION_DIR`, `gw_sh`, `gw_ide` и `programmer_cli`.
5. Запустите `./03_synthesize_for_fpga.bash` и дождитесь завершения сборки и **SRAM Program**.

![Open in Integrated Terminal из Explorer macOS.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_01.png)

*Рис. 22.01. Open in Integrated Terminal из Explorer macOS.*
![Исходник и терминал Zsh в одном окне.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_02.png)

*Рис. 22.02. Исходник и терминал Zsh в одном окне.*
![Вызов выбора платы.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_04.png)

*Рис. 22.04. Вызов выбора платы.*
![Выбор tang_nano_9k_hdmi_tm1638.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_06.png)

*Рис. 22.06. Выбор tang_nano_9k_hdmi_tm1638.*
![Найдена установка GowinIDE.app в /Applications.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_07.png)

*Рис. 22.07. Найдена установка GowinIDE.app в /Applications.*
![Запуск синтеза.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_08.png)

*Рис. 22.08. Запуск синтеза.*
![Фирменный программатор завершил SRAM Program.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_09.png)

*Рис. 22.09. Фирменный программатор завершил SRAM Program.*
![HDMI-изображение от Tang Nano 9K и подключённый TM1638.](https://www.panchul.com/bgm_workflow_manual/20261011/22_running_synthesis_for_tang_nano_9k_hdmi_with_gowin_fpga_using_gowin_eda/22_10.jpg)

*Рис. 22.10. HDMI-изображение от Tang Nano 9K и подключённый TM1638.*

При запросе macOS о запуске скачанного ПО следуйте инструкции установки для доверенного пакета. Если скрипт остановился на выборе **Abort, Retry, Ignore** из-за quarantine, исправьте причину и используйте **Retry**; **Ignore** не устраняет блокировку. Не меняйте исполняемые файлы Windows/Linux местами с содержимым приложения для macOS.

<a id="chapter-23"></a>

## 23. Tang Nano 9K с LCD на ARM Mac: OSS CAD Suite

**Уточнение исходных материалов.** В имени папки этой главы написано «HDMI», но на снимках 23_02 и 23_03 выбрана **`tang_nano_9k_lcd_480_272_tm1638_yosys`**. В проверенном наборе плат нет `tang_nano_9k_hdmi_tm1638_yosys`. Поэтому здесь описан именно показанный LCD-маршрут. Для HDMI используйте главу 22; добавление суффикса к имени конфигурации не создаёт отсутствующую поддержку.

1. Подключите LCD 480×272 и TM1638 согласно конфигурации, сняв питание перед переподключением.
2. Выполните `./06_choose_another_fpga_board.bash`.
3. Выберите `tang_nano_9k_lcd_480_272_tm1638_yosys`, затем проверьте сообщение **Configuring for Gowin chips... OK**.
4. Выполните `./03_synthesize_for_fpga.bash`.

![Выбран вариант LCD с суффиксом _yosys, а не HDMI.](https://www.panchul.com/bgm_workflow_manual/20261011/23_running_synthesis_for_tang_nano_9k_hdmi_with_giwin_fpga_using_oss_cad_suite/23_02.png)

*Рис. 23.02. Выбран вариант LCD с суффиксом _yosys, а не HDMI.*
![Подтверждение конфигурации и проверка открытых инструментов.](https://www.panchul.com/bgm_workflow_manual/20261011/23_running_synthesis_for_tang_nano_9k_hdmi_with_giwin_fpga_using_oss_cad_suite/23_03.png)

*Рис. 23.03. Подтверждение конфигурации и проверка открытых инструментов.*
![Запуск синтеза через общий скрипт.](https://www.panchul.com/bgm_workflow_manual/20261011/23_running_synthesis_for_tang_nano_9k_hdmi_with_giwin_fpga_using_oss_cad_suite/23_04.png)

*Рис. 23.04. Запуск синтеза через общий скрипт.*
![Завершение nextpnr, упаковка bitstream.fs и загрузка SRAM с успешной проверкой CRC.](https://www.panchul.com/bgm_workflow_manual/20261011/23_running_synthesis_for_tang_nano_9k_hdmi_with_giwin_fpga_using_oss_cad_suite/23_05.png)

*Рис. 23.05. Завершение nextpnr, упаковка bitstream.fs и загрузка SRAM с успешной проверкой CRC.*

Здесь **Yosys** синтезирует логику, **nextpnr-himbaechel** размещает и трассирует её для Gowin, **gowin_pack** из Apicula формирует `bitstream.fs`, а **openFPGALoader** загружает результат. Выбор `_yosys` меняет весь маршрут, а не только программу просмотра схемы.

На снимке предупреждения об отсутствии Numpy, Msgspec и fastcrc сообщают о снижении производительности Python-компонентов. Данная сборка после них завершила загрузку с **CRC check: Success**. Это не повод считать любые предупреждения безвредными: проверяйте текст и итог каждой стадии. Комплект инструментов и поддерживаемые платформы: [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build).

<a id="chapter-24"></a>

## 24. iCEBreaker с ПЛИС Lattice: OSS CAD Suite

На снимках используется конфигурация **`icebreaker_dvi_24b_tm1638_yosys`** с внешним DVI-видеомодулем и TM1638. Голая плата без соответствующего видеомодуля не выдаст показанную картинку только за счёт выбора этого имени.

```bash
./06_choose_another_fpga_board.bash
```

Выберите `icebreaker`, затем `icebreaker_dvi_24b_tm1638_yosys`. Разновидности `12b`, `24b`, `no_dvi` и `no_tm1638` выбирают разные подключения и комплектацию. После сообщения **Configuring for Lattice iCE40... OK**:

```bash
./03_synthesize_for_fpga.bash
```

![Выбор семейства icebreaker.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_02.png)

*Рис. 24.02. Выбор семейства icebreaker.*
![Второй уровень меню с вариантами DVI и TM1638.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_03.png)

*Рис. 24.03. Второй уровень меню с вариантами DVI и TM1638.*
![Подтверждён вариант DVI 24b с TM1638.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_04.png)

*Рис. 24.04. Подтверждён вариант DVI 24b с TM1638.*
![Запуск синтеза.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_06.png)

*Рис. 24.06. Запуск синтеза.*
![Загрузка на iCEBreaker: в данном маршруте журнал показывает стирание и запись flash.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_07.png)

*Рис. 24.07. Загрузка на iCEBreaker: в данном маршруте журнал показывает стирание и запись flash.*
![Результат упражнения на мониторе.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_08.jpg)

*Рис. 24.08. Результат упражнения на мониторе.*
![Плата iCEBreaker, видеомодуль и TM1638 крупным планом.](https://www.panchul.com/bgm_workflow_manual/20261011/24_running_synthesis_for_ice_breaker_with_lattice_fpga_using_oss_cad_suite/24_09.jpg)

*Рис. 24.09. Плата iCEBreaker, видеомодуль и TM1638 крупным планом.*

Для iCE40 используются Yosys, **nextpnr-ice40**, **icepack**, **icetime** и openFPGALoader. Здесь загрузка на снимке записывает flash, в отличие от показанной SRAM-загрузки Tang Nano. Не предполагайте, что все платы одинаково сохраняют конфигурацию после выключения питания.

Видеомодуль формирует цифровой видеосигнал; наличие HDMI-совместимого разъёма или кабеля не означает автоматическую передачу звука по HDMI. Пользуйтесь схемой и README именно выбранного комплекта.

<a id="chapter-25"></a>

## 25. Просмотр размещения в nextpnr

Оставив выбранной `icebreaker_dvi_24b_tm1638_yosys`, после создания файлов проекта запустите:

```bash
./05_run_gui_for_fpga_synthesis.bash
```

В маршруте Yosys этот скрипт устанавливает `GUI_OPT=--gui` и повторно выполняет сгенерированный `synth.source_bash`: сначала Yosys, затем nextpnr с графическим интерфейсом. **Он не открывает автоматически сохранённую картинку предыдущего размещения.**

1. Дождитесь окна **nextpnr-ice40**. Проверьте устройство: на снимке `iCE40UP5K (sg48)`.
2. Если видна только сетка ресурсов, выполните упаковку, размещение и трассировку через команды GUI **Pack**, **Place**, **Route**; подписи можно посмотреть во всплывающих подсказках панели инструментов. Доступность следующего этапа зависит от завершения предыдущего.
3. Увеличьте вид устройства и выбирайте объекты в **Cells**, **Nets**, **Wires**, **Pips**. Ячейки показывают занятые ресурсы, цепи и переключатели — соединения между ними.
4. Проверьте сообщения в консоли и временной отчёт. Если процесс остановился, сначала прочитайте первую ошибку, а не оценивайте только вид сетки.

![Запуск GUI через скрипт BGM.](https://www.panchul.com/bgm_workflow_manual/20261011/25_view_implemented_design_in_oss_cad_suite_nextpnr/25_02.png)

*Рис. 25.02. Запуск GUI через скрипт BGM.*
![Окно nextpnr-ice40 с видом устройства и списками ресурсов. Этот снимок сам по себе ещё не подтверждает завершённую трассировку.](https://www.panchul.com/bgm_workflow_manual/20261011/25_view_implemented_design_in_oss_cad_suite_nextpnr/25_03.png)

*Рис. 25.03. Окно nextpnr-ice40 с видом устройства и списками ресурсов. Этот снимок сам по себе ещё не подтверждает завершённую трассировку.*

Для GUI нужна сборка nextpnr с поддержкой графического интерфейса. Если `--gui` не поддерживается, используйте подходящую сборку или изучайте отчёты командного маршрута. Назначение nextpnr и варианты архитектур описаны в [репозитории проекта](https://github.com/YosysHQ/nextpnr).

Закрытие GUI позволяет запущенному скрипту продолжить команды упаковки битового потока. Команда `05` сама по себе не вызывает общий шаг `04` программирования платы. Для новой загрузки надёжнее снова использовать обычный маршрут `03`, либо `04`, когда известно, что готовый битовый поток относится к нужным исходникам и конфигурации.

<a id="appendix-a"></a>

## Приложение А. Минималистичная памятка по Git

Автор исходной памятки — **Юрий Панчул**. Ниже приведён русский перевод [A Minimalistic Git Cheat Sheet](https://github.com/yuri-panchul/basics-graphics-music/blob/main/git_cheat_sheet.md), редакция от 28 августа 2026 года. Сохранены её структура и примеры команд; уточнения, связанные с нынешней аутентификацией GitHub, безопасностью удаления файлов и переносимостью команд, явно отмечены как примечания. Загруженный исходник совпал с файлом в проверенном снимке BGM.

### А.1. В начале работы

**1.1. Настройте имя и электронную почту**

```bash
git config --global user.name "Your Name"
git config --global user.email your@email.com
```

Подставьте собственные данные. Эти значения станут авторскими реквизитами коммитов.

**1.2. Настройте кэширование данных доступа**

```bash
git config credential.helper 'cache --timeout=3600'
```

Без helper при каждой отправке Git может снова спрашивать данные доступа. Тайм-аут задаётся в секундах; после его истечения ввод потребуется повторить.

**Примечание к переводу.** В оригинале ошибочно сказано «10 часов»: 3600 секунд — **1 час**, 10 часов — 36000 секунд. Для GitHub вместо обычного пароля при HTTPS нужен токен либо браузерная авторизация через GCM. Команда выше настраивает текущий репозиторий и подходит для временного кэша под Linux; варианты постоянного хранения и особенность Windows рассмотрены в главе 11.

**1.3. Клонируйте репозиторий с GitHub**

```bash
git clone https://github.com/yuri-panchul/basics-graphics-music
```

**Примечание.** Это адрес из оригинальной памятки. Для учебного процесса с правом push клонируйте **свой fork**, как в главе 04.

### А.2. Цикл разработки

**2.1. Получите изменения, сделанные другими участниками**

```bash
git pull
```

**Примечание.** Команда работает с удалённой веткой, которую отслеживает текущая локальная ветка. Она не обязательно получает изменения из репозитория Школы. Для разделения `origin` и `upstream` используйте главу 13. При чистом рабочем каталоге `git pull --ff-only` удобен тем, что останавливается при расхождении историй.

**2.2. Добавьте новые файлы или каталоги, включая их содержимое**

```bash
git add file_or_directory_name
```

**2.3. Отредактируйте файлы**

После редактирования снова выполните `git add`, если требуется обновить подготовленную к коммиту версию.

**2.4. Проверьте состояние перед коммитом**

Обратите внимание на изменённые, добавленные и удалённые файлы. Проверьте, не забыли ли вы добавить нужные новые файлы.

```bash
git status
```

**2.5. Просмотрите различия и проверьте свои изменения в коде**

```bash
git diff
```

**Примечание.** Без аргументов эта команда показывает изменения рабочей копии относительно индекса. Подготовленные изменения смотрите через `git diff --cached`, оба вида изменений отслеживаемых файлов относительно последнего коммита — через `git diff HEAD`. Содержимое новых неотслеживаемых файлов обычный `git diff` не показывает.

**2.6. Не добавляйте в текст табуляции без необходимости**

Разные редакторы отображают табуляцию по-разному. Чтобы прочитать исходник, участник не должен сначала подбирать ширину табуляции. Есть исключения, прежде всего Makefile. Команда поиска из оригинальной памятки:

```bash
grep -rlI --exclude-dir=.git --exclude='*.mk' $'\t' .
```

`-r` означает рекурсивный поиск, `-l` — вывод имён файлов, `-I` — пропуск двоичных файлов. В Bash `$'\t'` обозначает символ табуляции. Оригинал предлагает такую массовую замену, после которой обязательно нужно просмотреть diff:

```bash
grep -rlI --exclude-dir=.git --exclude='*.mk' $'\t' . | xargs sed -i 's/\t/    /g'
```

**Примечание о применимости.** Последнюю команду не следует запускать по всему BGM без проверки списка. Она рассчитана на GNU-подобные утилиты, плохо обрабатывает имена с пробелами и исключает только `*.mk`, но не файл с именем `Makefile`. В macOS синтаксис `sed -i` отличается. Практичнее найти табуляции в изменённых исходниках и исправить их редактором; табуляции в командах Makefile могут быть обязательными. Просмотр без изменения файлов, ограниченный текстовыми исходниками под Git:

```bash
git grep -n -I $'\t' -- '*.sv' '*.svh' '*.v' '*.bash' '*.source_bash'
```

**2.7. Отмена незакоммиченных правок в файле или каталоге**

В оригинале указано `git checkout file_or_directory_name`. Однозначная запись с разделителем пути:

```bash
git checkout -- file_or_directory_name
```

**Примечание.** Это разрушительная для выбранных правок операция: рабочий файл восстанавливается **из индекса**, который может уже содержать подготовленные изменения. Современная запись — `git restore -- file_or_directory_name`. До отмены проверьте diff или сохраните копию.

**2.8. Отмена таких правок для файлов текущего каталога и его подкаталогов, включая удаления**

```bash
git checkout -- .
```

В оригинале — `git checkout .`; смысл тот же, если путь распознан однозначно. Команда не является универсальным «отменить всё»: она не удаляет неотслеживаемые файлы и не отменяет подготовленные изменения в индексе. Если вы выполнили `git add` удаления, действовать нужно с пониманием состояния индекса.

**2.9. Для отмены уже закоммиченных или отправленных изменений обратитесь к опытному пользователю Git либо внимательно прочитайте документацию**

Не выполняйте команды переписывания истории, пока не понимаете их результат. Для общей истории часто подходит новый отменяющий коммит через `git revert`; случай со слияниями требует отдельного разбора.

**2.10. Завершив редактирование, сделайте коммит**

Опция `-a` автоматически подготавливает изменения и удаления уже отслеживаемых файлов, но не новые файлы. Для новых файлов и каталогов нужен явный `git add`.

Перед каждым коммитом выполните `git status` и `git diff`. Отменить закоммиченное, особенно уже опубликованное, сложнее, чем исправить правку до коммита. Пишите содержательное пояснение.

```bash
git commit -am "A meaningful comment"
```

**2.11. Опубликуйте коммиты в удалённом репозитории, например GitHub**

```bash
git push
```

В публичном репозитории опубликованные изменения доступны другим пользователям. Для первого push новой ветки удобно `git push -u origin имя_ветки`.

### А.3. Другие приёмы

**3.1. Историю репозитория можно просматривать через браузер на GitHub**

Локальный краткий просмотр:

```bash
git log --oneline --graph --decorate -20
```

**3.2. Файлы, которые нужно игнорировать, перечисляются в `.gitignore`**

Обычно это автоматически создаваемые двоичные файлы, временные данные и посторонние файлы, которые не должны попадать в коммиты или отвлекать в `git status`. Перед правкой изучите правила `.gitignore`.

**Примечание.** Добавление имени в `.gitignore` не прекращает отслеживание уже закоммиченного файла. Собственные исходники упражнения нельзя скрывать там вместо их сохранения в Git. Для локального исключения, которое не надо предлагать всему курсу, существует `.git/info/exclude`.

**3.3. Просмотр неотслеживаемых файлов в текущем каталоге и ниже**

```bash
git clean -dn
```

Это только предварительный просмотр. После внимательной проверки оригинальная памятка предлагает удалить перечисленное командой:

```bash
git clean -df
```

**Осторожно.** Так можно удалить ещё не добавленное в Git новое упражнение. Сначала сохраните нужные файлы; Git обычно не сможет восстановить неотслеживаемый файл, которого никогда не было в коммите.

**3.4. Просмотр и очистка с учётом игнорируемых файлов**

Для порядка, особенно перед подготовкой пакета, иногда требуется убрать сгенерированные файлы. Команда из оригинала для предварительного просмотра:

```bash
git clean -dxn
```

После проверки удаление выполняет:

```bash
git clean -dxf
```

**Уточнение.** Строчная `-x` включает **все неотслеживаемые файлы**, в том числе игнорируемые; это не список только игнорируемых. Для просмотра только игнорируемых есть `git clean -dXn` с заглавной `X`. Даже игнорируемый файл может содержать нужную вам локальную работу или настройки. Подробности: [git-clean](https://git-scm.com/docs/git-clean).

**3.5. Перед нетривиальными действиями, например слиянием и отменой опубликованных коммитов, внимательно прочитайте документацию Git**

Иначе можно внести ошибки, запутать историю или случайно добавить большие двоичные файлы. [Документация Git](https://git-scm.com/docs) и конкретный рабочий пример слияния в главе 13 помогут выбрать подходящую операцию.

### А.4. Дополнения для учебной работы BGM

| Задача | Команда | Что произойдёт |
| --- | --- | --- |
| Увидеть текущую ветку | `git branch --show-current` | Покажет, куда попадёт следующий commit. |
| Создать ветку для задачи | `git switch -c student/my-variant` | Начнёт отдельную линию разработки от текущего коммита. |
| Проверить адреса | `git remote -v` | Поможет отличить свой fork от репозитория Школы. |
| Посмотреть подготовленное | `git diff --cached` | Покажет содержимое будущего коммита. |
| Убрать файл из подготовки | `git restore --staged -- path/to/file` | Уберёт изменение из индекса, сохранив рабочую копию. |
| Посмотреть состав PR | `git diff upstream/main...HEAD` | Покажет изменения от общего предка с upstream/main до текущей ветки; перед этим выполните fetch. |
| Проверить пробельные ошибки | `git diff --cached --check` | Проверит подготовленный diff, не компилируя код. |

Разделяйте **сохранение в редакторе**, **commit** и **push**. Только последнее действие переносит закоммиченную работу на сервер. Git сохраняет историю исходников, но не заменяет проверку схемы, тесты и резервные копии данных вне репозитория.

<a id="appendix-b"></a>

## Приложение Б. Как BGM находит маршруты синтеза

Разбор ниже относится к скриптам BGM в снимке основной ветки [991a4b32b4a3ad154cea262803911af28827c8c6](https://github.com/yuri-panchul/basics-graphics-music/tree/991a4b32b4a3ad154cea262803911af28827c8c6/scripts/steps), соответствующем базе демонстрации. Это описание фактического алгоритма, а не обещание одинакового поведения всех будущих версий.

Сначала BGM определяет плату и её конфигурацию. Затем общий `00_setup.source_bash` выбирает маршрут и вызывает соответствующую функцию поиска. Пользователь запускает обычные `03`, `04`, `05`, `06`; внутренние `00_setup_*.source_bash` отдельно запускать не нужно.

**PATH** — упорядоченный список каталогов, в которых оболочка ищет команды. Переменная окружения, экспортированная в терминале, передаётся запущенному скрипту. Настройка, которую дочерний скрипт сделал внутри себя, обратно в родительский терминал не возвращается. Поэтому Vivado может находиться при запуске `03`, но команда `vivado` в исходном терминале без настройки PATH всё ещё может быть недоступна.

| Маршрут | Явный путь к установке | Указание родительского каталога | Как сравниваются найденные версии |
| --- | --- | --- | --- |
| Vivado | `XILINX_VIVADO` — каталог, содержащий `bin` | `XILINX_HOME` — родитель `Xilinx`, `AMD`, `AMDDesignTools` | Численно-подобная сортировка версий в первом подходящем родителе; запасной вариант — алфавитный. |
| Quartus | `QUARTUS_ROOTDIR` — каталог `quartus` | `INTEL_FPGA_HOME`, `ALTERA_HOME`, `QUARTUS_HOME` | Сначала совместимость с выбранной микросхемой, затем предпочтение редакции и числовое сравнение в текущей группе кандидатов. |
| Gowin EDA | `GOWIN_VERSION_DIR` — корень с `IDE` и `Programmer` | `GOWIN_HOME` | Первый подходящий родитель; внутри проверяемого каталога используется обычный sort. |
| OSS CAD Suite | Отдельного override в `setup_yosys` нет | Два фиксированных места плюс существующий PATH | Числового сравнения версий нет; загружаются найденные environment-файлы. |

<a id="appendix-b1"></a>

### Б.1. Xilinx Vivado

Источник: [00_setup_xilinx.source_bash](https://github.com/yuri-panchul/basics-graphics-music/blob/991a4b32b4a3ad154cea262803911af28827c8c6/scripts/steps/00_setup_xilinx.source_bash).

Алгоритм по шагам:

1. На поддерживаемых здесь платформах Linux, Cygwin и MSYS проверяется `XILINX_VIVADO`. Если внутри есть каталог `bin`, его добавляют в конец PATH и поиск завершается. Некорректный путь вызывает предупреждение и переход к следующим вариантам.
2. Если команда `vivado` уже доступна в PATH, поиск завершается. Это может быть как установка, настроенная заранее, так и доступная команда-обёртка.
3. Если задан `XILINX_HOME`, сначала просматривается он. Далее Linux проверяет `$HOME`, `/opt`, `/tools`; Windows — `/c`, `/d`, `/e`, соответствующие дискам **C:\, D:\ и E:\** в Git Bash/MSYS. Для иной разметки дисков в Cygwin задайте подходящий родитель явно.
4. В каждом родителе проверяются каталоги поставщика `Xilinx`, `AMD`, `AMDDesignTools` и **оба** формата: `<parent>/<vendor>/Vivado/<version>/bin` и `<parent>/<vendor>/<version>/Vivado/bin`. Именем версии считается имя, начинающееся с цифры.
5. Как только в одном родителе найдены кандидаты, более поздние родители уже не просматриваются. Внутри этого родителя выбирается старшая версия среди всех трёх имён поставщика и обоих форматов.
6. При одинаковой версии выигрывает лексикографически последний полный путь в локали `C`. Выбранный путь записывается в `XILINX_VIVADO`, его `bin` добавляется в конец PATH. При нескольких кандидатах скрипт предупреждает и печатает выбор.

Например, если Vivado 2024.2 находится в `$HOME/Xilinx/Vivado/2024.2`, а 2026.1 — в `/opt/AMD/2026.1/Vivado`, без других настроек победит установка в `$HOME`. Более новая версия из `/opt` не сравнивается с первым подходящим родителем.

Для сортировки функция `xilinx_sort_discovery` пробует `/usr/bin/sort`, `/bin/sort`, затем `sort` из PATH. Она проверяет не просто имя команды, а поддержку сортировки версий: `2026.2` должна идти раньше `2026.10`. Если подходящий Unix sort не найден, используется `sort` из PATH без опций, с предупреждением, что алфавитный порядок может выбрать более старую версию. Это важно при наличии Windows `sort.exe`.

Пример явного выбора в Linux:

```bash
export XILINX_VIVADO="$HOME/AMD/2026.1/Vivado"
export PATH="$XILINX_VIVADO/bin:$PATH"
./03_synthesize_for_fpga.bash
```

**Почему здесь PATH задан отдельно?** В текущем скрипте `bin` добавляется в конец PATH. Если другая команда `vivado` уже стоит раньше, одно только `XILINX_VIVADO` не гарантирует запуск нужного исполняемого файла. В примере выбранный `bin` поставлен в начало. Проверить терминал можно командой `command -v vivado`.

Пример родителя для автоматического поиска:

```bash
export XILINX_HOME=/tools
./03_synthesize_for_fpga.bash
```

Здесь ожидаются, например, `/tools/Xilinx/Vivado/2024.2` или `/tools/AMD/2026.1/Vivado`. Автоматический поиск **не выбирает безверсионный** `/opt/Xilinx/Vivado/bin`; такую установку можно указать через `XILINX_VIVADO=/opt/Xilinx/Vivado`. Наличие `bin` проверяется, но поддержка конкретного чипа и успешный запуск Vivado самим поиском не доказываются. В macOS эта функция поиска сразу возвращает управление.

<a id="appendix-b2"></a>

### Б.2. Altera Quartus

Источники: [00_setup_altera.source_bash](https://github.com/yuri-panchul/basics-graphics-music/blob/991a4b32b4a3ad154cea262803911af28827c8c6/scripts/steps/00_setup_altera.source_bash) и [quartus_has_device.tcl](https://github.com/yuri-panchul/basics-graphics-music/blob/991a4b32b4a3ad154cea262803911af28827c8c6/scripts/fpga/quartus_has_device.tcl).

В отличие от Vivado, Quartus выбирается **с учётом конкретной микросхемы платы**. Название DEVICE читается из `boards/<configuration>/board_specific.qsf`.

Порядок источников:

1. Явный `QUARTUS_ROOTDIR`.
2. Установка, которой принадлежит первая исполняемая команда `quartus`/`quartus.exe` из PATH. Её путь должен иметь распознаваемый вид `.../quartus/bin/quartus` или `.../quartus/bin64/quartus.exe`; произвольная обёртка сама по себе не определяет установку.
3. Кандидаты под `INTEL_FPGA_HOME`, если переменная задана.
4. Затем кандидаты под `ALTERA_HOME`.
5. Затем кандидаты под `QUARTUS_HOME`.
6. Наконец, **общая группа** стандартных родителей: `$HOME`, `/opt`, `/tools` в Linux либо `/c`, `/d`, `/e` в Windows.

Каждый источник проверяется до выбора подходящей установки. Если в нём нет совместимой, скрипт продолжает с источником меньшего приоритета. Если подходящая есть, до следующего источника он уже не доходит. В последней группе сравниваются кандидаты **из всех стандартных родителей вместе**, в отличие от Vivado.

При обходе родителя распознаются:

```text
<parent>/altera/<version>/quartus
<parent>/altera_lite/<version>/quartus
<parent>/altera_std/<version>/quartus
<parent>/altera_pro/<version>/quartus
<parent>/intelFPGA/<version>/quartus
<parent>/intelFPGA_lite/<version>/quartus
<parent>/intelFPGA_std/<version>/quartus
<parent>/intelFPGA_pro/<version>/quartus
```

`<version>` в имени каталога начинается с цифры. Редакция определяется по содержимому установки, а не только по имени `lite`/`pro` в пути.

Проверка каждого кандидата:

1. Путь приводится к нормализованному виду, повторные ссылки на ту же установку пропускаются. В Windows используются `cygpath` и `.exe`.
2. Проверяются исполняемые `quartus`, `quartus_sh`, `quartus_pgm`: в Linux — в `bin`, в Windows сначала в `bin64`, затем в `bin`.
3. Версия и редакция читаются из `version.txt`; если этих сведений недостаточно, запускается `quartus_sh --version`.
4. Проверяются ограничения известных семейств. Например, новые выпуски не заменяют старый Quartus для всех поколений Cyclone. Учитывается и ограничение конфигурации `omdazz_epm570_quartus_13_1_or_older`.
5. Tcl-помощник запрашивает установленную базу устройств и проверяет **точную микросхему**, указанную в QSF. Если пакет устройств отсутствует или запрос не запускается из-за зависимостей, кандидат пропускается.

Из совместимых кандидатов текущей группы предпочтение имеют **Lite/Web**, даже если другая редакция новее. Среди кандидатов одного класса предпочтения выбирается численно более новая версия. При одинаковой версии Standard/Subscription имеет преимущество над Pro; остальные равенства решаются стабильным порядком обхода. `25.1std.0` нормализуется в числовую версию, `13.0sp1` — в `13.0.1`. Внешняя команда `sort` для сравнения версий Quartus не нужна.

**Наличие лицензии алгоритм не проверяет.** Поиск редакции и проверка базы устройств не равны проверке лицензирования. Выбранная Standard/Pro может потребовать соответствующую лицензию уже при работе самого инструмента.

Пример указания точной установки в Git Bash:

```bash
export QUARTUS_ROOTDIR=/c/intelFPGA_lite/23.1std/quartus
./03_synthesize_for_fpga.bash
```

Пример родителя в Linux:

```bash
export INTEL_FPGA_HOME=/tools
./03_synthesize_for_fpga.bash
```

Во втором случае ожидается, например, `/tools/intelFPGA_lite/23.1std/quartus`, а не `/tools/23.1std/quartus`. После выбора `bin`/`bin64` ставится **в начало PATH**, и скрипт хранит полные пути к GUI, shell и programmer одной установки. В сообщении **Selected Quartus** указаны плата, микросхема, версия, редакция и источник выбора.

Для путей с пробелами, не-ASCII символами и специальными символами вроде `!`, `$`, `%`, `@`, `^`, `&`, `*`, кавычек и скобок выводится предупреждение. Скрипт не переносит установку и не обещает, что экранирование решит ограничения самой САПР. Для рабочего маршрута используйте простой ASCII-путь. Под macOS эта функция сообщает о неподдерживаемой платформе.

<a id="appendix-b3"></a>

### Б.3. Gowin EDA

Источник: [00_setup_gowin.source_bash](https://github.com/yuri-panchul/basics-graphics-music/blob/991a4b32b4a3ad154cea262803911af28827c8c6/scripts/steps/00_setup_gowin.source_bash).

Функция допускает Linux, Windows (Cygwin/MSYS) и macOS, когда `uname -m` возвращает `arm64`. Intel Mac этим маршрутом не поддерживается.

1. Если задан `GOWIN_VERSION_DIR`, проверяется именно этот каталог. Внутри ожидаются `IDE`, `Programmer`, `IDE/bin`, а на Windows/macOS ещё `Programmer/bin`. Проверяются исполняемые файлы GUI и синтеза, на Windows/macOS также programmer. Ошибка в явном пути завершает настройку; это не мягкий переход к другим каталогам.
2. Далее проверяется готовое окружение PATH: на Linux нужны `gw_sh` и openFPGALoader; на Windows — `gw_sh.exe` и `programmer_cli.exe`. Проверка в завершающем помощнике также требует `gw_ide`. Этот короткий путь через PATH не используется для macOS.
3. Если этого недостаточно, проверяется `GOWIN_HOME`.
4. Под macOS следующими идут `/Applications`, `$HOME/Applications`; затем, как и под Linux, `$HOME`, `/opt`, `/tools`, `$HOME/Downloads`.
5. В Windows после явного родителя проверяются `/c`, `/d`, `/e` — диски C:\, D:\ и E:\ в Git Bash/MSYS.

В каждом родителе сначала ищутся каталоги поставщика: в Windows `Gowin`, в Linux `Gowin`, затем `gowin`; в macOS перед ними пробуется `GowinIDE.app`. Затем проверяется и сам родитель без добавочного имени поставщика.

Внутри проверяемого каталога сначала рассматриваются непосредственные подкаталоги, путь которых содержит `Gowin_`. Их пути сортируются обычным `sort`, берётся последняя строка; при нескольких версиях печатается предупреждение. Это **алфавитный порядок, не числовое сравнение версии**. Затем, если такой вариант не найден, проверяются непосредственная установка с `IDE/bin/gw_sh` и на macOS содержимое `.app` по пути `Contents/Resources/Gowin_EDA`.

Примеры распознаваемых мест:

```text
/c/Gowin/Gowin_V1.9.9Beta-4_Education/IDE/bin
/opt/gowin/Gowin_V1.9.11.03_Education_Linux/IDE/bin
/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE/bin
```

Первая найденная установка останавливает дальнейший выбор: это не поиск самой новой Gowin на всём компьютере. Подкаталоги просматриваются через `find -type d`, поэтому не следует рассчитывать, что символьная ссылка на каталог версии будет обработана так же, как обычный каталог. Отдельной проверки Unix sort, аналогичной Vivado, здесь нет.

Указать родителя в Linux:

```bash
export GOWIN_HOME=/opt
./03_synthesize_for_fpga.bash
```

Указать конкретную установку в Linux:

```bash
export GOWIN_VERSION_DIR=/opt/gowin/Gowin_V1.9.11.03_Education_Linux
./03_synthesize_for_fpga.bash
```

Проверяйте реальное имя своего каталога, а не копируйте номер версии без проверки. На ARM macOS обычно удобнее оставить стандартную `/Applications/GowinIDE.app` и дать скрипту найти её автоматически. После автоматического поиска скрипт задаёт библиотечные пути `DYLD_FRAMEWORK_PATH`, `DYLD_LIBRARY_PATH` и проверяет quarantine. **В текущем коде ранний выход по явно заданному `GOWIN_VERSION_DIR` пропускает эту заключительную настройку**, поэтому считать этот override полностью эквивалентным автоматическому обнаружению приложения на Mac нельзя.

Скрипт печатает фактические пути `gowin_ide_full_real_path`, `gowin_sh_full_real_path`, `gowin_prog_full_real_path`. Они полезнее предположений о том, какая из нескольких установок «должна» использоваться. Обновление Gowin проверяйте отдельно для нужной микросхемы и подключённого программатора; существование каталогов не заменяет запуск сборки.

<a id="appendix-b4"></a>

### Б.4. OSS CAD Suite

Источник: [00_setup_yosys.source_bash](https://github.com/yuri-panchul/basics-graphics-music/blob/991a4b32b4a3ad154cea262803911af28827c8c6/scripts/steps/00_setup_yosys.source_bash).

Здесь алгоритм короче и устроен иначе:

1. Если существует `~/oss-cad-suite`, скрипт выполняет `source ~/oss-cad-suite/environment`.
2. **Независимо от первого шага**, если существует `~/Downloads/oss-cad-suite`, он выполняет и `source ~/Downloads/oss-cad-suite/environment`.
3. В macOS перед каждым таким подключением проверяется quarantine соответствующего каталога.
4. После загрузки окружения проверяется наличие `yosys` в PATH.
5. Для iCE40 требуются `nextpnr-ice40` и `icepack`; для ECP5 — `nextpnr-ecp5` и `ecppack`; для рассматриваемых Tang/Gowin — `nextpnr-himbaechel` и `gowin_pack`.
6. `openFPGALoader` проверяется на стадии программирования. В iCE40-маршруте также вызывается `icetime`, хотя начальная проверка отдельно его не перечисляет.

Если обе директории существуют, загружаются **обе**. Обычный environment OSS CAD Suite добавляет свой `bin` впереди, поэтому второй каталог в Downloads может перекрыть первый. Сам BGM версии не сравнивает, не ищет каталоги с датами и не останавливается после первого найденного пакета. Для предсказуемого поведения держите одну используемую установку в этих стандартных местах либо внимательно проверьте итоговый PATH.

Если ни одного стандартного каталога нет, используются инструменты, уже доступные в PATH. Для нестандартного расположения можно перед запуском подключить окружение вручную в **Bash**:

```bash
source /opt/oss-cad-suite/environment
command -v yosys
command -v nextpnr-himbaechel
command -v openFPGALoader
./03_synthesize_for_fpga.bash
```

Это пример для маршрута Tang Nano; для iCEBreaker проверяйте `nextpnr-ice40`. Под macOS интерактивный терминал часто использует Zsh: для Bash-файла `environment` откройте `bash` или примените способ настройки, документированный поставщиком пакета. Учитывайте, что стандартные каталоги BGM при запуске могут снова изменить полученное окружение.

В Windows каталог `~` означает домашний каталог Git Bash и не обязательно совпадает с местом распаковки на диске C:. Если пакет установлен в `C:\oss-cad-suite`, а не в `~/oss-cad-suite`, автоматическая проверка этих двух путей его не найдёт. Подключите пакет способом из [документации OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build) или распакуйте его в предусмотренное место. Не смешивайте исполняемые файлы и базы устройств из случайных разных выпусков.

### Б.5. Что сообщить преподавателю, если маршрут не запускается

Скопируйте текст команды, сообщения поиска и **первую существенную ошибку**, а также укажите ОС, архитектуру, конфигурацию платы и версию репозитория:

```bash
pwd
uname -s -m
git rev-parse --short HEAD
git status --short --branch
```

Из корня клона имя платы можно посмотреть в `fpga_board_selection`. В Bash `command -v имя_программы` показывает программу из текущего PATH, а `type -a имя_программы` помогает увидеть несколько кандидатов. Помните, что окружение внутри скрипта может отличаться от исходного терминала. Не публикуйте токены и содержимое файлов аутентификации вместе с диагностикой.

Типичные причины легко различить по стадии: инструмент не найден; выбрана неподдерживаемая микросхема; ошибка HDL; нарушение временных ограничений; битовый поток создан, но USB-программатор недоступен. Последний случай обычно требует исправить подключение и повторить `04`, а не заново редактировать исходник.
