read -p "Version du proxy : " proxy_version
echo "Arrêt du proxy"
systemctl stop zabbix-proxy > /dev/null 2>&1
echo "Ajout du dépot de Zabbix Proxy $proxy_version"
rpm -Uvh https://repo.zabbix.com/zabbix/$proxy_version/release/alma/9/noarch/zabbix-release-latest-$proxy_version.el9.noarch.rpm > /dev/null 2>&1
echo "Nettoyage du cache des dépots..."
dnf clean all > /dev/null 2>&1
echo "Mise à jour du proxy..."
dnf update zabbix-* -y > /dev/null 2>&1
echo "Démarrage du proxy"
systemctl start zabbix-proxy > /dev/null 2>&1
