#!/bin/bash

set -e

if [ "$(id -u)" != "0" ]; then
    echo "❌ Скрипт нужно запускать от root (sudo)"
    exit 1
fi

read -p "Вы сервер логов или клиент? (server/client): " ROLE
ROLE=$(echo "$ROLE" | tr '[:upper:]' '[:lower:]')

if [[ "$ROLE" == "server" ]]; then

    echo "[*] Устанавливаем rsyslog..."
    apt update && apt install -y rsyslog

    echo "[*] Создаём директорию /opt для логов..."
    mkdir -p /opt
    chmod 755 /opt

    echo "[*] Включаем UDP и TCP прием в rsyslog..."
    cat <<EOF > /etc/rsyslog.d/00-server.conf
module(load="imudp")
input(type="imudp" port="514")

module(load="imtcp")
input(type="imtcp" port="514")

template(name="RemoteLog" type="string" string="/opt/%HOSTNAME%/syslog.log")

if (\$fromhost-ip != "127.0.0.1") then {
    action(type="omfile" dynaFile="RemoteLog")
    stop
}
EOF

    echo "[*] Настраиваем ротацию логов..."
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

    echo "[*] Перезапуск rsyslog..."
    systemctl restart rsyslog

    echo "✅ Сервер логов готов! Логи будут храниться в /opt/<hostname>/syslog.log"

elif [[ "$ROLE" == "client" ]]; then

    echo "[*] Устанавливаем rsyslog..."
    apt update && apt install -y rsyslog

    read -p "Введите IP-адрес лог-сервера: " SERVER_IP
    if [[ -z "$SERVER_IP" ]]; then
        echo "❌ IP сервера не указан"
        exit 1
    fi

    echo "[*] Настройка отправки логов на сервер..."
    cat <<EOF > /etc/rsyslog.d/01-forward.conf
*.*;auth,authpriv.none @${SERVER_IP}:514
EOF

    echo "[*] Перезапуск rsyslog..."
    systemctl restart rsyslog

    echo "✅ Клиент настроен. Логи отправляются на $SERVER_IP"
    echo "Проверь на сервере: tail -f /opt/$(hostname)/syslog.log"
else
    echo "❌ Неизвестный тип. Введите 'server' или 'client'"
    exit 1
fi
