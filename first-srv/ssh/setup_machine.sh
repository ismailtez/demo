#!/bin/bash

# Установка имени машины
set_hostname() {
    echo "Введите имя машины (например, First-SRV):"
    read -r hostname
    sudo hostnamectl set-hostname "$hostname"
    echo "Имя машины изменено на: $hostname"
}

# Создание пользователя sshuser
create_sshuser() {
    echo "Создание пользователя sshuser..."
    sudo useradd sshuser -u 1010 -m -s /bin/bash || true
    echo "Установка пароля для sshuser..."
    sudo passwd sshuser
    echo "Добавление sshuser в sudoers с правами без пароля..."
    echo "%sshuser ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers > /dev/null
    echo "Пользователь sshuser создан и добавлен в sudoers."
}

# Установка и настройка SSH
setup_ssh() {
    echo "Установка OpenSSH-сервера..."
    sudo apt update -y
    sudo apt install openssh-server -y

    echo "Настройка конфигурации SSH (/etc/ssh/sshd_config)..."
    sudo tee /etc/ssh/sshd_config > /dev/null <<EOF
Port 2024
MaxAuthTries 2
AllowUsers sshuser
PermitRootLogin no
Banner /root/banner

# Остальные настройки по умолчанию
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem       sftp    /usr/lib/openssh/sftp-server
EOF

    echo "Создание баннера SSH (/root/banner)..."
    echo "Authorized access only" | sudo tee /root/banner > /dev/null

    echo "Перезапуск службы SSH..."
    sudo systemctl restart ssh
    echo "SSH настроен и перезапущен."
}

# Проверка статуса SSH
check_ssh_status() {
    echo "Проверка статуса службы SSH..."
    sudo systemctl status ssh
}

# Основной процесс
main() {
    set_hostname
    create_sshuser
    setup_ssh
    check_ssh_status
    echo "Настройка завершена!"
}

main