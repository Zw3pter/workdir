#!/bin/bash

# Installer Samba-pakker
sudo dnf install samba samba-client samba-common -y

# Start og aktiver Samba services
sudo systemctl start smb nmb
sudo systemctl enable smb nmb

# Opret gruppe
sudo groupadd masters

# Opret mapper og tildele rettigheder
sudo mkdir -p /samba/off_mappe
sudo mkdir -p /samba/salg_privat
sudo chown -R nobody:nobody /samba/off_mappe
sudo chmod -R 0755 /samba/off_mappe
sudo chown root:masters /samba/salg_privat
sudo chmod 0770 /samba/salg_privat

# Konfigurer Samba
sudo bash -c 'cat << EOF > /etc/samba/smb.conf
[Global]
workgroup = WORKGROUP
server string = This is a samba share on centos
netbios name = SAMBASHARE
wins support = yes
security = user

[off_mappe]
path = /samba/off_mappe
browsable = yes
writable = yes
guest ok = yes
read only = no

[salg_privat]
path = /samba/salg_privat
valid users = @masters
writeable = yes
browsable = yes
EOF'

# Genstart Samba services
sudo systemctl restart smb nmb

# Opret bruger
sudo useradd -M -d /samba/master -s /usr/sbin/nologin -G masters master

# Sæt og aktiver brugerens Samba password
echo -e "1234\n1234" | sudo smbpasswd -a master
sudo smbpasswd -e master

# Tilføj Samba til firewall og genindlæs
sudo firewall-cmd --add-service=samba --permanent
sudo firewall-cmd --reload

# Anvend SELinux kontekst
sudo chcon -t samba_share_t /samba/off_mappe /samba/salg_privat
