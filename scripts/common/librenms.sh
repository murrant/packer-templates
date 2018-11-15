#!/bin/bash -eux

if [ -z "$LIBRENMS_VERSION"]; then
  LIBRENMS_VERSION="master"
fi

sudo bash -c 'cat <<EOF > /etc/sudoers.d/librenms
Defaults:librenms !requiretty
librenms ALL=(ALL) NOPASSWD: ALL
EOF'

sudo chmod 440 /etc/sudoers.d/librenms

sudo mkdir /var/run/rrdcached
sudo chown librenms:librenms /var/run/rrdcached
sudo chmod 755 /var/run/rrdcached

sudo bash -c 'cat << EOF > /etc/systemd/system/rrdcached.service
[Unit]
Description=Data caching daemon for rrdtool
After=network.service

[Service]
Type=forking
PIDFile=/run/rrdcached.pid
ExecStart=/usr/bin/rrdcached -w 1800 -z 1800 -f 3600 -s librenms -U librenms -G librenms -B -R -j /var/tmp -l unix:/var/run/rrdcached/rrdcached.sock -t 4 -F -b /opt/librenms/rrd/

[Install]
WantedBy=default.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable --now rrdcached.service



mysql_pass="D42nf23rewD";

echo "CREATE DATABASE librenms;
            GRANT ALL PRIVILEGES ON librenms.*
            TO 'librenms'@'localhost'
            IDENTIFIED BY '$mysql_pass';
            FLUSH PRIVILEGES;" | mysql -u root

sudo rm -rf /opt/librenms
sudo sh -c "cd /opt/; git clone --branch $LIBRENMS_VERSION https://github.com/librenms/librenms.git"
cd /opt/librenms

sudo chown -R librenms:librenms /opt/librenms
sudo setfacl -d -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/
sudo setfacl -R -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/

/usr/bin/php ./scripts/composer_wrapper.php install --no-dev

cp /opt/librenms/config.php.default /opt/librenms/config.php

sed -i 's/USERNAME/librenms/g' /opt/librenms/config.php
sed -i "s/PASSWORD/${mysql_pass}/g" /opt/librenms/config.php
bash -c "echo '\$config[\"fping\"] = \"/usr/sbin/fping\";' >> /opt/librenms/config.php"
bash -c "echo '\$config[\"rrdcached\"] = \"unix:/var/run/rrdcached/rrdcached.sock\";' >> /opt/librenms/config.php"
bash -c "echo '\$config[\"update_channel\"] = \"release\";' >> /opt/librenms/config.php"

#sudo rm /etc/snmp/snmpd.conf
sudo bash -c 'cat <<EOF > /etc/snmp/snmpd.conf
rocommunity public 127.0.0.1
extend distro /usr/bin/distro
extend hardware "/bin/cat /sys/devices/virtual/dmi/id/product_name"
extend manufacturer "/bin/cat /sys/devices/virtual/dmi/id/sys_vendor"
EOF'
sudo curl -o /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro
sudo chmod +x /usr/bin/distro
sudo systemctl enable snmpd
sudo systemctl restart snmpd

sudo cp /opt/librenms/misc/librenms.logrotate /etc/logrotate.d/librenms
sudo cp /opt/librenms/librenms.nonroot.cron /etc/cron.d/librenms

/usr/bin/php /opt/librenms/build-base.php
/usr/bin/php /opt/librenms/addhost.php localhost public v2c
/usr/bin/php /opt/librenms/adduser.php librenms D32fwefwef 10

git clone https://github.com/librenms-plugins/Weathermap.git /opt/librenms/html/plugins/Weathermap/
echo "INSERT INTO plugins SET plugin_name = 'Weathermap', plugin_active = 1;" | mysql -u root librenms

sudo cp /opt/librenms/librenms.nonroot.cron /etc/cron.d/librenms

sudo bash -c "echo '*/5 * * * * librenms /opt/librenms/html/plugins/Weathermap/map-poller.php >> /dev/null 2>&1' >> /etc/cron.d/librenms"

# default to 4 poller threads
sudo sed -i "s/16/4/g" /etc/cron.d/librenms

sudo chown -R librenms:librenms /opt/librenms
