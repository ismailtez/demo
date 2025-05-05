## НАСТРОЙКА CUPS ПРИНТЕРА PDF

СЕРВЕР First-SRV

```
sudo apt install rsyslog
sudo nano /etc/rsyslog.conf

#Снимаем комментарии со следующих строк:
module(load="imudp")
input(type="imudp" port="514")
# provides TCP syslog reception
module(load="imtcp")
input(type="imtcp" port="514")

```

И ДОБАВЛЯЕМ В КОНЕЦ ФАЙЛА

```
#После добавляем в конфигурационный файл строки:
$template RemoteLogs,"/opt/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& ~

#в данном примере мы создаем шаблон с названием RemoteLogs, который принимает логи всех категорий, любого уровня (про категории и уровни читайте ниже); логи, полученный по данному шаблону будут сохраняться в каталоге по маске /var/log/rsyslog/<имя компьютера, откуда пришел лог>/<приложение, чей лог пришел>.log; конструкция & ~ говорит о том, что после получения лога, необходимо остановить дальнейшую его обработку.
```

ЧТОБЫ ЛОГИ НЕ ШЛИ С САМОГО СЕБЯ

ОТКРЫВАЕМ ФАЙЛ

```
sudo nano /etc/rsyslog.d/remote-logs.conf
```

ВСТАВЛЯЕМ В ФАЙЛ

```
# Шаблон для сохранения логов по имени хоста
template(name="RemoteHost" type="string" string="/opt/%HOSTNAME%/%PROGRAMNAME%.log")

# Исключаем логи самого сервера и localhost
if ($fromhost-ip != "127.0.0.1" and $hostname != "First-SRV") then {
    action(type="omfile" dynaFile="RemoteHost" template="RemoteHost")
}

# Останавливаем дальнейшую обработку этих сообщений
& stop
```

```
sudo nano /etc/logrotate.d/rsyslog-remote
/opt/*.log {
    weekly
    missingok
    rotate 4
    compress
    delaycompress
    notifempty
    minsize 10M
    create 0640 root root
}
```

ПЕРЕЗАПУСКАЕМ СЛУЖБУ

```
sudo systemctl restart rsyslog
```

КЛИЕНТ Second-SRV

```
sudo apt install rsyslog
sudo nano /etc/rsyslog.conf

#Снимаем комментарии со следующих строк:
module(load="imudp")
input(type="imudp" port="514")
# provides TCP syslog reception
module(load="imtcp")
input(type="imtcp" port="514")

```

```
#Для начала можно настроить отправку всех логов на сервер. Создаем конфигурационный файл для rsyslog:
sudo nano /etc/rsyslog.d/all.conf
#Добавляем:
*.* @@<ip address>:514
# ГАЛОЧКИ УБИРАЕМ ТОЖЕ
# где ip address это адрес сервера rsyslog
#Перезапускаем rsyslog на клиенте
sudo systemctl restart rsyslog
```


или если определенные уровни логирования

```
vi /etc/rsyslog.d/erors.conf

*.err @@192.168.0.15:514
```


КЛИЕНТ микротик First-RTR


```
```



ПРОВЕРКА РАБОТЫ НА ЛИНУКСЕ


```
logger -t test "Сообщение из Second-SRV"
```

ДАЛЕЕ СМОТРИМ ЕГО В 

```
tail -f /opt/Second-SRV/test.log
```