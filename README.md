## Подключение к ISP (Eltex)

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


## Настройка ISP (Eltex)

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




НАСТРОЙКА ELTEX ISP

## Настройка портов ISP (Eltex)

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

НАСТРОЙКА NAT
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

МАРШРУТ ПО УМОЛЧАНИЮ ДЛЯ ПОДСЕТЕЙ FIRST И SECOND
```
ip route 0.0.0.0/0 10.23.68.74
```

НАСТРОЙКА OSPF НА ISP
ISP(config)# router ospf 1
ISP(config-ospf)# router-id 1.1.1.1
ISP(config-ospf)# area 0.0.0.0
ISP(config-ospf-area)# network 172.16.4.0/28
ISP(config-ospf-area)# network 172.16.5.0/28
ISP(config-ospf-area)# enable
ISP(config-ospf-area)# exit
ISP(config-ospf)# enable
ISP(config-ospf)# exit
ISP(config)# do commit
Configuration has been successfully applied and saved to flash. Commit timer started, changes will be reverted in 600 seconds.
1970-01-01T01:11:19+00:00 %CLI-I-CRIT: user admin from ssh 172.16.99.2 input: do commit
ISP(config)# do confirm
Configuration has been confirmed. Commit timer canceled.
1970-01-01T01:11:24+00:00 %CLI-I-CRIT: user admin from ssh 172.16.99.2 input: do confirm
ISP(config)#


НАСТРОЙКА OSPF НА ISP ИНТЕРФЕЙС 1/0/2 FIRST-RTR

ISP(config)# interface gigabitethernet 1/0/2
ISP(config-if-gi)# ip ospf instance 1
ISP(config-if-gi)# ip ospf network point-to-point
ISP(config-if-gi)# ip ospf
ISP(config-if-gi)# exit
ISP(config)# do commit
Configuration has been successfully applied and saved to flash. Commit timer started, changes will be reverted in 600 seconds.
1970-01-01T01:12:53+00:00 %CLI-I-CRIT: user admin from ssh 172.16.99.2 input: do commit
ISP(config)# do confirm
Configuration has been confirmed. Commit timer canceled.
1970-01-01T01:12:55+00:00 %CLI-I-CRIT: user admin from ssh 172.16.99.2 input: do confirm
ISP(config)#


НАСТРОЙКА OSPF НА ISP ИНТЕРФЕЙС 1/0/3 SECOND-RTR
ISP(config)# interface gigabitethernet 1/0/3
ISP(config-if-gi)# ip ospf instance 1
ISP(config-if-gi)# ip ospf network point-to-point
ISP(config-if-gi)# ip ospf
ISP(config-if-gi)# do commit
Configuration has been successfully applied and saved to flash. Commit timer started, changes will be reverted in 600 seconds.
1970-01-01T01:13:35+00:00 %CLI-I-CRIT: user admin from ssh 172.16.99.2 input: do commit
ISP(config-if-gi)# do confirm
Configuration has been confirmed. Commit timer canceled.
1970-01-01T01:13:39+00:00 %CLI-I-CRIT: user admin from ssh 172.16.99.2 input: do confirm
ISP(config-if-gi)# exit
ISP(config)#

АУТЕНТИФИКАЦИЯ OSPF НА ISP ИНТЕРФЕЙС НА FIRST-RTR

ISP(config)# interface gigabitethernet 1/0/2
ISP(config-if-gi)# ip ospf authentication key ascii-text Simple12
ISP(config-if-gi)# ip ospf authentication algorithm cleartext
ISP(config-if-gi)# exit

АУТЕНТИФИКАЦИЯ OSPF НА ISP ИНТЕРФЕЙС НА SECOND-RTR
ISP(config)# interface gigabitethernet 1/0/3
ISP(config-if-gi)# ip ospf authentication key ascii-text Simple12
ISP(config-if-gi)# ip ospf authentication algorithm cleartext
ISP(config-if-gi)# exit
ISP(config)# do commit
Configuration has been successfully applied and saved to flash. Commit timer started, changes will be reverted in 600 seconds.
1970-01-01T01:17:07+00:00 %CLI-I-CRIT: user admin from ssh 172.16.99.2 input: do commit
ISP(config)# do confirm
Configuration has been confirmed. Commit timer canceled.
1970-01-01T01:17:10+00:00 %CLI-I-CRIT: user admin from ssh 172.16.99.2 input: do confirm
ISP(config)#




-------------------------------------------------------------

НАСТРОЙКА MIKROTIK FIRST-RTR


user add name=net_admin password=P@ssword group=full
system identity set name=First-router


ip address print - вывод настроек ip адресов, если есть удаляем

ip address remove numbers= число удаления

ip dhcp-client print

ip dhcp-client remove numbers=


ip dhcp-server print

ip dhcp-server remove numbers=

НАВЕШИВАЕМ АДРЕС НА ИНТЕРФЕЙС ДЛЯ SSH ПОДКЛЮЧЕНИЯ

ip address add address=172.16.98.1/24 interface=ether4


НАСТРОЙКА SSH  НА MIKROTIK FIRST-router

ip service set ssh port=22 address=0.0.0.0/0 disable=no

С АСТРЫ ПОДКЛЮЧАЕМСЯ НА

ssh net_user@172.16.98.1


ЗАДАЕМ IP-ШНИК НА FIRST-RTR В СТОРОНУ ELTEX ISP
[net_admin@First-RTR] > ip address add address=172.16.4.2/28 interface=ether1


ПРОПИСЫВАЕМ МАРШРУТ ПО УМОЛЧАНИЮ
[net_admin@First-RTR] > ip route add dst-address=0.0.0.0/0 gateway=172.16.4.1


НАСТРОЙКА OSPF НА FIRST-RTR

[net_admin@First-RTR] > routing ospf instance add name=ospf-instance-1 router-id=2.2.2.2
[net_admin@First-RTR] > routing ospf network add area=backbone network=172.16.4.0/28
[net_admin@First-RTR] > routing ospf interface add interface=ether1 network-type=point-to-point
[net_admin@First-RTR] > routing ospf interface set [find where interface=ether1] authentication=simple authentication-key=Simple12


РАЗРЕШАЕМ ВСЕ ПРАВИЛА ФАЙРВОЛЛ НА МИРОКТИКЕ

[net_admin@First-RTR] > ip firewall filter add chain=input action=accept place-before=0
[net_admin@First-RTR] > ip firewall filter add chain=forward  action=accept place-before=0
[net_admin@First-RTR] > ip firewall filter add chain=output  action=accept place-before=0
[net_admin@First-RTR] > ip firewall filter print
Flags: X - disabled, I - invalid, D - dynamic
 0    chain=input action=accept

 1    chain=forward action=accept

 2    chain=output action=accept

 3  D ;;; special dummy rule to show fasttrack counters
      chain=forward action=passthrough

 4    ;;; defconf: accept established,related,untracked
      chain=input action=accept
      connection-state=established,related,untracked

ПРОВЕРЯЕМ СОСЕДЕЙ OSPF

[net_admin@First-RTR] > routing ospf neighbor print
 0 instance=default router-id=1.1.1.1 address=172.16.4.1 interface=ether1
   priority=128 dr-address=0.0.0.0 backup-dr-address=0.0.0.0 state="Full"
   state-changes=4 ls-retransmits=0 ls-requests=0 db-summaries=0
   adjacency=1m7s



НАСТРОЙКА DHCP  НА FIRST-RTR

[net_admin@First-RTR] > ip address add address=192.168.100.1/26 interface=ether2
[net_admin@First-RTR] > ip address add address=192.168.200.1/28 interface=ether3
[net_admin@First-RTR] > ip pool add name=dhcp-pool ranges=192.168.200.2-192.168.200.14
[net_admin@First-RTR] > interface bridge port remove [find interface=ether3]

[net_admin@First-RTR] > ip dhcp-server network add address=192.168.200.0/28 gateway=192.168.200.1 dns-server=8.8.8.8
[net_admin@First-RTR] > ip dhcp-server add address-pool=d
default-dhcp  dhcp-pool
[net_admin@First-RTR] > ip dhcp-server add address-pool=dhcp-pool in
insert-queue-before  interface
[net_admin@First-RTR] > ip dhcp-server add address-pool=dhcp-pool interface=ether3 disabled=no name=local-dhcp
[net_admin@First-RTR] >

-------------------------------------------------------------

НАСТРОЙКА MIKROTIK SECOND-RTR

user add name=net_admin password=P@ssword group=full
system identity set name=Second-RTR


ip address print - вывод настроек ip адресов, если есть удаляем

ip address remove numbers= число удаления

ip dhcp-client print

ip dhcp-client remove numbers=

ВКЛЮЧАЕМ SSH НА SECOND-RTR

ip service set ssh port=22 address=0.0.0.0/0 disable=no


ЗАДАЕМ IP-ШНИК НА FIRST-RTR В СТОРОНУ ELTEX ISP
[net_admin@First-RTR] > ip address add address=172.16.5.2/28 interface=ether1


ПРОПИСЫВАЕМ МАРШРУТ ПО УМОЛЧАНИЮ
[net_admin@First-RTR] > ip route add dst-address=0.0.0.0/0 gateway=172.16.5.1


НАСТРОЙКА OSPF НА FIRST-RTR

[net_admin@First-RTR] > routing ospf instance add name=ospf-instance-2 router-id=3.3.3.3
[net_admin@First-RTR] > routing ospf network add area=backbone network=172.16.5.0/28
[net_admin@First-RTR] > routing ospf interface add interface=ether1 network-type=point-to-point
[net_admin@First-RTR] > routing ospf interface set [find where interface=ether1] authentication=simple authentication-key=Simple12


РАЗРЕШАЕМ ВСЕ ПРАВИЛА ФАЙРВОЛЛ НА МИРОКТИКЕ

[net_admin@First-RTR] > ip firewall filter add chain=input action=accept place-before=0
[net_admin@First-RTR] > ip firewall filter add chain=forward  action=accept place-before=0
[net_admin@First-RTR] > ip firewall filter add chain=output  action=accept place-before=0
[net_admin@First-RTR] > ip firewall filter print
Flags: X - disabled, I - invalid, D - dynamic
 0    chain=input action=accept

 1    chain=forward action=accept

 2    chain=output action=accept

 3  D ;;; special dummy rule to show fasttrack counters
      chain=forward action=passthrough

 4    ;;; defconf: accept established,related,untracked
      chain=input action=accept
      connection-state=established,related,untracked

ПРОВЕРЯЕМ СОСЕДЕЙ OSPF

[net_admin@First-RTR] > routing ospf neighbor print
 0 instance=default router-id=1.1.1.1 address=172.16.4.1 interface=ether1
   priority=128 dr-address=0.0.0.0 backup-dr-address=0.0.0.0 state="Full"
   state-changes=4 ls-retransmits=0 ls-requests=0 db-summaries=0
   adjacency=1m7s

