#!/bin/bash

# Обновление и установка зависимостей
sudo apt update && sudo apt install -y nginx openssl libgost-astra

# Создание директории для сертификатов
mkdir -p ~/certs && cd ~/certs

# Генерация GOST-2012_256 сертификата (для Moodle)
openssl genpkey -algorithm gost2012_256 -pkeyopt paramset:A -out moodle.pem
openssl req -x509 -key moodle.pem -days 365 -out moodle.crt

# Генерация GOST-2012_256 сертификата (для Moodle)
openssl genpkey -algorithm gost2012_256 -pkeyopt paramset:A -out mediawiki.key
openssl req -x509 -key mediawiki.key -days 365 -out mediawiki.crt


# Копируем в /etc/nginx/ssl/
sudo mkdir -p /etc/nginx/ssl
sudo cp moodle.pem moodle.crt mediawiki.key mediawiki.crt /etc/nginx/ssl/

# Удаляем дефолтный сайт
sudo rm -f /etc/nginx/sites-enabled/default

# Конфигурация для Moodle через ГОСТ
sudo tee /etc/nginx/sites-available/moodle.conf > /dev/null <<'EOF'
server {
    listen 443 ssl;
    #listen 80;
    server_name moodle.it-sirius.any;
    ssl_certificate /etc/nginx/ssl/moodle.crt;
    ssl_certificate_key /etc/nginx/ssl/moodle.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
location / {
    proxy_pass http://localhost:8888;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-Proto https;
    proxy_set_header        SSL_PROTOCOL $ssl_protocol;
    }
}
EOF

# Конфигурация для Mediawiki через RSA
sudo tee /etc/nginx/sites-available/mediawiki.conf > /dev/null <<'EOF'
server {
    listen 443 ssl;
    #listen 80;
    server_name moodle.it-sirius.any;
    ssl_certificate /etc/nginx/ssl/mediawiki.crt;
    ssl_certificate_key /etc/nginx/ssl/mediawiki.key;
    ssl_protocols TLSv1.2 TLSv1.3;
location / {
    proxy_pass http://localhost:8888;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-Proto https;
    proxy_set_header        SSL_PROTOCOL $ssl_protocol;
    }
}
EOF

# Активируем сайты
sudo ln -sf /etc/nginx/sites-available/moodle.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/mediawiki.conf /etc/nginx/sites-enabled/

# Проверяем конфиг и перезапускаем Nginx
sudo nginx -t
sudo systemctl restart nginx