#!/bin/bash

DEVICE="/dev/sda"
MOUNT_DIR="/srv/nfs"

# Получаем список свободных пространств
echo "[+] Ищем самый большой свободный блок..."
FREE_BLOCKS=$(sudo parted -m $DEVICE unit MB print free | grep "free")

# Найдём самый большой блок
BIGGEST_BLOCK=$(echo "$FREE_BLOCKS" | awk -F: '{
    start=$2; end=$3;
    gsub("MB","",start); gsub("MB","",end);
    size=end - start;
    print size":"start":"end
}' | sort -nr | head -n1)

SIZE=$(echo $BIGGEST_BLOCK | cut -d: -f1)
START=$(echo $BIGGEST_BLOCK | cut -d: -f2)
END=$(echo $BIGGEST_BLOCK | cut -d: -f3)

echo "[+] Самый большой свободный блок: $START MB - $END MB ($SIZE MB)"

# Создаём новый раздел
echo "[+] Создаём новый раздел..."
sudo parted -s $DEVICE mkpart primary ext4 ${START}MB ${END}MB

# Обновляем таблицу разделов
sleep 3

# Находим имя нового раздела
LAST_PART=$(lsblk -nr $DEVICE | tail -n1 | awk '{print $1}')
NEW_PART="/dev/$LAST_PART"

echo "[+] Новый раздел: $NEW_PART"

# Форматируем в ext4
echo "[+] Форматируем $NEW_PART в ext4..."
sudo mkfs.ext4 $NEW_PART

# Монтируем
sudo mkdir -p $MOUNT_DIR
sudo chmod 777 $MOUNT_DIR
sudo mount $NEW_PART $MOUNT_DIR

# UUID и fstab
UUID=$(sudo blkid -s UUID -o value $NEW_PART)
echo "[+] UUID: $UUID"
echo "UUID=$UUID $MOUNT_DIR ext4 defaults 0 0" | sudo tee -a /etc/fstab

# Установка и настройка NFS
sudo apt update
sudo apt install -y nfs-kernel-server

echo "$MOUNT_DIR 192.168.100.0/24(rw,nohide,all_squash,no_subtree_check)" | sudo tee -a /etc/exports

sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server
sudo exportfs -ra

echo "[✓] Готово, брат! Шара на месте."
