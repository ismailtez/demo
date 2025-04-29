## DNS

ДЛЯ ТОГО ЧТОБЫ СНЕСТИ СЕРВЕР

```
sudo systemctl stop bind9
sudo systemctl disable bind9
sudo apt purge bind9 bind9utils bind9-dnsutils bind9-host -y
sudo rm -rf /etc/bind/ /var/cache/bind/ /var/log/bind/
sudo apt autoremove -y
systemctl status bind9  # Должен быть "not found"
```

УСТАНОВКА DNS СЕРВЕРА

```
sudo apt update
sudo apt install bind9 bind9utils dnsutils -y
sudo systemctl status bind9
```

## ПЕРВОЕ

```
sudo touch /etc/bind/named.conf.options
sudo touch /etc/bind/named.conf.local
sudo touch /etc/bind/db.it-sirius.any
sudo touch /etc/bind/db.4.16.172
sudo touch /etc/bind/db.5.16.172
sudo touch /etc/bind/db.100.168.192
sudo touch /etc/bind/db.200.168.192
sudo touch /etc/bind/db.6.168.192
```

```
# Копирование содержимого из клонированных файлов
sudo cp named.conf.options /etc/bind/named.conf.options
sudo cp named.conf.local /etc/bind/named.conf.local
sudo cp db.it-sirius.any /etc/bind/db.it-sirius.any
sudo cp db.4.16.172 /etc/bind/db.4.16.172
sudo cp db.5.16.172 /etc/bind/db.5.16.172
sudo cp db.100.168.192 /etc/bind/db.100.168.192
sudo cp db.200.168.192 /etc/bind/db.200.168.192
sudo cp db.6.168.192 /etc/bind/db.6.168.192
```

