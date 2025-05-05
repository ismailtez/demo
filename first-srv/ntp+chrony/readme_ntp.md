НАСТРОЙКА НТП НА МИКРОТИКЕ

```
/system/ntp/client/set enabled=yes
/system/ntp/client/servers/add address=pool.ntp.org
/system/ntp/client/servers/add address=0.europe.pool.ntp.org
```
```
/system/clock/set time-zone-name=Europe/Moscow
```
НА ЭЛТЕКС
```
clock timezone gmt +7
```
ИЛИ
```
/system ntp client set \
    enabled=yes \
    primary-ntp=2.ru.pool.ntp.org \
    secondary-ntp=3.ru.pool.ntp.org \
    stratum=5 \
    mode=unicast \
    poll-interval=16
```
