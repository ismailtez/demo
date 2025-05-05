#!/bin/bash

# Проверка root
if [ "$(id -u)" != "0" ]; then
    echo "❌ Запускайте от sudo"
    exit 1
fi

echo "🔄 Начинаем установку и настройку BIND9..."

# --- Функция удаления старого BIND ---
remove_bind9() {
    echo "🗑 Удаление старой версии BIND9..."
    sudo systemctl stop bind9 2>/dev/null || true
    sudo systemctl disable bind9 2>/dev/null || true
    sudo apt purge -y bind9 bind9utils dnsutils 2>/dev/null || true
    sudo rm -rf /etc/bind /var/cache/bind /var/log/bind
    sudo apt autoremove -y
    echo "✅ BIND9 удален (если был)"
}

# --- Установка BIND9 ---
install_bind9() {
    echo "📦 Установка BIND9..."
    sudo apt update -y
    sudo apt install -y bind9 bind9utils dnsutils
    sudo mkdir -p /etc/bind/zones
    echo "✅ BIND9 установлен"
}

# --- Настройка named.conf.options ---
configure_named_conf_options() {
    echo "🔧 Настройка named.conf.options..."
    sudo tee /etc/bind/named.conf.options > /dev/null <<'EOF'
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-transfer { none; };
    allow-recursion {
        192.168.63.0/24;
        192.168.64.0/24;
        192.168.65.0/24;
        192.168.66.0/24;
        192.168.67.0/24;
    };

    forwarders {
        8.8.8.8;
    };

    dnssec-validation auto;

    listen-on-v6 { any; };
};
EOF
    echo "✅ named.conf.options настроен"
}

# --- Настройка named.conf.local с прямой и обратными зонами ---
configure_named_conf_local() {
    echo "🔧 Настройка named.conf.local..."
    sudo tee /etc/bind/named.conf.local > /dev/null <<'EOF'
zone "it-sirius.any" {
    type master;
    file "/etc/bind/zones/db.it-sirius.any";
};

zone "63.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.63.168.192";
};

zone "64.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.64.168.192";
};

zone "65.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.65.168.192";
};

zone "66.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.66.168.192";
};

zone "67.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.67.168.192";
};
EOF
    echo "✅ named.conf.local обновлён"
}

# --- Прямая зона it-sirius.any ---
create_zone_file_it_sirius() {
    echo "🌐 Создание прямой зоны it-sirius.any..."
    sudo tee /etc/bind/zones/db.it-sirius.any > /dev/null <<'EOF'
\$TTL    604800
@       IN      SOA     first-srv.it-sirius.any. admin.it-sirius.any. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      first-srv.it-sirius.any.

first-srv       IN      A       192.168.65.3
first-rtr       IN      A       192.168.65.2
first-rtr       IN      A       192.168.63.3
first-rtr       IN      A       192.168.66.2
first-cli       IN      A       192.168.66.14
second-rtr      IN      A       192.168.64.3
second-rtr      IN      A       192.168.67.2
second-srv      IN      A       192.168.67.3

moodle          IN      CNAME   first-srv.it-sirius.any.
wiki            IN      CNAME   second-srv.it-sirius.any.
mon             IN      CNAME   first-srv.it-sirius.any.
EOF
    echo "✅ Прямая зона it-sirius.any создана"
}

# --- Обратная зона 63.168.192.in-addr.arpa ---
create_reverse_zone_63() {
    echo "🔙 Создание обратной зоны 63.168.192.in-addr.arpa..."
    sudo tee /etc/bind/zones/db.63.168.192 > /dev/null <<'EOF'
\$TTL    604800
@       IN      SOA     first-srv.it-sirius.any. admin.it-sirius.any. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      first-srv.it-sirius.any.

3       IN      PTR     first-srv.it-sirius.any.
EOF
    echo "✅ Обратная зона 63.168.192.in-addr.arpa создана"
}

# --- Обратная зона 64.168.192.in-addr.arpa ---
create_reverse_zone_64() {
    echo "🔙 Создание обратной зоны 64.168.192.in-addr.arpa..."
    sudo tee /etc/bind/zones/db.64.168.192 > /dev/null <<'EOF'
\$TTL    604800
@       IN      SOA     first-srv.it-sirius.any. admin.it-sirius.any. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      first-srv.it-sirius.any.

3       IN      PTR     second-rtr.it-sirius.any.
EOF
    echo "✅ Обратная зона 64.168.192.in-addr.arpa создана"
}

# --- Обратная зона 65.168.192.in-addr.arpa ---
create_reverse_zone_65() {
    echo "🔙 Создание обратной зоны 65.168.192.in-addr.arpa..."
    sudo tee /etc/bind/zones/db.65.168.192 > /dev/null <<'EOF'
\$TTL    604800
@       IN      SOA     first-srv.it-sirius.any. admin.it-sirius.any. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      first-srv.it-sirius.any.

2       IN      PTR     first-rtr.it-sirius.any.
3       IN      PTR     first-srv.it-sirius.any.
EOF
    echo "✅ Обратная зона 65.168.192.in-addr.arpa создана"
}

# --- Обратная зона 66.168.192.in-addr.arpa ---
create_reverse_zone_66() {
    echo "🔙 Создание обратной зоны 66.168.192.in-addr.arpa..."
    sudo tee /etc/bind/zones/db.66.168.192 > /dev/null <<'EOF'
\$TTL    604800
@       IN      SOA     first-srv.it-sirius.any. admin.it-sirius.any. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      first-srv.it-sirius.any.

2       IN      PTR     first-rtr.it-sirius.any.
14      IN      PTR     first-cli.it-sirius.any.
EOF
    echo "✅ Обратная зона 66.168.192.in-addr.arpa создана"
}

# --- Обратная зона 67.168.192.in-addr.arpa ---
create_reverse_zone_67() {
    echo "🔙 Создание обратной зоны 67.168.192.in-addr.arpa..."
    sudo tee /etc/bind/zones/db.67.168.192 > /dev/null <<'EOF'
\$TTL    604800
@       IN      SOA     first-srv.it-sirius.any. admin.it-sirius.any. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      first-srv.it-sirius.any.

2       IN      PTR     second-rtr.it-sirius.any.
3       IN      PTR     second-srv.it-sirius.any.
EOF
    echo "✅ Обратная зона 67.168.192.in-addr.arpa создана"
}

# --- Проверка конфига и зон ---
check_configuration() {
    echo "🔍 Проверка конфигурации BIND9..."
    sudo named-checkconf
    sudo named-checkzone it-sirius.any /etc/bind/zones/db.it-sirius.any

    sudo named-checkzone 63.168.192.in-addr.arpa /etc/bind/zones/db.63.168.192
    sudo named-checkzone 64.168.192.in-addr.arpa /etc/bind/zones/db.64.168.192
    sudo named-checkzone 65.168.192.in-addr.arpa /etc/bind/zones/db.65.168.192
    sudo named-checkzone 66.168.192.in-addr.arpa /etc/bind/zones/db.66.168.192
    sudo named-checkzone 67.168.192.in-addr.arpa /etc/bind/zones/db.67.168.192
    echo "✅ Все зоны прошли проверку"
}

# --- Перезапуск службы BIND9 ---
restart_bind9() {
    echo "🔁 Перезапуск BIND9..."
    sudo systemctl restart bind9
    sudo systemctl enable bind9
    echo "✅ Служба BIND9 перезапущена и добавлена в автозагрузку"
}

# --- Настройка resolv.conf ---
configure_resolv_conf() {
    echo "🔧 Настройка /etc/resolv.conf..."
    sudo tee /etc/resolv.conf > /dev/null <<'EOF'
nameserver 192.168.65.3
search it-sirius.any
EOF
    echo "✅ /etc/resolv.conf обновлён"
}

# --- Основной процесс ---
main() {
    remove_bind9
    install_bind9
    configure_named_conf_options
    configure_named_conf_local
    create_zone_file_it_sirius
    create_reverse_zone_63
    create_reverse_zone_64
    create_reverse_zone_65
    create_reverse_zone_66
    create_reverse_zone_67
    check_configuration
    restart_bind9
    configure_resolv_conf
    echo "🎉 Настройка DNS-сервера завершена!"
}

main