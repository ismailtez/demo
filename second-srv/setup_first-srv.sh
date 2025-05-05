#!/bin/bash

# Проверка root
if [ "$(id -u)" != "0" ]; then
    echo "❌ Запускайте от sudo"
    exit 1
fi

echo "🔄 Начинаем полную настройку системы..."

# --- Шаг 1: Установка имени хоста ---
set_hostname() {
    echo "Введите имя машины (например, First-SRV):"
    read -r hostname
    hostnamectl set-hostname "$hostname"
    echo "✅ Имя изменено на $hostname"
}
set_hostname

# --- Шаг 2: Создание пользователя sshuser ---
create_sshuser() {
    useradd sshuser -u 1010 -m -s /bin/bash || true
    echo "Установите пароль для sshuser:"
    passwd sshuser
    echo "%sshuser ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
    echo "✅ Пользователь sshuser создан и добавлен в sudoers."
}
create_sshuser

# --- Шаг 3: Настройка SSH ---
setup_ssh() {
    apt update -y && apt install -y openssh-server
    tee /etc/ssh/sshd_config > /dev/null <<'EOF'
Port 2024
MaxAuthTries 2
AllowUsers sshuser
PermitRootLogin no
Banner /root/banner
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem       sftp    /usr/lib/openssh/sftp-server
EOF
    echo "Authorized access only" > /root/banner
    systemctl restart ssh
    echo "✅ SSH перезапущен. Порт: 2024, пользователь: sshuser"
}
setup_ssh

# --- Шаг 4: Удаление старого BIND9 ---
remove_bind9() {
    systemctl stop bind9 2>/dev/null || true
    apt purge -y bind9 bind9utils dnsutils 2>/dev/null || true
    rm -rf /etc/bind /var/cache/bind /var/log/bind
    apt autoremove -y
    echo "BIND9 удален (если был)"
}
remove_bind9

# --- Шаг 5: Установка BIND9 ---
install_bind9() {
    apt install -y bind9 bind9utils dnsutils
    mkdir -p /etc/bind/zones
    echo "✅ BIND9 установлен"
}
install_bind9

# --- Шаг 6: named.conf.options ---
configure_named_options() {
    tee /etc/bind/named.conf.options > /dev/null <<'EOF'
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
    forwarders { 8.8.8.8; };
    dnssec-validation auto;
    listen-on-v6 { any; };
};
EOF
    echo "named.conf.options настроен"
}
configure_named_options

# --- Шаг 7: named.conf.local с зонами ---
configure_named_local() {
    tee /etc/bind/named.conf.local > /dev/null <<'EOF'
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
    echo "named.conf.local настроен"
}
configure_named_local

# --- Шаг 8: Прямая зона it-sirius.any ---
create_zone_file_it_sirius() {
    tee /etc/bind/zones/db.it-sirius.any > /dev/null <<'EOF'
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
first-rtr       IN      A       172.16.4.2
first-rtr       IN      A       192.168.100.1
first-cli       IN      A       192.168.200.14
second-rtr      IN      A       172.16.5.2
second-srv      IN      A       192.168.6.2

moodle          IN      CNAME   second-srv.it-sirius.any.
wiki            IN      CNAME   second-srv.it-sirius.any.
EOF
    echo "Зона it-sirius.any создана"
}

# --- Шаг 9: Обратные зоны ---
create_reverse_zones() {
    tee /etc/bind/zones/db.4.16.172 > /dev/null <<'EOF'
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

    tee /etc/bind/zones/db.5.16.172 > /dev/null <<'EOF'
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

    tee /etc/bind/zones/db.100.168.192 > /dev/null <<'EOF'
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

    tee /etc/bind/zones/db.200.168.192 > /dev/null <<'EOF'
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

    tee /etc/bind/zones/db.6.168.192 > /dev/null <<'EOF'
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

    echo "Обратные зоны созданы"
}

# --- Шаг 10: Проверка и запуск BIND9 ---
check_and_start_bind9() {
    named-checkconf
    named-checkzone it-sirius.any /etc/bind/zones/db.it-sirius.any
    named-checkzone 4.16.172.in-addr.arpa /etc/bind/zones/db.4.16.172
    named-checkzone 5.16.172.in-addr.arpa /etc/bind/zones/db.5.16.172
    named-checkzone 6.168.192.in-addr.arpa /etc/bind/zones/db.6.168.192
    named-checkzone 100.168.192.in-addr.arpa /etc/bind/zones/db.100.168.192
    named-checkzone 200.168.192.in-addr.arpa /etc/bind/zones/db.200.168.192

    systemctl enable bind9
    systemctl restart bind9
    echo "✅ DNS-сервер запущен"
}
check_and_start_bind9

# --- Шаг 11: Настройка resolv.conf ---
configure_resolv_conf() {
    echo 'nameserver 192.168.100.2' > /etc/resolv.conf
    echo 'search it-sirius.any' >> /etc/resolv.conf
    echo "✅ /etc/resolv.conf обновлён"
}
configure_resolv_conf

# --- Шаг 12: Настройка rsyslog как сервера логов ---
setup_rsyslog_server() {
    apt install -y rsyslog
    mkdir -p /opt
    tee /etc/rsyslog.conf > /dev/null <<'EOF'
module(load="imudp")
input(type="imudp" port="514")
module(load="imtcp")
input(type="imtcp" port="514")

$WorkDirectory /var/spool/rsyslog
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
include(file="/etc/rsyslog.d/*.conf" mode="optional")
$OmitLocalLogging no
$IMJournalStateFile imjournal.state
EOF

    tee /etc/rsyslog.d/remote-logs.conf > /dev/null <<'EOF'
$template RemoteLogs,"/opt/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& ~
EOF

    systemctl restart rsyslog
    echo "✅ Rsyslog сервер настроен"
}
setup_rsyslog_server

# --- Шаг 13: Настройка ротации логов ---
setup_logrotate() {
    tee /etc/logrotate.d/rsyslog-central > /dev/null <<'EOF'
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
    echo "✅ Ротация логов настроена"
}

# --- Шаг 14: Настройка chrony ---
setup_chrony() {
    apt install -y chrony
    sed -i '/^server/d' /etc/chrony/chrony.conf
    echo "server 172.16.4.2 iburst" >> /etc/chrony/chrony.conf
    systemctl restart chrony
    echo "✅ Chrony настроен"
}
setup_chrony

# --- Шаг 15: Установка и настройка Nginx + сертификаты ---
setup_nginx() {
    apt install -y nginx openssl libgost-astra
    mkdir -p ~/certs && cd ~/certs || exit

    # RSA-сертификаты
    openssl genrsa -out moodle.key 2048
    openssl req -x509 -key moodle.key -days 365 -out moodle.crt
    openssl genrsa -out mediawiki.key 2048
    openssl req -x509 -key mediawiki.key -days 365 -out mediawiki.crt
    openssl genrsa -out mon.key 2048
    openssl req -x509 -key mon.key -days 365 -out mon.crt

    # Копируем в ssl
    mkdir -p /etc/nginx/ssl
    cp *.crt *.key /etc/nginx/ssl/

    # Конфигурация сайтов
    tee /etc/nginx/sites-available/moodle.conf > /dev/null <<'EOF'
server {
    listen 443 ssl;
    server_name moodle.it-sirius.any;
    ssl_certificate /etc/nginx/ssl/moodle.crt;
    ssl_certificate_key /etc/nginx/ssl/moodle.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        proxy_pass http://localhost:8888;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
EOF

    tee /etc/nginx/sites-available/mediawiki.conf > /dev/null <<'EOF'
server {
    listen 443 ssl;
    server_name wiki.it-sirius.any;
    ssl_certificate /etc/nginx/ssl/mediawiki.crt;
    ssl_certificate_key /etc/nginx/ssl/mediawiki.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        proxy_pass http://wiki.it-sirius.any:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
EOF

    tee /etc/nginx/sites-available/mon.conf > /dev/null <<'EOF'
server {
    listen 443 ssl;
    server_name mon.it-sirius.any;
    ssl_certificate /etc/nginx/ssl/mon.crt;
    ssl_certificate_key /etc/nginx/ssl/mon.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_xwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
EOF

    # Активируем конфиги
    ln -sf /etc/nginx/sites-available/moodle.conf /etc/nginx/sites-enabled/
    ln -sf /etc/nginx/sites-available/mediawiki.conf /etc/nginx/sites-enabled/
    ln -sf /etc/nginx/sites-available/mon.conf /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default

    nginx -t && systemctl restart nginx
    echo "✅ Nginx настроен"
}
setup_nginx

# --- Шаг 16: Настройка Docker Compose для мониторинга ---
setup_docker_compose_monitoring() {
    mkdir -p ~/monitoring
    tee ~/monitoring/docker-compose.yml > /dev/null <<'DOCKER_COMPOSE'
version: '3'
services:
  prometheus:
    image: prom/prometheus:v2.37.0
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:8.5.0
    container_name: grafana
    environment:
      GF_SECURITY_ADMIN_PASSWORD: "P@ssw0rd"
    ports:
      - "3000:3000"
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:v1.3.1
    container_name: node-exporter
    ports:
      - "9101:9100"
    networks:
      - monitoring

  mktxp:
    image: ghcr.io/akpw/mktxp:latest
    container_name: mktxp
    volumes:
      - ./mktxp.conf:/home/mktxp/mktxp.conf:ro
    ports:
      - "49090:49090"
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
DOCKER_COMPOSE

    tee ~/monitoring/mktxp.conf > /dev/null <<'EOF'
[router1]
enabled = True
hostname = 192.168.65.2
port = 8728
username = admin
password = 127.0.0.1
EOF

    tee ~/monitoring/prometheus.yml > /dev/null <<'PROMETHEUS'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter_second'
    static_configs:
      - targets: ['Second-SRV_IP:9100']

  - job_name: 'node_exporter_first'
    static_configs:
      - targets: ['localhost:9101']

  - job_name: 'mktxp'
    static_configs:
      - targets: ['mktxp:49090']
PROMETHEUS

    echo "✅ Docker Compose для мониторинга создан"
}

# --- Шаг 17: Docker Compose для Moodle ---
setup_docker_compose_moodle() {
    mkdir -p ~/moodle
    tee ~/moodle/docker-compose.yml > /dev/null <<'DOCKER_COMPOSE'
version: '2'
services:
  mariadb:
    image: docker.io/bitnami/mariadb:11.3
    container_name: mariadb
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
      - MARIADB_USER=moodle
      - MARIADB_PASSWORD=P@ssw0rd
      - MARIADB_DATABASE=moodledb
      - MARIADB_CHARACTER_SET=utf8mb4
      - MARIADB_COLLATE=utf8mb4_unicode_ci
    volumes:
      - 'mariadb_data:/bitnami/mariadb'
    ports:
      - "3306:3306"

  moodle:
    image: docker.io/bitnami/moodle:4.4
    container_name: moodle
    ports:
      - "80:8080"
      - "443:8443"
    environment:
      - MOODLE_DATABASE_HOST=mariadb
      - MOODLE_DATABASE_PORT_NUMBER=3306
      - MOODLE_DATABASE_USER=moodle
      - MOODLE_DATABASE_NAME=moodledb
      - MOODLE_DATABASE_PASSWORD=P@ssw0rd
      - MOODLE_USERNAME=admin
      - MOODLE_PASSWORD=P@ssw0rd
    volumes:
      - 'moodle_data:/bitnami/moodle'
      - 'moodledata_data:/bitnami/moodledata'
    depends_on:
      - mariadb
volumes:
  mariadb_data:
    driver: local
  moodle_data:
    driver: local
  moodledata_data:
    driver: local
DOCKER_COMPOSE

    echo "✅ Docker Compose для Moodle создан"
}

# --- Шаг 18: Перезапуск всех служб ---
restart_services() {
    systemctl restart nginx
    systemctl restart chrony
    systemctl restart rsyslog
    systemctl restart bind9
    echo "✅ Все службы перезапущены"
}

# --- Шаг 19: Директории ~/moodle и ~/monitoring ---
setup_directories() {
    mkdir -p ~/moodle ~/monitoring ~/monitoring/dashboards
    echo "✅ Директории ~/moodle и ~/monitoring созданы"
}

# --- Вызов всех функций ---
main() {
    setup_directories
    set_hostname
    create_sshuser
    setup_ssh
    remove_bind9
    install_bind9
    configure_named_options
    configure_named_local
    create_zone_file_it_sirius
    create_reverse_zones
    check_and_start_bind9
    setup_rsyslog_server
    setup_logrotate
    setup_chrony
    setup_nginx
    setup_docker_compose_monitoring
    setup_docker_compose_moodle
    restart_services
    echo "🎉 Полная настройка завершена!"
}
main