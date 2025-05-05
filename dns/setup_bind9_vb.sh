#!/bin/bash

# Проверка на root
if [ "$(id -u)" != "0" ]; then
    echo "❌ Запускайте от sudo"
    exit 1
fi

echo "🔄 Начинаем настройку DNS с нуля..."

# --- Шаг 1: Удаление старого bind9 ---
remove_bind9() {
    echo "🗑 Удаление старой версии BIND..."
    sudo systemctl stop bind9 2>/dev/null || true
    sudo apt purge -y bind9 bind9utils dnsutils 2>/dev/null || true
    sudo rm -rf /etc/bind /var/cache/bind /var/log/bind
    sudo apt autoremove -y
    echo "✅ BIND удалён (если был)"
}
remove_bind9

# --- Шаг 2: Установка нового bind9 ---
install_bind9() {
    echo "📦 Обновление системы и установка BIND9..."
    sudo apt update -y
    sudo apt install -y bind9 bind9utils dnsutils
    sudo mkdir -p /etc/bind/zones
    echo "✅ BIND установлен"
}
install_bind9

# --- Шаг 3: named.conf.options ---
configure_named_conf_options() {
    echo "🔧 Настройка /etc/bind/named.conf.options..."
    sudo tee /etc/bind/named.conf.options > /dev/null <<'EOF'
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
    echo "✅ named.conf.options создан"
}
configure_named_conf_options

# --- Шаг 4: named.conf.local ---
configure_named_conf_local() {
    echo "🔧 Настройка /etc/bind/named.conf.local..."
    sudo tee /etc/bind/named.conf.local > /dev/null <<'EOF'
// Do any local configuration here

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

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
    echo "✅ named.conf.local создан"
}
configure_named_conf_local

# --- Шаг 5: Прямая зона it-sirius.any ---
create_zone_file_it_sirius() {
    echo "🌐 Создание прямой зоны it-sirius.any..."
    sudo tee /etc/bind/zones/db.it-sirius.any > /dev/null <<'EOF'
;
; BIND data file for local loopback interface
;
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
moodle          IN      CNAME   first-rtr.it-sirius.any.
wiki            IN      CNAME   first-rtr.it-sirius.any.
@       IN      AAAA    ::1
EOF
    echo "✅ Прямая зона db.it-sirius.any создана"
}

# --- Шаг 6: Обратные зоны ---

### db.100.168.192
create_reverse_100_168_192() {
    echo "🔙 Создание обратной зоны 100.168.192.in-addr.arpa..."
    sudo tee /etc/bind/zones/db.100.168.192 > /dev/null <<'EOF'
;
; BIND reverse data file for local loopback interface
;
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
    echo "✅ db.100.168.192 создан"
}

### db.200.168.192
create_reverse_200_168_192() {
    echo "🔙 Создание обратной зоны 200.168.192.in-addr.arpa..."
    sudo tee /etc/bind/zones/db.200.168.192 > /dev/null <<'EOF'
;
; BIND reverse data file for local loopback interface
;
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
    echo "✅ db.200.168.192 создан"
}

### db.4.16.172
create_reverse_4_16_172() {
    echo "🔙 Создание обратной зоны 4.16.172.in-addr.arpa..."
    sudo tee /etc/bind/zones/db.4.16.172 > /dev/null <<'EOF'
;
; BIND reverse data file for local loopback interface
;
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
    echo "✅ db.4.16.172 создан"
}

### db.5.16.172
create_reverse_5_16_172() {
    echo "🔙 Создание обратной зоны 5.16.172.in-addr.arpa..."
    sudo tee /etc/bind/zones/db.5.16.172 > /dev/null <<'EOF'
;
; BIND reverse data file for local loopback interface
;
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
    echo "✅ db.5.16.172 создан"
}

### db.6.168.192
create_reverse_6_168_192() {
    echo "🔙 Создание обратной зоны 6.168.192.in-addr.arpa..."
    sudo tee /etc/bind/zones/db.6.168.192 > /dev/null <<'EOF'
;
; BIND reverse data file for local loopback interface
;
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
    echo "✅ db.6.168.192 создан"
}

# --- Шаг 7: Проверка всех зон ---
check_zones() {
    echo "🔍 Проверка конфигурации BIND..."
    sudo named-checkconf
    sudo named-checkzone it-sirius.any /etc/bind/zones/db.it-sirius.any

    sudo named-checkzone 100.168.192.in-addr.arpa /etc/bind/zones/db.100.168.192
    sudo named-checkzone 200.168.192.in-addr.arpa /etc/bind/zones/db.200.168.192
    sudo named-checkzone 4.16.172.in-addr.arpa /etc/bind/zones/db.4.16.172
    sudo named-checkzone 5.16.172.in-addr.arpa /etc/bind/zones/db.5.16.172
    sudo named-checkzone 6.168.192.in-addr.arpa /etc/bind/zones/db.6.168.192
    echo "✅ Все зоны проверены"
}

# --- Шаг 8: Перезапуск BIND9 ---
restart_bind9() {
    echo "🔁 Перезапуск службы BIND9..."
    sudo systemctl restart bind9
    sudo systemctl enable bind9
    echo "✅ BIND перезапущен и добавлен в автозагрузку"
}

# --- Шаг 9: Настройка resolv.conf ---
configure_resolv_conf() {
    echo "🔧 Настройка /etc/resolv.conf..."
    echo 'nameserver 192.168.100.2' | sudo tee /etc/resolv.conf > /dev/null
    echo 'search it-sirius.any' | sudo tee -a /etc/resolv.conf > /dev/null
    echo "✅ /etc/resolv.conf обновлён"
}

# --- Основной процесс ---
main() {
    remove_bind9
    install_bind9
    configure_named_conf_options
    configure_named_conf_local
    create_zone_file_it_sirius
    create_reverse_100_168_192
    create_reverse_200_168_192
    create_reverse_4_16_172
    create_reverse_5_16_172
    create_reverse_6_168_192
    check_zones
    restart_bind9
    configure_resolv_conf
    echo "🎉 Настройка BIND9 завершена!"
}
main