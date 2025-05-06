#!/bin/bash

# Проверка на root
if [ "$(id -u)" != "0" ]; then
    echo "❌ Запускайте от имени root (sudo)"
    exit 1
fi

timedatectl set-timezone Europe/Moscow

timedatectl

apt install -y chrony

cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak

sed -i '/^server/d' /etc/chrony/chrony.conf

echo "server 192.168.65.2 iburst" >> /etc/chrony/chrony.conf

systemctl restart chrony

chronyc sources -v