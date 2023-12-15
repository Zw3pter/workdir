#!/bin/bash

# Installer Samba-pakker
sudo dnf install samba samba-client samba-common -y

# Start og aktiver Samba services
sudo systemctl start smb nmb
sudo systemctl enable smb nmb

# Opret gruppe
sudo groupadd faelles
sudo groupadd lager
sudo groupadd regnskab

# Opret mapper og tildele rettigheder
# faelles mappe oprettelse
sudo mkdir -p /samba/faelles
sudo chown root:faelles /samba/faelles
sudo chmod 0770 /samba/faelles
# lager mappe oprettelse
sudo mkdir -p /samba/lager
sudo chown root:lager /samba/lager
sudo chmod 0770 /samba/lager
# regnskab mappe oprettelse
sudo mkdir -p /samba/regnskab
sudo chown root:regnskab /samba/regnskab
sudo chmod 0770 /samba/regnskab

# Konfigurer Samba skriver data til filen smb.conf
sudo bash -c 'cat << EOF > /etc/samba/smb.conf
[Global]
workgroup = WORKGROUP
server string = This is a samba share on centos
netbios name = FAELLESSHARE
wins support = yes
security = user

[faelles]
path = /samba/faelles
valid users = @faelles
writeable = yes
browsable = yes

[lager]
path = /samba/lager
valid users = @lager
writeable = yes
browsable = yes

[regnskab]
path = /samba/regnskab
valid users = @regnskab
writeable = yes
browsable = yes
EOF'

# Genstart Samba services
sudo systemctl restart smb nmb

# Opret bruger
sudo useradd -M -d /samba/faelles -s /usr/sbin/nologin -G faelles userfaelles
sudo useradd -M -d /samba/lager -s /usr/sbin/nologin -G lager userlager
sudo useradd -M -d /samba/regnskab -s /usr/sbin/nologin -G regnskab userregnskab

echo Indstil brugerens Samba password interaktivt
echo Du skal indtast password til 3 brugere
echo forste bruger userfaelles 
sudo smbpasswd -a userfaelles
sudo smbpasswd -e userfaelles

echo Indtast password for userlager
sudo smbpasswd -a userlager
sudo smbpasswd -e userlager

echo Indtast password for userregnskab
sudo smbpasswd -a userregnskab
sudo smbpasswd -e userregnskab

# Tilføj Samba til firewall og genindlæs
sudo firewall-cmd --add-service=samba --permanent
sudo firewall-cmd --reload

# Anvend SELinux kontekst
sudo chcon -t samba_share_t /samba/faelles /samba/lager /samba/regnskab
