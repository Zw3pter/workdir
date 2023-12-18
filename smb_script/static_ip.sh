echo Saetter statisk ip på eth1

sudo bash -c 'cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth1
DEVICE=eth1
NAME=eth1
ONBOOT=yes
BOOTPROTO=static
IPADDR=10.25.175.61
NETMASK=255.255.255.192
GATEWAY=10.25.175.62
DNS1=10.25.175.62
DNS2=0.0.0.0
EOF'
echo statisk ip sat og filen ifcfg-eth1 ændret til
echo DEVICE=eth1
echo NAME=eth1
echo ONBOOT=yes
echo BOOTPROTO=static
echo IPADDR=10.25.175.61
echo NETMASK=255.255.255.192
echo GATEWAY=10.25.175.62
echo DNS1=10.25.175.62
echo DNS2=0.0.0.0
sudo systemctl restart network