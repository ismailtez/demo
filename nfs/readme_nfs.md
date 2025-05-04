Сервер NFS:

Если нет раздела на диске и неразмеченное пространство

sudo parted <Файл диска>
(parted) mkpart primary ext4 <start> <end>

start - что написано в колоннке START после выполнения команды "sudo parted <Файл диска> print" на месте неразмеченного пространства
end - тоже самое только END колонка

Чтобы отформатировать раздел в ext4:
sudo mkfs.ext4 <Раздел>

sudo mkdir /srv/nfshare - создаем папку, которую шарим
sudo chmod 777 /srv/nfshare - даем полные права

sudo mount <Раздел> /srv/nfsshare

sudo blkid <Раздел> - Узнаем UUID раздела
sudo nano /etc/fstab
в конец добавляем: 
	UUID=<UUID> <папка, которую расшариваем> ext4 defaults 0 0


sudo apt update
sudo apt install nfs-kernel-server

sudo nano /etc/exports
/srv/nfsshare <ip сетки, которой двем доступ>/<маска>(rw,nohide,all_squash,no_subtree_check)

sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server
sudo exportfs -ra

Клиент NFS:

sudo apt update
sudo apt install nfs-common
sudo mkdir <название папки> 
sudo mount <ip адрес сервера nfs>:<папка на сервере, которая настроена для nfs> <папка, которую создали пред командой>
sudo nano /etc/fstab
добавляем в конец:
<ip адрес сервера nfs>:<папка на сервере, которая настроена для nfs> <папка, которую создали пред командой> nfs rw,sync,hard,intr 0 0        
