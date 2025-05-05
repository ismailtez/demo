#!/bin/bash

DEVICE="/dev/sda"
MOUNT_DIR="/srv/nfsshare"

# 1. Получаем первый свободный диапазон
FREE_LINE=$(sudo parted $DEVICE print free | awk '/Free Space/ {getline; print}')
START=$(echo $FREE_LINE | awk '{print $1}')
END=$(echo $FREE_LINE | awk '{print $2}')

echo "[+] Свободный раздел найден: $START - $END"

# 2. Создаём новый раздел
PARTNUM=$(lsblk -ln $DEVICE | wc -l)
NEW_PART="${DEVICE}$((PARTNUM))"

echo "[+] Создание нового раздела на $NEW_PART..."
sudo parted $DEVICE mkpart primary ext4 $START $END

# 3. Ждём пока система подхватит новый раздел
sleep 3

# 4. Форматируем
echo "[+] Форматирование $NEW_PART в ext4..."
sudo mkfs.ext4 ${NEW_PART}

# 5. Создаём директорию и даём права
echo "[+] Создаём точку монтирования $MOUNT_DIR..."
sudo mkdir -p $MOUNT_DIR
sudo chmod 777 $MOUNT_DIR

# 6. Монтируем
echo "[+] Монтируем $NEW_PART в $MOUNT_DIR..."
sudo mount ${NEW_PART} $MOUNT_DIR

# 7. Получаем UUID и правим fstab
UUID=$(sudo blkid -s UUID -o value ${NEW_PART})
echo "[+] UUID нового раздела: $UUID"
echo "UUID=${UUID} $MOUNT_DIR ext4 defaults 0 0" | sudo tee -a /etc/fstab

# 8. Устанавливаем и настраиваем NFS
echo "[+] Установка NFS-сервера..."
sudo apt update
sudo apt install -y nfs-kernel-server

echo "[+] Настройка экспорта каталога..."
echo "$MOUNT_DIR 192.168.100.0/26(rw,nohide,all_squash,no_subtree_check)" | sudo tee -a /etc/exports

sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server
sudo exportfs -ra

echo "[✓] Готово! NFS-шара работает по адресу: $MOUNT_DIR"
