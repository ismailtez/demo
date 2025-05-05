#!/bin/bash

MOUNT_DIR="/mnt/nfs"
REMOTE_SHARE="192.168.100.2:/srv/nfs"

echo "[!] Откатываем NFS клиент..."

# 1. Размонтировать, если смонтировано
if mountpoint -q "$MOUNT_DIR"; then
    echo "[+] Размонтируем $MOUNT_DIR"
    sudo umount "$MOUNT_DIR"
else
    echo "[-] $MOUNT_DIR не смонтирован"
fi

# 2. Удалить запись из /etc/fstab
echo "[+] Удаляем строку из /etc/fstab"
sudo sed -i "\|$REMOTE_SHARE|d" /etc/fstab

# 3. Удалить директорию
if [ -d "$MOUNT_DIR" ]; then
    echo "[+] Удаляем директорию $MOUNT_DIR"
    sudo rm -rf "$MOUNT_DIR"
fi

# 4. Опционально удалить nfs-common
read -p "[?] Удалить пакет nfs-common? (y/N): " DELETE_NFS
if [[ "$DELETE_NFS" =~ ^[Yy]$ ]]; then
    echo "[+] Удаляем nfs-common"
    sudo apt purge -y nfs-common
    sudo apt autoremove -y
fi

echo "[✓] Всё откатили, брат."
