#!/bin/bash

# Проверка root
if [ "$(id -u)" != "0" ]; then
    echo "❌ Запускайте от sudo"
    exit 1
fi

echo "🔄 Остановка службы nginx..."
sudo systemctl stop nginx 2>/dev/null || true

echo "🗑 Удаление пакета nginx..."
sudo apt purge -y nginx nginx-common nginx-full 2>/dev/null || true

echo "🧹 Удаление автозагрузки..."
sudo systemctl disable nginx 2>/dev/null || true

echo "📁 Удаление конфигов..."
sudo rm -rf /etc/nginx/
sudo rm -rf /etc/default/nginx
sudo rm -rf /etc/apparmor.d/nginx

echo "📂 Удаление логов и кэша..."
sudo rm -rf /var/log/nginx/
sudo rm -rf /var/cache/nginx/

echo "💣 Удаление сертификатов (если были)..."
sudo rm -rf ~/certs/
sudo rm -rf /root/certs/

echo "✅ Чистка системы..."
sudo apt autoremove -y
sudo apt clean

echo "🎉 Nginx полностью удален!"