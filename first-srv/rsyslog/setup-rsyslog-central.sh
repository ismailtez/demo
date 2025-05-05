#!/bin/bash

if [ "$(id -u)" != "0" ]; then
    echo "❌ Запускайте от имени root (sudo)"
    exit 1
fi

# --- Проверяем, это сервер или клиент ---
echo "Вы сервер или клиент?"
select role in "server" "client"; do
    case $role in
        server) break;;
        client) break;;
        *) echo "Выберите 1 (сервер) или 2 (клиент)"
    esac
done

if [[ "$role" == "server" ]]; then

    # --- НАСТРОЙКА СЕРВЕРА ЛОГОВ ---

    echo "[*] Установка rsyslog..."
    sudo apt update && sudo apt install -y rsyslog

    echo "[*] Включаем модули imudp и imtcp в /etc/rsyslog.conf"
    sudo sed -i 's/#module(load="imudp")/module(load="imudp")/' /etc/rsyslog.conf
    sudo sed -i 's/#input(type="imudp" port="514")/input(type="imudp" port="514")/' /etc/rsyslog.conf
    sudo sed -i 's/#module(load="imtcp")/module(load="imtcp")/' /etc/rsyslog.conf
    sudo sed -i 's/#input(type="imtcp" port="514")/input(type="imtcp" port="514")/' /etc/rsyslog.conf

    echo "[*] Добавляем шаблон для хранения логов в /etc/rsyslog.conf"
    cat <<'EOF' | sudo tee -a /etc/rsyslog.conf > /dev/null

# Шаблон для логов с удалённых хостов
$template RemoteLogs,"/opt/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& stop
EOF

    echo "[*] Создаём директорию /opt для логов..."
    sudo mkdir -p /opt

    echo "[*] Исключаем логи самого сервера в /etc/rsyslog.d/remote-logs.conf"
    cat <<'EOF' | sudo tee /etc/rsyslog.d/remote-logs.conf > /dev/null
# Шаблон для сохранения логов по имени хоста
template(name="RemoteHost" type="string" string="/opt/%HOSTNAME%/%PROGRAMNAME%.log")

# Исключаем логи самого себя
if ($fromhost-ip != "127.0.0.1" and $hostname != "First-SRV") then {
    action(type="omfile" dynaFile="RemoteHost" template="RemoteHost")
}
& stop
EOF

    echo "[*] Настройка ротации логов..."
    cat <<'EOF' | sudo tee /etc/logrotate.d/rsyslog-remote > /dev/null
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
EOF

    echo "[*] Перезапуск службы rsyslog..."
    sudo systemctl restart rsyslog

    echo "[+] Сервер логов готов!"
    echo "Логи будут сохраняться в /opt/<имя_хоста>/<программа>.log"

elif [[ "$role" == "client" ]]; then

    # --- НАСТРОЙКА КЛИЕНТА ЛОГОВ (Second-SRV) ---

    echo "[*] Установка rsyslog на клиенте..."
    sudo apt update && sudo apt install -y rsyslog

    echo "[*] Включаем приём логов через UDP и TCP"
    sudo sed -i 's/#module(load="imudp")/module(load="imudp")/' /etc/rsyslog.conf
    sudo sed -i 's/#input(type="imudp" port="514")/input(type="imudp" port="514")/' /etc/rsyslog.conf
    sudo sed -i 's/#module(load="imtcp")/module(load="imtcp")/' /etc/rsyslog.conf
    sudo sed -i 's/#input(type="imtcp" port="514")/input(type="imtcp" port="514")/' /etc/rsyslog.conf

    echo "[*] Настройка отправки всех логов на сервер First-SRV"
    read -p "Введите IP-адрес сервера rsyslog (например, 192.168.100.2): " RSYSL
        if [[ -z "$RSYSLOG_SERVER_IP" ]]; then
        echo "❌ Не указан IP сервера"
        exit 1
    fi

    echo "[*] Добавляем конфиг отправки логов на сервер"
    echo "*.* @@$RSYSLOG_SERVER_IP:514" | sudo tee /etc/rsyslog.d/all.conf > /dev/null

    echo "[*] Перезапуск rsyslog на клиенте"
    sudo systemctl restart rsyslog

    echo "[+] Клиент настроен. Логи будут отправляться на $RSYSLOG_SERVER_IP"
    echo "Проверить можно командой:"
    echo "logger -t test \"Тестовое сообщение\""
    echo "tail -f /opt/$(hostname)/test.log"
fi