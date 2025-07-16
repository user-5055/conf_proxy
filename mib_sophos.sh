# Telechargement de la MIB SOPHOS
curl -o SFOS-FIREWALL-MIB.txt https://mibbrowser.online/mibs/SFOS-FIREWALL-MIB.mib
mkdir -p /usr/local/share/snmp/mibs
touch /etc/snmp/snmp.conf
echo "mibdirs +/usr/local/share/snmp/mibs" >> /etc/snmp/snmp.conf
mv SFOS-FIREWALL-MIB.txt /usr/local/share/snmp/mibs
