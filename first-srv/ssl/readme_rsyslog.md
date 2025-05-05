## НАСТРОЙКА NGINX

https://github.com/xxsbnd/DEMO2025/tree/main?tab=readme-ov-file#настройка-центра-сертификации

https://wiki.astralinux.ru/pages/viewpage.action?pageId=27362269


УСТАНОВКА NGINX НА АСТРА First-SRV

```
sudo apt install nginx
```


СОЗДАНИЕ КЛЮЧЕЙ И СЕРТИФИКАТОВ

```
sudo apt install -y openssl libengine-gost-openssl
sudo apt install -y openssl libgost-astra
mkdir ~/certs
cd certs/
```

ГОСТ
```
sudo openssl genpkey -algorithm gost2012_256 -pkeyopt paramset:A -out moodle.pem
sudo openssl req -x509 -key moodle.pem -days 365 -out moodle.crt
```


НОРМАЛЬНЫЕ СЕРТИФИКАТЫ

```
openssl genrsa -out mediawiki.key 2048
openssl req -x509 -key mediawiki.key -days 365 -out mediawiki.crt

```


ДОБАВЛЕНИЕ PROXY
```
sudo nano /etc/nginx/site-avaliable/mediawiki.conf - конфигурация виртуального сервера для mediawiki
server {
    listen 443 ssl;
    server_name mediawiki.it-sirius.any;
    ssl_certificate /root/certs/mediawiki.crt;
    ssl_certificate_key /root/certs/mediawiki.key;
location / {
    proxy_pass http://localhost:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Real-IP $remote_addr;
proxy_set_header        X-Forwarded-Proto https;
    proxy_set_header        SSL_PROTOCOL $ssl_protocol;
    }
}

```