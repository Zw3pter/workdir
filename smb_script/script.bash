#!/bin/bash

# Installer Samba og Kerberos-pakker
sudo dnf install samba samba-client samba-common krb5-workstation krb5-libs -y

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

# Konfigurer Samba til AD integration i smb.conf
sudo bash -c 'cat << EOF > /etc/samba/smb.conf
[global]
   workgroup = DCTRL-LTJ
   security = ads
   realm = DCTRL.LTJ.LOCAL
   winbind use default domain = true
   winbind enum users = yes
   winbind enum groups = yes
   idmap config * : backend = tdb
   idmap config * : range = 1000-999999
   idmap config DCTRL-LTJ : backend = rid
   idmap config DCTRL-LTJ : range = 10000-999999
   template shell = /bin/bash

[faelles]
   path = /samba/faelles
   valid users = @faelles
   writable = yes
   browsable = yes

[lager]
   path = /samba/lager
   valid users = @lager
   writable = yes
   browsable = yes

[regnskab]
   path = /samba/regnskab
   valid users = @regnskab
   writable = yes
   browsable = yes
EOF'

# Genstart Samba services
sudo systemctl restart smb nmb

# Konfigurer Kerberos
sudo bash -c 'cat << EOF > /etc/krb5.conf
[logging]
 default = FILE:/var/log/krb5libs.log

[libdefaults]
 default_realm = DCTRL.LTJ.LOCAL
 dns_lookup_realm = false
 dns_lookup_kdc = true
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

[realms]
 DCTRL.LTJ.LOCAL = {
  kdc = 10.25.175.62
  admin_server = 10.25.175.62
 }

[domain_realm]
 .dctrl.ltj.local = DCTRL.LTJ.LOCAL
 dctrl.ltj.local = DCTRL.LTJ.LOCAL
EOF'

# Tilføj Samba og Kerberos til firewall og genindlæs
sudo firewall-cmd --add-service=samba --permanent
sudo firewall-cmd --add-service=kerberos --permanent
sudo firewall-cmd --reload

# Anvend SELinux kontekst
sudo chcon -t samba_share_t /samba/faelles /samba/lager /samba/regnskab
