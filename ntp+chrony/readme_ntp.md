/system/ntp/client/set enabled=yes
/system/ntp/client/servers/add address=pool.ntp.org
/system/ntp/client/servers/add address=0.europe.pool.ntp.org


/system/clock/set time-zone-name=Europe/London



КЛИЕНТ
sudo apt update && sudo apt install chrony -y
sudo nano /etc/chrony/chrony.conf


В ФАЙЛЕ ДОПИСАТЬ
server 192.168.1.1 iburst