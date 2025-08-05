systemctl stop zabbix-proxy
rpm -Uvh https://repo.zabbix.com/zabbix/7.4/release/alma/9/noarch/zabbix-release-latest-7.4.el9.noarch.rpm
dnf clean all
dnf update zabbix-* -y
systemctl start zabbix-proxy
