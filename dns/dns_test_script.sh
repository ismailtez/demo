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

# named.conf.options
cat > /etc/bind/named.conf.options << 'EOF'
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
)"

# Повторим для остальных зон
add_zone_file db.4.16.172 "$(cat << 'EOF'
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
EOF
)"

add_zone_file db.5.16.172 "$(cat << 'EOF'
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
EOF
)"

add_zone_file db.6.168.192 "$(cat << 'EOF'
$TTL    604800
@       IN      SOA     it-sirius.any. admin.it-sirius.any. (
                              1
                         604800
                          86400
                        2419200
                         604800 )
;
@       IN      NS      first-srv.it-sirius.any.
1       IN      PTR     second-rtr.it-sirius.any.
2       IN      PTR     second-srv.it-sirius.any.
EOF
)"

add_zone_file db.100.168.192 "$(cat << 'EOF'
$TTL    604800
@       IN      SOA     it-sirius.any. admin.it-sirius.any. (
                              1
                         604800
                          86400
                        2419200
                         604800 )
;
@       IN      NS      first-srv.it-sirius.any.
1       IN      PTR     first-rtr.it-sirius.any.
2       IN      PTR     first-srv.it-sirius.any.
EOF
)"

add_zone_file db.200.168.192 "$(cat << 'EOF'
$TTL    604800
@       IN      SOA     it-sirius.any. admin.it-sirius.any. (
                              1
                         604800
                          86400
                        2419200
                         604800 )
;
@       IN      NS      first-srv.it-sirius.any.
1       IN      PTR     first-rtr.it-sirius.any.
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
