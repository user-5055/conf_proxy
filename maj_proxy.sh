exec > /dev/null 2>&1

read -p "Version du proxy : " proxy_version
echo "Arrêt du proxy"
systemctl stop zabbix-proxy
echo "Ajout du dépot de Zabbix Proxy $proxy_version"
rpm -Uvh https://repo.zabbix.com/zabbix/$proxy_version/release/alma/9/noarch/zabbix-release-latest-$proxy_version.el9.noarch.rpm
echo "Nettoyage du cache des dépots..."
dnf clean all
echo "Mise à jour du proxy..."
dnf update zabbix-* -y
systemctl start zabbix-proxy
echo "Proxy redémarré"
