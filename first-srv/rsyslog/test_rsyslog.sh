#!/bin/bash

set -e

if [ "$(id -u)" != "0" ]; then
    echo "❌ Запусти скрипт через sudo или от root"
    exit 1
fi

read -rp "Выберите тип (server/client): " ROLE
ROLE=$(echo "$ROLE" | tr '[:upper:]' '[:lower:]')

# ==== SERVER SETUP ====
if [[ "$ROLE" == "server" ]]; then
    echo "[*] Устанавливаем rsyslog..."
    apt update && apt install -y rsyslog

    echo "[*] Включаем TCP/UDP приём логов..."
    cat <<EOF > /etc/rsyslog.d/00-server.conf
module(load="imudp")
input(type="imudp" port="514")

module(load="imtcp")
input(type="imtcp" port="514")

template(name="RemoteLog" type="string" string="/opt/%HOSTNAME%/syslog.log")

if (\$fromhost-ip != "127.0.0.1" and \$hostname != "$(hostname)") then {
    action(type="omfile" dynaFile="RemoteLog")
    stop
}
EOF

    echo "[*] Создаём /opt и настраиваем права..."
    mkdir -p /opt
    chmod 755 /opt

    echo "[*] Настраиваем логротацию..."
    cat <<EOF > /etc/logrotate.d/remote-syslog
/opt/*/syslog.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    minsize 10M
    create 0640 root root
}
EOF

    echo "[*] Перезапускаем rsyslog..."
    systemctl restart rsyslog

    echo "✅ Сервер готов. Логи будут храниться в /opt/<имя_хоста>/syslog.log"

# ==== CLIENT SETUP ====
elif [[ "$ROLE" == "client" ]]; then
    echo "[*] Устанавливаем rsyslog..."
    apt update && apt install -y rsyslog

    read -rp "Введите IP сервера логов: " SERVER_IP
    if [[ -z "$SERVER_IP" ]]; then
        echo "❌ Не указан IP"
        exit 1
    fi

    echo "[*] Настраиваем отправку логов на $SERVER_IP..."
    cat <<EOF > /etc/rsyslog.d/01-forwarding.conf
*.*;auth,authpriv.none @@$SERVER_IP:514
EOF

    echo "[*] Перезапуск rsyslog..."
    systemctl restart rsyslog

    echo "✅ Клиент настроен. Отправка логов на $SERVER_IP"
    echo "Проверь на сервере: tail -f /opt/$(hostname)/syslog.log"

else
    echo "❌ Введите server или client"
    exit 1
fi
