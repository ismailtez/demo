#!/bin/bash

DEVICE="/dev/sda"
MOUNT_DIR="/srv/nfsshare"

echo "[!] Удаляем шару NFS и всё, что с ней связано..."

# Получаем смонтированный раздел для этой шары
MOUNTED_PART=$(mount | grep "$MOUNT_DIR" | awk '{print $1}')

# 1. Отмонтировать
if mountpoint -q "$MOUNT_DIR"; then
    echo "[+] Размонтируем $MOUNT_DIR"
    sudo umount "$MOUNT_DIR"
else
    echo "[-] $MOUNT_DIR не смонтирован"
fi

# 2. Удалить строку из /etc/fstab
echo "[+] Удаляем запись из /etc/fstab"
sudo sed -i "\|$MOUNT_DIR|d" /etc/fstab

# 3. Удалить запись из /etc/exports
echo "[+] Удаляем экспорт из /etc/exports"
sudo sed -i "\|$MOUNT_DIR|d" /etc/exports

# 4. Обновить экспорт
sudo exportfs -ra

# 5. Остановить и отключить NFS
echo "[+] Останавливаем nfs-kernel-server"
sudo systemctl stop nfs-kernel-server
sudo systemctl disable nfs-kernel-server

# 6. Удалить директорию
if [ -d "$MOUNT_DIR" ]; then
    echo "[+] Удаляем директорию $MOUNT_DIR"
    sudo rm -rf "$MOUNT_DIR"
fi

# 7. Удалить последний созданный раздел
if [ -n "$MOUNTED_PART" ]; then
    PART_NAME=$(basename "$MOUNTED_PART")
    PART_NUM=$(echo "$PART_NAME" | sed "s/[^0-9]*//g")

    echo "[+] Удаляем раздел /dev/${PART_NAME}"
    sudo parted -s $DEVICE rm $PART_NUM
else
    echo "[-] Не найден смонтированный раздел, удаление раздела пропущено"
fi

echo "[✓] Всё нахрен удалено, брат. Чисто."
