# Настройка программы minicom

## Запуск программы

```
sudo minicom -D /dev/ttyUSB0
```
Параметр -D передаёт имя устройства, как правило это /dev/ttyUSB0, но может быть и другим.

## Конфигурирование

1. В терминале minicom нажмите  Ctrl+A, затем Z. Появится окно со списком команд
![](./minicom_1.png)

2. Нажмите 'o'. Появится окно настройки
![](./minicom_2.png)

3. Выберете пунк :Serial port setup". Появится окно настройки. 
![](./minicom_3.png)

  Должны быть установлены параметры:
* Bps/Par/Bits: 115200 8N1
* Hardware Flow control: No
* Software Flow control: No
    

В каталоге лабораторной работы есть скрипт ./13_run_serial_terminal.bash

Скрипт запускат программу в зависимости от типа операционной системы.

Если имя порта отличается от /dev/ttyUSB0 то требуется скорректировать вызов программы minicom

```
if    [ "$OSTYPE" = "msys" ]  
then
    # COM_BOARD is session name
    # The first time you run it, a configuration window will be displayed. 
    # Please select the  mode "Serial", serial port number  which the board is connected, 
    # serial mode 115200, 8N1, flow control "None" and save the session with the name "COM_BOARD"
    # The port number can be determined through the device manager
    putty -load COM_BOARD &
else
    # change device name /dev/ttyUSB0 for actual device in your system
    # Please set serial mode 115200, 8N1, flow control "None" and save the session as default
    sudo minicom -D /dev/ttyUSB0 
fi
```