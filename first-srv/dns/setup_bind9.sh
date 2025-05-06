#!/bin/bash

set -e

echo "[*] Устанавливаем BIND9..."
apt update
apt install -y bind9 bind9utils bind9-doc

echo "[*] Создаём директорию для зон..."
mkdir -p /etc/bind/zones

echo "[*] Копируем конфиги..."

# named.conf.local
cat > /etc/bind/named.conf.local << 'EOF'
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

zone "67.168.192.in-addr.arpa" {
        type master;
        file "/etc/bind/zones/db.67.168.192";    
};

zone "65.168.192.in-addr.arpa" {
        type master;
        file "/etc/bind/zones/db.65.168.192";
};

zone "66.168.192.in-addr.arpa" {
        type master;
        file "/etc/bind/zones/db.66.168.192";
};
EOF

# named.conf.options
cat > /etc/bind/named.conf.options << 'EOF'
options {
        directory "/var/cache/bind";
        recursion yes;
        allow-recursion {
                192.168.63.0/24;
                192.168.64.0/24;
                192.168.67.0/24;
                192.168.65.0/24;
                192.168.66.0/24;
        };

        forwarders {
                8.8.8.8;
        };

        dnssec-validation auto;
        listen-on-v6 { any; };
};
EOF

echo "[*] Добавляем файлы зон..."

# Шаблонная функция для зоны
add_zone_file() {
  local filename="$1"
  local content="$2"
  echo "$content" > "/etc/bind/zones/$filename"
}

# zone files
add_zone_file db.it-sirius.any "$(cat << 'EOF'
$TTL    604800
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
@       IN      AAAA    ::1
EOF
)"

# Повторим для остальных зон
add_zone_file db.63.168.192 "$(cat << 'EOF'
$TTL    604800
@       IN      SOA     it-sirius.any. admin.it-sirius.any. (
                              1
                         604800
                          86400
                        2419200
                         604800 )
;
@       IN      NS      first-srv.it-sirius.any.
3       IN      PTR     first-rtr.it-sirius.any.
EOF
)"

add_zone_file db.64.168.192 "$(cat << 'EOF'
$TTL    604800
@       IN      SOA     it-sirius.any. admin.it-sirius.any. (
                              1
                         604800
                          86400
                        2419200
                         604800 )
;
@       IN      NS      first-srv.it-sirius.any.
3       IN      PTR     second-rtr.it-sirius.any.
EOF
)"

add_zone_file db.67.168.192 "$(cat << 'EOF'
$TTL    604800
@       IN      SOA     it-sirius.any. admin.it-sirius.any. (
                              1
                         604800
                          86400
                        2419200
                         604800 )
;
@       IN      NS      first-srv.it-sirius.any.
2       IN      PTR     second-rtr.it-sirius.any.
3       IN      PTR     second-srv.it-sirius.any.
EOF
)"

add_zone_file db.65.168.192 "$(cat << 'EOF'
$TTL    604800
@       IN      SOA     it-sirius.any. admin.it-sirius.any. (
                              1
                         604800
                          86400
                        2419200
                         604800 )
;
@       IN      NS      first-srv.it-sirius.any.
2       IN      PTR     first-rtr.it-sirius.any.
3       IN      PTR     first-srv.it-sirius.any.
EOF
)"

add_zone_file db.66.168.192 "$(cat << 'EOF'
$TTL    604800
@       IN      SOA     it-sirius.any. admin.it-sirius.any. (
                              1
                         604800
                          86400
                        2419200
                         604800 )
;
@       IN      NS      first-srv.it-sirius.any.
2       IN      PTR     first-rtr.it-sirius.any.
14      IN      PTR     first-cli.it-sirius.any.
EOF
)"

echo "[*] Проверяем конфигурацию..."
named-checkconf
named-checkzone it-sirius.any /etc/bind/zones/db.it-sirius.any

echo "[*] Перезапускаем сервис BIND9..."
systemctl restart bind9
systemctl enable bind9

echo "[+] DNS поднят успешно, брат!"
