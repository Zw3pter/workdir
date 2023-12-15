#!/bin/bash

# Installer Samba-pakker
sudo dnf install samba samba-client samba-common -y

# Start og aktiver Samba services
sudo systemctl start smb nmb
sudo systemctl enable smb nmb

# Opret gruppe
sudo groupadd masters

# Opret mapper og tildele rettigheder
sudo mkdir -p /samba/faelles
sudo chown root:masters /samba/faelles
sudo chmod 0770 /samba/faelles

# Konfigurer Samba
sudo bash -c 'cat << EOF > /etc/samba/smb.conf
[Global]
workgroup = WORKGROUP
server string = This is a samba share on centos
netbios name = FAELLESSHARE
wins support = yes
security = user

[faelles]
path = /samba/faelles
valid users = @masters
writeable = yes
browsable = yes
EOF'

# Genstart Samba services
sudo systemctl restart smb nmb

# Opret bruger
sudo useradd -M -d /samba/master -s /usr/sbin/nologin -G masters master

# Sæt og aktiver brugerens Samba password
echo -e "V3n1ngT0P\nV3nd1ngT0P" | sudo smbpasswd -a master
sudo smbpasswd -e master

# Tilføj Samba til firewall og genindlæs
sudo firewall-cmd --add-service=samba --permanent
sudo firewall-cmd --reload

# Anvend SELinux kontekst
sudo chcon -t samba_share_t /samba/faelles
