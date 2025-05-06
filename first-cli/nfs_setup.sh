#!/bin/bash

# Обновление пакетов
sudo apt update

# Установка клиента NFS
sudo apt install -y nfs-common

# Создание директории для монтирования
sudo mkdir -p /mnt/nfs

# Монтирование NFS-сервера
sudo mount 192.168.100.2:/srv/nfs /mnt/nfs

# Добавление записи в /etc/fstab, если её там ещё нет
FSTAB_ENTRY="192.168.100.2:/srv/nfs /mnt/nfs nfs rw,sync,hard,intr 0 0"
if ! grep -qs "$FSTAB_ENTRY" /etc/fstab; then
    echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab
fi

echo "✅ Всё готово. NFS смонтирован и добавлен в автозагрузку."
