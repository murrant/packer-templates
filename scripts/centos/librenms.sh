#!/bin/bash -eux

if [ -z "$LIBRENMS_VERSION"]; then
  LIBRENMS_VERSION="master"
fi

sudo yum install -y epel-release
sudo yum update -y
sudo rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
sudo yum install -y composer cronie fping git ImageMagick jwhois mariadb mariadb-server mtr MySQL-python net-snmp net-snmp-utils nginx nmap php72w php72w-cli php72w-common php72w-curl php72w-fpm php72w-gd php72w-mbstring php72w-mysqlnd php72w-process php72w-snmp php72w-xml php72w-zip python-memcached rrdtool libargon2

sudo usermod -a -G librenms nginx

# Change php to UTC TZ
sudo sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php.ini
sudo sed -i "s/^user =.*/user = nginx/" /etc/php-fpm.d/www.conf
sudo sed -i "s/^group =.*/group = apache/" /etc/php-fpm.d/www.conf
sudo sed -i "s/^listen =.*/listen = \/var\/run\/php-fpm\/php7.2-fpm.sock/" /etc/php-fpm.d/www.conf
sudo sed -i "s/^;listen.owner =.*/listen.owner = nginx/" /etc/php-fpm.d/www.conf
sudo sed -i "s/^;listen.group =.*/listen.group = nginx/" /etc/php-fpm.d/www.conf
sudo sed -i "s/^;listen.mode =.*/listen.mode = 0660/" /etc/php-fpm.d/www.conf

sudo systemctl enable php-fpm
sudo systemctl restart php-fpm

sudo cp /tmp/librenms.conf /etc/nginx/conf.d/librenms.conf
sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf

sudo rm -f /etc/httpd/conf.d/welcome.conf
sudo chgrp apache /var/lib/php/session/

sudo systemctl enable nginx
sudo systemctl restart nginx

sudo firewall-cmd --zone public --add-service http
sudo firewall-cmd --permanent --zone public --add-service http
sudo firewall-cmd --zone public --add-service https
sudo firewall-cmd --permanent --zone public --add-service https


sudo bash -c 'cat << EOF > /etc/my.cnf.d/server.cnf
#
# These groups are read by MariaDB server.
# Use it for options that only the server (but not clients) should see
#
# See the examples of server my.cnf files in /usr/share/mysql/
#

# this is read by the standalone daemon and embedded servers
[server]
innodb_file_per_table=1
lower_case_table_names=0
EOF'

sudo systemctl restart mariadb
sudo systemctl enable mariadb

