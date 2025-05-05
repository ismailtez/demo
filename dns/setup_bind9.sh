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
        recursion yes;
        allow-recursion {
                172.16.4.0/28;
                172.16.5.0/28;
                192.168.6.0/27;
                192.168.100.0/26;
                192.168.200.0/28;
        };

        // If there is a firewall between you and nameservers you want
        // to talk to, you may need to fix the firewall to allow multiple
        // ports to talk.  See http://www.kb.cert.org/vuls/id/800113

        // If your ISP provided one or more IP addresses for stable
        // nameservers, you probably want to use them as forwarders.
        // Uncomment the following block, and insert the addresses replacing
        // the all-0's placeholder.

        forwarders {
                8.8.8.8;
        };

        //========================================================================
        // If BIND logs error messages about the root key being expired,
        // you will need to update your keys.  See https://www.isc.org/bind-keys
        //========================================================================
        dnssec-validation auto;

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
        file "/etc/bind/zones/db.it-sirius.any";
};

zone "4.16.172.in-addr.arpa" {
        type master;
        file "/etc/bind/zones/db.4.16.172";
};

zone "5.16.172.in-addr.arpa" {
        type master;
        file "/etc/bind/zones/db.5.16.172";
};

zone "6.168.192.in-addr.arpa" {
        type master;
        file "/etc/bind/zones/db.6.168.192";    
};
zone "100.168.192.in-addr.arpa" {
        type master;
        file "/etc/bind/zones/db.100.168.192";
};

zone "200.168.192.in-addr.arpa" {
        type master;
        file "/etc/bind/zones/db.200.168.192";
};
EOF
}

# Создание файла зоны it-sirius.any
create_zone_file_it_sirius() {
    echo "Создание файла /etc/bind/db.it-sirius.any..."
    sudo tee /etc/bind/db.it-sirius.any > /dev/null <<EOF
\$TTL    604800
@       IN      SOA     first-srv.it-sirius.any. admin.it-sirius.any. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      first-srv.it-sirius.any.
first-srv       IN      A       192.168.100.2
first-rtr       IN      A       192.168.100.1
first-rtr       IN      A       172.16.4.2
first-rtr       IN      A       192.168.200.1
first-cli       IN      A       192.168.200.14
second-rtr      IN      A       172.16.5.2
second-rtr      IN      A       192.168.6.1
second-srv      IN      A       192.168.6.2
moodle          IN      CNAME   first-srv.it-sirius.any.
wiki            IN      CNAME   second-srv.it-sirius.any.
mon             IN      CNAME   first-srv.it-sirius.any.
@       IN      AAAA    ::1
EOF
}

# Создание файлов обратных зон
create_reverse_zone_files() {
    echo "Создание файлов обратных зон..."

    # Зона 4.16.172.in-addr.arpa
    sudo tee /etc/bind/db.4.16.172 > /dev/null <<EOF
\$TTL    604800
@       IN      SOA     it-sirius.any. admin.it-sirius.any. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      first-srv.it-sirius.any.
2       IN      PTR     first-rtr.it-sirius.any.
EOF

    # Зона 5.16.172.in-addr.arpa
    sudo tee /etc/bind/db.5.16.172 > /dev/null <<EOF
\$TTL    604800
@       IN      SOA     it-sirius.any. admin.it-sirius.any. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      first-srv.it-sirius.any.
2       IN      PTR     second-rtr.it-sirius.any.
EOF

    # Зона 100.168.192.in-addr.arpa
    sudo tee /etc/bind/db.100.168.192 > /dev/null <<EOF
\$TTL    604800
@       IN      SOA     it-sirius.any. admin.it-sirius.any. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      first-srv.it-sirius.any.
1       IN      PTR     first-rtr.it-sirius.any.
2       IN      PTR     first-srv.it-sirius.any.
EOF

    # Зона 200.168.192.in-addr.arpa
    sudo tee /etc/bind/db.200.168.192 > /dev/null <<EOF
\$TTL    604800
@       IN      SOA     it-sirius.any. admin.it-sirius.any. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      first-srv.it-sirius.any.
1       IN      PTR     first-rtr.it-sirius.any.
14      IN      PTR     first-cli.it-sirius.any.
EOF

    # Зона 6.168.192.in-addr.arpa
    sudo tee /etc/bind/db.6.168.192 > /dev/null <<EOF
\$TTL    604800
@       IN      SOA     it-sirius.any. admin.it-sirius.any. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      first-srv.it-sirius.any.
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