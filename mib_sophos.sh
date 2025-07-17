# Telechargement de la MIB SOPHOS
curl -o SFOS-FIREWALL-MIB.txt https://mibbrowser.online/mibs/SFOS-FIREWALL-MIB.mib
cp SFOS-FIREWALL-MIB.txt /usr/share/snmp/mibs
systemctl restart zabbix-proxy
