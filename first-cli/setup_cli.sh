#!/bin/bash

# Установка имени машины
set_hostname() {
    echo "Введите имя машины (например, First-SRV):"
    read -r hostname
    sudo hostnamectl set-hostname "$hostname"
    echo "Имя машины изменено на: $hostname"
}

# Создание пользователя sshuser
create_nfs() {
    sudo apt update
    sudo apt install nfs-common -y
    sudo mkdir -p /mnt/nfs
    sudo mount 192.168.100.2:/srv/nfs /mnt/nfs
    echo "192.168.100.2:/srv/nfs /mnt/nfs nfs rw,sync,hard,intr 0 0" | sudo tee -a /etc/fstab > /dev/null
}

install_yandex() {
    sudo apt update
    sudo apt install yandex-browser-stable
}

# Основной процесс
main() {
    set_hostname
    create_nfs
    install_yandex
}

main