> **Warning:** This document is deprecated and WSL is no longer supported.


Reference document https://www.xda-developers.com/wsl-connect-usb-devices-windows-11/

Then download and install the latest release USBIPD for Windows. https://github.com/dorssel/usbipd-win/releases/latest

Windows
```
> wsl --install
```
Ubuntu
```
$ sudo apt install linux-tools-virtual hwdata
$ sudo update-alternatives --install /usr/local/bin/usbip usbip `ls /usr/lib/linux-tools/*/usbip | tail -n1` 20
```
```
$ uname -a
Linux XXXX 5.15.133.1-microsoft-standard-WSL2 #1 SMP Thu Oct 5 21:02:42 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
```

Add Defaults        secure_path="/usr/lib/linux-tools/5.15.0-97-generic:  in /etc/sudoers

```
$ sudo vi /etc/sudoers
```

```
# See the man page for details on how to write a sudoers file.
#
Defaults        env_reset
Defaults        mail_badpass
Defaults        secure_path="/usr/lib/linux-tools/5.15.0-97-generic:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
Defaults        use_pty
```
Windows As Administrator
```
PS C:\Windows\system32> usbipd list
Connected:
BUSID  VID:PID    DEVICE                                                        STATE
1-7    8087:0a2b  Intel(R) Wireless Bluetooth(R)                                Not shared
1-8    04f2:b5c1  Integrated Camera                                             Not shared
1-9    138a:0090  Synaptics WBDI                                                Not shared
4-2    0403:6010  USB Serial Converter A, USB Serial Converter B                Not shared
```
```
PS C:\Windows\system32> usbipd  bind --busid 4-2
```
```
PS C:\Windows\system32> usbipd  attach --busid 4-2 -w
usbipd: info: Using WSL distribution 'Ubuntu' to attach; the device will be available in all WSL 2 distributions.
usbipd: info: Using IP address 172.22.0.1 to reach the host.
```
Ubuntu
```
$ lsusb
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 004: ID 0403:6010 Future Technology Devices International, Ltd FT2232C/D/H Dual UART/FIFO IC
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```


# Installing openFPGALoader

Select Ubuntu steps

https://trabucayre.github.io/openFPGALoader/guide/install.html

```
~/openFPGALoader$ openFPGALoader --detect
empty
No cable or board specified: using direct ft2232 interface
Can't read iSerialNumber field from FTDI: considered as empty string
Jtag frequency : requested 6.00MHz   -> real 6.00MHz
index 0:
        idcode 0x41111043
        manufacturer lattice
        family ECP5
        model  LFE5U-25
        irlength 8
```

