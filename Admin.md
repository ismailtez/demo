### 1. Выполняем на First-CLI,  First-SRV и.т.д

Меняем имя машин

```
hostname set-hostname First-SRV
```

Добавление пользователя 

```
useradd sshuser -u 1010
passwd sshuser - задаст новый пароль
sudo nano /etc/sudoers
и добавляем в конец файла строку:
%sshuser ALL=(ALL:ALL) NOPASSWD: ALL

```
НАСТРОЙКА SSH

```
sudo apt install openssh-server -y
nano /etc/openssh/sshd_config

ДОБАВЛЯЕМ В ФАЙЛ
Port 2024
MaxAuthTries 2
AllowUsers sshuser
PermitRootLogin no
Banner /root/banner

nano /root/banner
ПИШЕМ ТУДА
Authorized access only

systemctl restart sshd
```