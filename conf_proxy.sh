#!/bin/bash
# Initialisation des variables 

# Demandes de variables

read -p "Rentrer le nom : Proxy " proxy_hostname
read -p "Zabbix Proxy Version : " proxy_version

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

echo "Mise à jour..."
dnf update -y > /dev/null 2>&1
echo "Telechargement et installation de PostgreSQL 17"
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm > /dev/null 2>&1
dnf makecache -y > /dev/null 2>&1
dnf install -y postgresql17 postgresql17-server postgresql17-contrib epel-release nano > /dev/null 2>&1
postgresql-17-setup initdb > /dev/null 2>&1
systemctl enable --now postgresql-17 > /dev/null 2>&1

# Remplacement avec la ligne exclude zabbix
rm /etc/yum.repos.d/epel.repo
cp epel.repo /etc/yum.repos.d

echo "Installation de Zabbix Proxy $proxy_version et autres utilitaires..."
rpm -Uvh https://repo.zabbix.com/zabbix/$proxy_version/release/alma/9/noarch/zabbix-release-latest-$proxy_version.el9.noarch.rpm > /dev/null 2>&1
dnf clean all > /dev/null 2>&1
dnf install -y zabbix-proxy-pgsql zabbix-sql-scripts zabbix-selinux-policy telnet lynx net-snmp net-snmp-utils wireshark-cli qrencode nmap > /dev/null 2>&1

echo "Création et configuration de la BDD"
sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD '$db_password';" > /dev/null 2>&1
sudo -u postgres createdb -O zabbix zabbix_proxy > /dev/null 2>&1
sudo -u zabbix psql zabbix_proxy < /usr/share/zabbix/sql-scripts/postgresql/proxy.sql > /dev/null 2>&1

conf_file="/etc/zabbix/zabbix_proxy.conf"
server="zabbix.irvi.fr"

sed -i "s/^Server=127.0.0.1/Server=$server/" "$conf_file"
sed -i "s/^Hostname=Zabbix proxy*/Hostname=Proxy $proxy_hostname/" "$conf_file"
sed -i "s/^# DBPassword=/DBPassword=$db_password/" "$conf_file"

echo "Activation et démarrage du proxy"
systemctl enable --now zabbix-proxy > /dev/null 2>&1

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

systemctl restart zabbix-proxy > /dev/null 2>&1

# Telechargement de la MIB SOPHOS
curl -o SFOS-FIREWALL-MIB.txt https://mibbrowser.online/mibs/SFOS-FIREWALL-MIB.mib > /dev/null 2>&1
cp SFOS-FIREWALL-MIB.txt /usr/share/snmp/mibs > /dev/null 2>&1
systemctl restart zabbix-proxy > /dev/null 2>&1
