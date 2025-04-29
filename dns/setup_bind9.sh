#!/bin/bash

# Функция для удаления BIND9 (если уже установлен)
remove_bind9() {
    echo "Удаление BIND9..."
    sudo systemctl stop bind9 2>/dev/null || true
    sudo systemctl disable bind9 2>/dev/null || true
    sudo apt purge bind9 bind9utils dnsutils -y
    sudo rm -rf /etc/bind/ /var/cache/bind/ /var/log/bind/
    sudo apt autoremove -y
    echo "BIND9 удален."
}

# Установка BIND9 и необходимых утилит
install_bind9() {
    echo "Обновление списка пакетов и установка BIND9..."
    sudo apt update -y
    sudo apt install bind9 bind9utils dnsutils -y
    echo "BIND9 установлен."
}

# Настройка named.conf.options
configure_named_conf_options() {
    echo "Настройка файла /etc/bind/named.conf.options..."
    sudo tee /etc/bind/named.conf.options > /dev/null <<EOF
options {
    directory "/var/cache/bind";
    recursion yes;  // Разрешить рекурсивные запросы (для кэширующего DNS)
    allow-query { any; };  // Разрешить запросы от всех (или укажите конкретные IP)
    forwarders {
        8.8.8.8;  // Google DNS (или ваш провайдерский DNS)
        8.8.4.4;
    };
    dnssec-validation auto;
    listen-on { any; };  // Слушать на всех интерфейсах
    listen-on-v6 { any; };
};
EOF
}

# Настройка named.conf.local
configure_named_conf_local() {
    echo "Настройка файла /etc/bind/named.conf.local..."
    sudo tee /etc/bind/named.conf.local > /dev/null <<EOF
zone "it-sirius.any" {
    type master;
    file "/etc/bind/db.it-sirius.any";
    allow-transfer { none; };
};

zone "4.16.172.in-addr.arpa" {
    type master;
    file "/etc/bind/db.4.16.172";
};

zone "5.16.172.in-addr.arpa" {
    type master;
    file "/etc/bind/db.5.16.172";
};

zone "100.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.100.168.192";
};

zone "200.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.200.168.192";
};

zone "6.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.6.168.192";
};
EOF
}

# Создание файла зоны it-sirius.any
create_zone_file_it_sirius() {
    echo "Создание файла /etc/bind/db.it-sirius.any..."
    sudo tee /etc/bind/db.it-sirius.any > /dev/null <<EOF
\$TTL    86400
@       IN      SOA     first-srv.it-sirius.any. admin.it-sirius.any. (
                        2024042601      ; Serial
                        3600            ; Refresh
                        1800            ; Retry
                        604800          ; Expire
                        86400           ; Minimum TTL
)

; NS записи
@       IN      NS      first-srv.it-sirius.any.

; A записи
first-srv       IN      A       192.168.100.2

first-rtr       IN      A       172.16.4.2
first-rtr       IN      A       192.168.100.1
first-rtr       IN      A       192.168.200.1

second-rtr      IN      A       172.16.5.2
second-rtr      IN      A       192.168.6.1

first-cli       IN      A       192.168.200.14
second-srv      IN      A       192.168.6.2

; CNAME записи
moodle          IN      CNAME   second-srv.it-sirius.any.
wiki            IN      CNAME   second-srv.it-sirius.any.
EOF
}

# Создание файлов обратных зон
create_reverse_zone_files() {
    echo "Создание файлов обратных зон..."

    # Зона 4.16.172.in-addr.arpa
    sudo tee /etc/bind/db.4.16.172 > /dev/null <<EOF
\$TTL    86400
@       IN      SOA     first-srv.it-sirius.any. admin.it-sirius.any. (
                        2024042601      ; Serial
                        3600            ; Refresh
                        1800            ; Retry
                        604800          ; Expire
                        86400           ; Minimum TTL
)

; NS записи
@       IN      NS      first-srv.it-sirius.any.

; PTR записи
1       IN      PTR     isp-gateway.it-sirius.any.
2       IN      PTR     first-rtr.it-sirius.any.
EOF

    # Зона 5.16.172.in-addr.arpa
    sudo tee /etc/bind/db.5.16.172 > /dev/null <<EOF
\$TTL    86400
@       IN      SOA     first-srv.it-sirius.any. admin.it-sirius.any. (
                        2024042601      ; Serial
                        3600            ; Refresh
                        1800            ; Retry
                        604800          ; Expire
                        86400           ; Minimum TTL
)

; NS записи
@       IN      NS      first-srv.it-sirius.any.

; PTR записи
1       IN      PTR     isp-gateway.it-sirius.any.
2       IN      PTR     second-rtr.it-sirius.any.
EOF

    # Зона 100.168.192.in-addr.arpa
    sudo tee /etc/bind/db.100.168.192 > /dev/null <<EOF
\$TTL    86400
@       IN      SOA     first-srv.it-sirius.any. admin.it-sirius.any. (
                        2024042601      ; Serial
                        3600            ; Refresh
                        1800            ; Retry
                        604800          ; Expire
                        86400           ; Minimum TTL
)

; NS записи
@       IN      NS      first-srv.it-sirius.any.

; PTR записи
1       IN      PTR     first-rtr.it-sirius.any.
2       IN      PTR     first-srv.it-sirius.any.
EOF

    # Зона 200.168.192.in-addr.arpa
    sudo tee /etc/bind/db.200.168.192 > /dev/null <<EOF
\$TTL    86400
@       IN      SOA     first-srv.it-sirius.any. admin.it-sirius.any. (
                        2024042601      ; Serial
                        3600            ; Refresh
                        1800            ; Retry
                        604800          ; Expire
                        86400           ; Minimum TTL
)

; NS записи
@       IN      NS      first-srv.it-sirius.any.

; PTR записи
1       IN      PTR     first-rtr.it-sirius.any.
14      IN      PTR     first-cli.it-sirius.any.
EOF

    # Зона 6.168.192.in-addr.arpa
    sudo tee /etc/bind/db.6.168.192 > /dev/null <<EOF
\$TTL    86400
@       IN      SOA     first-srv.it-sirius.any. admin.it-sirius.any. (
                        2024042601      ; Serial
                        3600            ; Refresh
                        1800            ; Retry
                        604800          ; Expire
                        86400           ; Minimum TTL
)

; NS записи
@       IN      NS      first-srv.it-sirius.any.

; PTR записи
1       IN      PTR     second-rtr.it-sirius.any.
2       IN      PTR     second-srv.it-sirius.any.
EOF
}

# Проверка конфигурации и зон
check_configuration() {
    echo "Проверка конфигурации BIND9..."
    sudo named-checkconf
    sudo named-checkzone it-sirius.any /etc/bind/db.it-sirius.any
    sudo named-checkzone 4.16.172.in-addr.arpa /etc/bind/db.4.16.172
    sudo named-checkzone 5.16.172.in-addr.arpa /etc/bind/db.5.16.172
    sudo named-checkzone 100.168.192.in-addr.arpa /etc/bind/db.100.168.192
    sudo named-checkzone 200.168.192.in-addr.arpa /etc/bind/db.200.168.192
    sudo named-checkzone 6.168.192.in-addr.arpa /etc/bind/db.6.168.192
}

# Перезапуск и включение службы BIND9
restart_and_enable_bind9() {
    echo "Перезапуск службы BIND9..."
    sudo systemctl restart bind9
    sudo systemctl enable bind9
    echo "Проверка статуса службы BIND9..."
    sudo systemctl status bind9
}

# Настройка resolv.conf
configure_resolv_conf() {
    echo "Настройка /etc/resolv.conf..."
    sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 192.168.100.2
search it-sirius.any
EOF
}

# Основной процесс
main() {
    remove_bind9
    install_bind9
    configure_named_conf_options
    configure_named_conf_local
    create_zone_file_it_sirius
    create_reverse_zone_files
    check_configuration
    restart_and_enable_bind9
    configure_resolv_conf
    echo "Настройка DNS-сервера завершена!"
}

main