#!/bin/bash
# Initialisation des variables 

# Demandes de variables

read -p "Rentrer le nom : Proxy " proxy_hostname

valid_password=false

while [ "$valid_password" = false ]; do
    read -s -p "Mot de passe DB : " db_password
    echo
    read -s -p "Confirmer Mot de passe DB : " db_password_confirm
    echo

    if [ "$db_password" = "$db_password_confirm" ]; then
        echo "Mot de passe confirmé."
        valid_password=true
    else
        echo "Les mots de passe ne correspondent pas. Réessaye."
    fi
done

# Mise à jour et installation PostgreSQL
dnf update -y
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf makecache -y
dnf install -y postgresql17 postgresql17-server postgresql17-contrib epel-release nano
postgresql-17-setup initdb
systemctl enable --now postgresql-17

# Remplacement avec la ligne exclude zabbix
rm /etc/yum.repos.d/epel.repo
cp epel.repo /etc/yum.repos.d

rpm -Uvh https://repo.zabbix.com/zabbix/7.2/release/alma/9/noarch/zabbix-release-latest-7.2.el9.noarch.rpm
dnf clean all
dnf install -y zabbix-proxy-pgsql zabbix-sql-scripts zabbix-selinux-policy telnet lynx net-snmp net-snmp-utils wireshark-cli qrencode

sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD '$db_password';"
sudo -u postgres createdb -O zabbix zabbix_proxy
sudo -u zabbix psql zabbix_proxy < /usr/share/zabbix/sql-scripts/postgresql/proxy.sql

conf_file="/etc/zabbix/zabbix_proxy.conf"
server="zabbix.irvi.fr"

sed -i "s/^Server=127.0.0.1/Server=$server/" "$conf_file"
sed -i "s/^Hostname=Zabbix proxy*/Hostname=Proxy $proxy_hostname/" "$conf_file"
sed -i "s/^# DBPassword=/DBPassword=$db_password/" "$conf_file"

systemctl enable --now zabbix-proxy

psk_file="/etc/zabbix/zabbix_proxy.psk"

### Chiffrement
# QR code
openssl rand -hex 128 > $psk_file
qrencode -t ANSIUTF8 < $psk_file

# TLS
sed -i "s/^# TLSConnect=unencrypted/TLSConnect=psk/" "$conf_file"
sed -i "s|^# TLSPSKFile=|TLSPSKFile=$psk_file|" "$conf_file"

psk_identity="PSK-$(echo "$proxy_hostname" | tr ' ' '-')"
sed -i "s/^# TLSPSKIdentity=/TLSPSKIdentity=$psk_identity/" "$conf_file"

systemctl restart zabbix-proxy

# Telechargement de la MIB SOPHOS
curl -o SFOS-FIREWALL-MIB.txt https://mibbrowser.online/mibs/SFOS-FIREWALL-MIB.mib
mkdir -p /usr/local/share/snmp/mibs
touch /etc/snmp/snmp.conf
echo "mibdirs +/usr/local/share/snmp/mibs" >> /etc/snmp/snmp.conf
mv SFOS-FIREWALL-MIB.txt /usr/local/share/snmp/mibs
systemctl restart zabbix-proxy
