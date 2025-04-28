## 1. Подключение к ISP (Eltex)

### Заходим на First-CLI

Втыкаем сериал и адаптер интернета в клиента

Заходим на клиента под кредами

```
логин - astradm
пароль - Sirius2025!
```

Далее alt + t открываем терминал

```
sudo su
nano /etc/apt/sourcec.list
```
Комментим первую строку и РАССКОМЕНЧИВАЕМ ВТОРУЮ

```
sudo apt update
sudo apt install putty
```

Если не скачивается

```
wget http://ftp.ru.debian.org/debian/pool/main/p/putty/putty_0.78-2+deb12u2_amd64.deb

dpkg -i putty-tools_0.78-2+deb12u2_amd64.deb
```

Для подключения через putty вводим
```
sudo putty /dev/ttyUSB0 -serial -sercfg 115200,8,n,1,N
```


## 2. Настройка ISP (Eltex)

Открывается окно putty. Жмем Несколько раз enter.

В терминале вводим

```
логин - admin
пароль - password
Потом еще раз команда - password 12345678
do commit
do confirm
```

```
configure
hostname ISP
```

ДЛЯ УДАЛЕНИЯ SHIFT + BACKSPACE

```
interface gigabitethernet 1/0/1
no switchport access vlan

do commit
do confirm

ip address dhcp

do commit
do confirm

exit
```


ПРОПИСЫВАЕМ НА СВОБОДНОМ ИНТЕРФЕЙСЕ АДРЕС ЧТОБЫ ПО SSH ПОДЛКЮЧИТЬСЯ

ПОСЛЕ ПОДКЛЮЧЕНИЯ ПО SSH ЧТОБЫ УДАЛЯТЬ CTRL + BACKSPACE



### 2.1 Настройка портов ISP (Eltex)

ПРОПИСЫВАЕМ IP ШНИК ДО FIRST-RTR

```
interface gigabitethernet 1/0/2
mode routerport
do commit
do confirm
ip firewall disable
ip address 172.16.4.1/28
do commit
do confirm
```

ПРОПИСЫВАЕМ IP ШНИК ДО SECOND-RTR

```
interface gigabitethernet 1/0/3
mode routerport
do commit
do confirm
ip firewall disable
ip address 172.16.5.1/28
do commit
do confirm
```

### НАСТРОЙКА NAT
```
nat source
ruleset SNAT
to interface gigabitethernet 1/0/1
rule 10
match source-address any
action source-nat interface
enable
do commit
do confirm
```

### 2.2 МАРШРУТ ПО УМОЛЧАНИЮ ДЛЯ ПОДСЕТЕЙ FIRST И SECOND
```
ip route 0.0.0.0/0 10.23.68.74
```

### 2.3 НАСТРОЙКА OSPF НА ISP
```
router ospf 1
router-id 1.1.1.1
area 0.0.0.0
network 172.16.4.0/28
network 172.16.5.0/28
enable
exit
enable
exit
do commit
do confirm
```

### НАСТРОЙКА OSPF НА ISP ИНТЕРФЕЙС 1/0/2 FIRST-RTR

```
interface gigabitethernet 1/0/2
ip ospf instance 1
ip ospf network point-to-point
ip ospf
exit
do commit
do confirm
```

### НАСТРОЙКА OSPF НА ISP ИНТЕРФЕЙС 1/0/3 SECOND-RTR
```
interface gigabitethernet 1/0/3
ip ospf instance 1
ip ospf network point-to-point
ip ospf
do commit
do confirm
exit
```

### АУТЕНТИФИКАЦИЯ OSPF НА ISP ИНТЕРФЕЙС НА FIRST-RTR

```
interface gigabitethernet 1/0/2
ip ospf authentication key ascii-text Simple12
ip ospf authentication algorithm cleartext
exit
```

### АУТЕНТИФИКАЦИЯ OSPF НА ISP ИНТЕРФЕЙС НА SECOND-RTR
```
interface gigabitethernet 1/0/3
ip ospf authentication key ascii-text Simple12
ip ospf authentication algorithm cleartext
exit
do commit
do confirm
```

## 3. НАСТРОЙКА MIKROTIK FIRST-RTR

### Настраиваем имя

```
user add name=net_admin password=P@ssword group=full
system identity set name=First-router
```
### Удаляем адреса
```
ip address print - вывод настроек ip адресов, если есть удаляем
ip address remove numbers=0 число удаления
ip dhcp-client print
ip dhcp-client remove numbers=0
ip dhcp-server print
ip dhcp-server remove numbers=0
```

### НАСТРОЙКА SSH  НА MIKROTIK FIRST-router

```
ip service set ssh port=22 address=0.0.0.0/0 disable=no
```

С АСТРЫ ПОДКЛЮЧАЕМСЯ НА

```
ssh net_user@172.16.98.1
```

### ЗАДАЕМ IP-ШНИК НА FIRST-RTR В СТОРОНУ ELTEX ISP

```
ip address add address=172.16.4.2/28 interface=ether1
```

### ПРОПИСЫВАЕМ МАРШРУТ ПО УМОЛЧАНИЮ

```
ip route add dst-address=0.0.0.0/0 gateway=172.16.4.1
```

### НАСТРОЙКА OSPF НА FIRST-RTR

```
routing ospf instance add name=ospf-instance-1 router-id=2.2.2.2
routing ospf network add area=backbone network=172.16.4.0/28
routing ospf interface add interface=ether1 network-type=point-to-point
routing ospf interface set [find where interface=ether1] authentication=simple authentication-key=Simple12
```

### РАЗРЕШАЕМ ВСЕ ПРАВИЛА ФАЙРВОЛЛ НА МИРОКТИКЕ

```
ip firewall filter add chain=input action=accept place-before=0
ip firewall filter add chain=forward  action=accept place-before=0
ip firewall filter add chain=output  action=accept place-before=0
ip firewall filter print
```

### ПРОВЕРЯЕМ СОСЕДЕЙ OSPF

```
routing ospf neighbor print
```

### НАСТРОЙКА DHCP  НА FIRST-RTR

```
ip address add address=192.168.100.1/26 interface=ether2
ip address add address=192.168.200.1/28 interface=ether3
ip pool add name=dhcp-pool ranges=192.168.200.2-192.168.200.14
interface bridge port remove [find interface=ether3]

ip dhcp-server network add address=192.168.200.0/28 gateway=192.168.200.1 dns-server=8.8.8.8
ip dhcp-server add address-pool=dhcp-pool interface=ether3 disabled=no name=local-dhcp
```

## 4. НАСТРОЙКА MIKROTIK SECOND-RTR

```
user add name=net_admin password=P@ssword group=full
system identity set name=Second-RTR

ip address print - вывод настроек ip адресов, если есть удаляем

ip address remove numbers= число удаления

ip dhcp-client print

ip dhcp-client remove numbers=
```

### ВКЛЮЧАЕМ SSH НА SECOND-RTR

ip service set ssh port=22 address=0.0.0.0/0 disable=no


### ЗАДАЕМ IP-ШНИК НА FIRST-RTR В СТОРОНУ ELTEX ISP
ip address add address=172.16.5.2/28 interface=ether1


### ПРОПИСЫВАЕМ МАРШРУТ ПО УМОЛЧАНИЮ
ip route add dst-address=0.0.0.0/0 gateway=172.16.5.1


### НАСТРОЙКА OSPF НА FIRST-RTR

routing ospf instance add name=ospf-instance-2 router-id=3.3.3.3
routing ospf network add area=backbone network=172.16.5.0/28
routing ospf interface add interface=ether1 network-type=point-to-point
routing ospf interface set [find where interface=ether1] authentication=simple authentication-key=Simple12


### РАЗРЕШАЕМ ВСЕ ПРАВИЛА ФАЙРВОЛЛ НА МИРОКТИКЕ

ip firewall filter add chain=input action=accept place-before=0
ip firewall filter add chain=forward  action=accept place-before=0
ip firewall filter add chain=output  action=accept place-before=0
ip firewall filter print

### ПРОВЕРЯЕМ СОСЕДЕЙ OSPF

routing ospf neighbor print