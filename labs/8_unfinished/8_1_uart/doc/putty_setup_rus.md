# Настройка программы Putty

Программа Putty используется для работы с последовательным портом в системе Wondows.

Программу можно скачать здесь: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html

Требуется определить через диспетчер устройств номер последовательного порта к которому подключена отладочная плата.

Порт должен появится в разделе "Порты COM и LPT", на рисунке ниже это порт COM15

![](./putty_1.png)

* Запустите программу Putty
* Выберете "Connection type:" - Serial
![](./putty_2.png)

* На вкладке Connection/Serial установите параметры:
    * Speed: 115200
    * Data bits: 8
    * Stop bits: 1
    * Parity: None
    * Flow control: None

![](./putty_3.png)

* Вернитесь на вкладу Session
* Введите имея сессии COM_BOARD
* Сохраните сессию

При запуске через скрипт ./13_run_serial_terminal.bash будет загружаться сессия COM_BOARD

