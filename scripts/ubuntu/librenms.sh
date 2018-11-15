#!/bin/bash -eux

if [ -z "$LIBRENMS_VERSION"]; then
  LIBRENMS_VERSION="master"
fi

sudo add-apt-repository universe
sudo apt update -y
sudo apt install -y curl composer fping git graphviz imagemagick mariadb-client mariadb-server mtr-tiny nginx-full nmap php7.2-cli php7.2-curl php7.2-fpm php7.2-gd php7.2-json php7.2-mbstring php7.2-mysql php7.2-snmp php7.2-xml php7.2-zip python-memcache python-mysqldb rrdtool snmp snmpd whois acl python-mysqldb rrdcached

sudo usermod -a -G librenms www-data

# Change php to UTC TZ
sudo sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.2/fpm/php.ini
sudo sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.2/cli/php.ini

sudo systemctl enable php7.2-fpm
sudo systemctl restart php7.2-fpm

sudo cp /tmp/librenms.conf /etc/nginx/conf.d/librenms.conf

sudo rm -f /etc/nginx/sites-enabled/default

sudo systemctl enable nginx
sudo systemctl restart nginx

sudo bash -c 'cat << EOF > /etc/mysql/mariadb.conf.d/50-server.cnf
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

sudo systemctl enable mysql
sudo systemctl restart mysql

